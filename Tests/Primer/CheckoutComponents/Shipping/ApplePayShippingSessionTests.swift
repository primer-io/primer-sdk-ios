//
//  ApplePayShippingSessionTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerNetworking
import XCTest

@available(iOS 15.0, *)
@MainActor
final class ApplePayShippingSessionTests: XCTestCase {

    private typealias ShippingMethodOptions = Response.Body.Configuration.CheckoutModule.ShippingMethodOptions

    private static let standard = PrimerShippingOption(id: "standard", name: "Standard", description: "3-5 days", amount: 500)
    private static let express = PrimerShippingOption(id: "express", name: "Express", description: "1-2 days", amount: 1500)
    private let address = PrimerAddress(
        firstName: nil, lastName: nil, addressLine1: nil, addressLine2: nil,
        postalCode: "SW1A 1AA", city: "London", state: nil, countryCode: "GB"
    )

    // MARK: - Mode resolution

    func test_resolveMode_legacyShippingModule_wins() {
        let module = checkoutModule(ShippingMethodOptions(
            shippingMethods: [ShippingMethodOptions.ShippingMethod(
                name: "Standard", description: "3-5 days", amount: 500, id: "standard"
            )],
            selectedShippingMethod: "standard"
        ))

        let mode = ApplePayShippingSession.resolveMode(
            checkoutModules: [module],
            applePayOptions: applePayOptions(requireShippingMethod: true),
            hasAddressChangeHandler: true
        )

        XCTAssertEqual(mode, .legacy)
    }

    func test_resolveMode_callbackModeModule_usesCallbacks() {
        let module = checkoutModule(ShippingMethodOptions(callbackMode: true))

        let mode = ApplePayShippingSession.resolveMode(
            checkoutModules: [module],
            applePayOptions: applePayOptions(requireShippingMethod: true),
            hasAddressChangeHandler: true
        )

        XCTAssertEqual(mode, .callbacks)
    }

    func test_resolveMode_noShippingModule_usesCallbacksWhenShippingIsCollected() {
        let mode = ApplePayShippingSession.resolveMode(
            checkoutModules: nil,
            applePayOptions: applePayOptions(requireShippingMethod: true),
            hasAddressChangeHandler: true
        )

        XCTAssertEqual(mode, .callbacks)
    }

    func test_resolveMode_shippingNotCollected_staysLegacy() {
        let mode = ApplePayShippingSession.resolveMode(
            checkoutModules: nil,
            applePayOptions: applePayOptions(requireShippingMethod: false),
            hasAddressChangeHandler: true
        )

        XCTAssertEqual(mode, .legacy)
    }

    func test_resolveMode_noAddressHandler_staysLegacy() {
        let mode = ApplePayShippingSession.resolveMode(
            checkoutModules: nil,
            applePayOptions: applePayOptions(requireShippingMethod: true),
            hasAddressChangeHandler: false
        )

        XCTAssertEqual(mode, .legacy, "A merchant who registers nothing keeps today's behaviour")
    }

    func test_resolveMode_postalAddressOnly_usesCallbacks() {
        let mode = ApplePayShippingSession.resolveMode(
            checkoutModules: nil,
            applePayOptions: applePayOptions(requireShippingMethod: false, contactFields: [.postalAddress]),
            hasAddressChangeHandler: true
        )

        XCTAssertEqual(mode, .callbacks)
    }

    // MARK: - Address change

    func test_addressChange_storesOptionsAndCommitsTheDefault() async throws {
        let committed = Box([PrimerShippingOption]())
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard, Self.express] },
            onOptionChange: { committed.value.append($0.selectedShippingOption) },
            shipping: shipping(methodId: "standard", amount: 500)
        )

        try await sut.handleShippingAddressChange(address)

        XCTAssertEqual(sut.options.map(\.id), ["standard", "express"])
        XCTAssertEqual(committed.value.map(\.id), ["standard"])
        XCTAssertEqual(sut.verifiedCommit?.id, "standard")
    }

    func test_addressChange_movesTheCommittedOptionToTheFront() async throws {
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard, Self.express] },
            onOptionChange: { _ in },
            shipping: shipping(methodId: "express", amount: 1500)
        )

        try await sut.handleShippingAddressChange(address)

        XCTAssertEqual(sut.options.map(\.id), ["express", "standard"])
        XCTAssertEqual(sut.verifiedCommit?.id, "express")
    }

    func test_addressChange_emptyList_marksTheAddressUnserviceable() async throws {
        let sut = makeSession(
            onAddressChange: { _ in [] }
        )

        try await sut.handleShippingAddressChange(address)

        XCTAssertTrue(sut.options.isEmpty)
        XCTAssertTrue(sut.isAddressUnserviceable)
        XCTAssertNil(sut.verifiedCommit)
    }

    func test_addressChange_withoutHandler_showsNoOptionsAndDoesNotThrow() async throws {
        let sut = makeSession()

        try await sut.handleShippingAddressChange(address)

        XCTAssertTrue(sut.options.isEmpty)
    }

    func test_addressChange_inLegacyMode_asksTheMerchantForNothing() async throws {
        let asked = Box(false)
        let sut = makeSession(
            mode: .legacy,
            onAddressChange: { _ in
                asked.value = true
                return [Self.standard]
            }
        )

        try await sut.handleShippingAddressChange(address)

        XCTAssertFalse(asked.value)
        XCTAssertTrue(sut.options.isEmpty)
    }

    func test_addressChange_staleCommitIsDropped() async throws {
        let committed = Box(shipping(methodId: "standard", amount: 500)())
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard] },
            onOptionChange: { _ in },
            shipping: { committed.value }
        )

        try await sut.handleShippingAddressChange(address)
        XCTAssertEqual(sut.verifiedCommit?.id, "standard")

        // The merchant's backend stops matching, so the next address must not inherit the old commit.
        committed.value = shipping(methodId: "other", amount: 999)()
        do {
            try await sut.handleShippingAddressChange(address)
            XCTFail("Expected the commit verification to fail")
        } catch {
            XCTAssertNil(sut.verifiedCommit)
        }
    }

    // MARK: - Option change

    func test_optionChange_commitsTheSelectedOptionAndMovesItToTheFront() async throws {
        let committed = Box([String]())
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard, Self.express] },
            onOptionChange: { committed.value.append($0.selectedShippingOption.id) },
            shipping: shipping(methodId: "express", amount: 1500)
        )
        try await sut.handleShippingAddressChange(address)
        committed.value.removeAll()

        try await sut.handleShippingOptionChange(optionId: "express")

        XCTAssertEqual(committed.value, ["express"])
        XCTAssertEqual(sut.options.map(\.id), ["express", "standard"])
    }

    func test_optionChange_mismatchedCommit_throwsAndLeavesNothingVerified() async throws {
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard, Self.express] },
            onOptionChange: { _ in },
            // The merchant PATCHes the wrong option.
            shipping: shipping(methodId: "standard", amount: 500)
        )
        try await sut.handleShippingAddressChange(address)

        do {
            try await sut.handleShippingOptionChange(optionId: "express")
            XCTFail("Expected a commit mismatch")
        } catch {
            XCTAssertNil(sut.verifiedCommit)
            XCTAssertTrue("\(error)".contains("express"))
        }
    }

    func test_optionChange_mismatchedAmount_throws() async throws {
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard] },
            onOptionChange: { _ in },
            // Right option, wrong price.
            shipping: shipping(methodId: "standard", amount: 100)
        )

        do {
            try await sut.handleShippingAddressChange(address)
            XCTFail("Expected a commit mismatch")
        } catch {
            XCTAssertNil(sut.verifiedCommit)
        }
    }

    func test_optionChange_unknownOption_isIgnored() async throws {
        let commits = Box(0)
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard] },
            onOptionChange: { _ in commits.value += 1 },
            shipping: shipping(methodId: "standard", amount: 500)
        )
        try await sut.handleShippingAddressChange(address)

        try await sut.handleShippingOptionChange(optionId: "unknown")

        XCTAssertEqual(commits.value, 1, "Only the eager default commit ran")
    }

    // MARK: - Authorization gate

    func test_requireVerifiedCommit_verifiedOption_passesWithoutAskingAgain() async throws {
        let commits = Box(0)
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard] },
            onOptionChange: { _ in commits.value += 1 },
            shipping: shipping(methodId: "standard", amount: 500)
        )
        try await sut.handleShippingAddressChange(address)

        try sut.requireVerifiedCommit(selectedOptionId: "standard")

        XCTAssertEqual(commits.value, 1)
    }

    func test_requireVerifiedCommit_failedInSheetCommit_blocksWithoutRetrying() async throws {
        let commits = Box(0)
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard, Self.express] },
            onOptionChange: { _ in commits.value += 1 },
            shipping: shipping(methodId: "standard", amount: 500)
        )
        try await sut.handleShippingAddressChange(address)
        // The merchant never records Express, so the in-sheet commit fails verification.
        try? await sut.handleShippingOptionChange(optionId: "express")
        commits.value = 0

        XCTAssertThrowsError(try sut.requireVerifiedCommit(selectedOptionId: "express")) { error in
            XCTAssertTrue("\(error)".contains("express"))
        }
        XCTAssertEqual(commits.value, 0, "A retry would charge a total the sheet never showed")
    }

    func test_requireVerifiedCommit_optionApplePayReportsIsNotInTheList_blocksAuthorization() async throws {
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard] },
            onOptionChange: { _ in },
            shipping: shipping(methodId: "standard", amount: 500)
        )
        try await sut.handleShippingAddressChange(address)

        XCTAssertThrowsError(try sut.requireVerifiedCommit(selectedOptionId: "express"))
    }

    func test_requireVerifiedCommit_noOptionReported_blocksAuthorization() async throws {
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard] },
            onOptionChange: { _ in },
            shipping: shipping(methodId: "standard", amount: 500)
        )
        try await sut.handleShippingAddressChange(address)

        XCTAssertThrowsError(try sut.requireVerifiedCommit(selectedOptionId: nil)) { error in
            XCTAssertTrue("\(error)".contains("none"))
        }
    }

    func test_requireVerifiedCommit_noCommitAtAll_blocksAuthorization() {
        let sut = makeSession(onAddressChange: { _ in [] })

        XCTAssertThrowsError(try sut.requireVerifiedCommit(selectedOptionId: "standard"))
    }

    func test_requireVerifiedCommit_legacyMode_isNotGated() throws {
        try makeSession(mode: .legacy).requireVerifiedCommit(selectedOptionId: nil)
    }

    func test_requireVerifiedCommit_shippingMethodNotRequired_isNotGated() throws {
        try makeSession(requireShippingMethod: false).requireVerifiedCommit(selectedOptionId: nil)
    }

    // MARK: - Timeout

    func test_addressChange_handlerThatNeverReturns_failsTheAttempt() async {
        let sut = makeSession(
            onAddressChange: { _ in
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return []
            },
            timeout: 0.2
        )

        do {
            try await sut.handleShippingAddressChange(address)
            XCTFail("Expected the callback to time out")
        } catch {
            XCTAssertTrue("\(error)".contains("onShippingAddressChange"))
        }
    }

    func test_optionChange_handlerThatNeverReturns_failsTheAttempt() async {
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard] },
            onOptionChange: { _ in try await Task.sleep(nanoseconds: 5_000_000_000) },
            timeout: 0.2
        )

        do {
            try await sut.handleShippingAddressChange(address)
            XCTFail("Expected the callback to time out")
        } catch {
            XCTAssertTrue("\(error)".contains("onShippingOptionChange"))
            XCTAssertNil(sut.verifiedCommit)
        }
    }

    func test_addressChange_handlerThatIgnoresCancellation_stillTimesOut() async {
        let release = Box<CheckedContinuation<Void, Never>?>(nil)
        let sut = makeSession(
            onAddressChange: { [release] _ in
                await withCheckedContinuation { release.value = $0 }
                return []
            },
            timeout: 0.2
        )

        do {
            try await sut.handleShippingAddressChange(address)
            XCTFail("Expected the callback to time out")
        } catch {
            XCTAssertTrue("\(error)".contains("onShippingAddressChange"))
        }
        release.value?.resume()
    }

    // MARK: - Helpers

    /// A reference cell so `@Sendable` merchant callbacks can record what they were asked, without
    /// capturing the test case itself.
    private final class Box<T>: @unchecked Sendable {
        var value: T
        init(_ value: T) { self.value = value }
    }

    private func makeSession(
        mode: ApplePayShippingSession.Mode = .callbacks,
        requireShippingMethod: Bool = true,
        onAddressChange: ShippingAddressChangeHandler? = nil,
        onOptionChange: ShippingOptionChangeHandler? = nil,
        shipping: @escaping () -> ClientSession.Order.ShippingMethod? = { nil },
        timeout: TimeInterval = ApplePayShippingSession.callbackTimeout
    ) -> ApplePayShippingSession {
        ApplePayShippingSession(
            mode: mode,
            requireShippingMethod: requireShippingMethod,
            addressChangeProvider: { onAddressChange },
            optionChangeProvider: { onOptionChange },
            refreshConfiguration: {},
            currentShipping: shipping,
            timeout: timeout
        )
    }

    private func shipping(methodId: String, amount: Int) -> () -> ClientSession.Order.ShippingMethod? {
        { ClientSession.Order.ShippingMethod(
            amount: amount,
            methodId: methodId,
            methodName: methodId.capitalized,
            methodDescription: nil
        ) }
    }

    private func checkoutModule(_ options: ShippingMethodOptions) -> Response.Body.Configuration.CheckoutModule {
        Response.Body.Configuration.CheckoutModule(type: "SHIPPING", requestUrlStr: nil, options: options)
    }

    private func applePayOptions(
        requireShippingMethod: Bool,
        contactFields: [PrimerApplePayOptions.RequiredContactField]? = nil
    ) -> PrimerApplePayOptions {
        PrimerApplePayOptions(
            merchantIdentifier: "merchant.test",
            merchantName: "Test",
            shippingOptions: PrimerApplePayOptions.ShippingOptions(
                shippingContactFields: contactFields,
                requireShippingMethod: requireShippingMethod
            )
        )
    }
}
