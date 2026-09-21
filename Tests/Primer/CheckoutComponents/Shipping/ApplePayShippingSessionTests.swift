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
            applePayOptions: applePayOptions(requireShippingMethod: true)
        )

        XCTAssertEqual(mode, .legacy)
    }

    func test_resolveMode_callbackModeModule_usesCallbacks() {
        let module = checkoutModule(ShippingMethodOptions(callbackMode: true))

        let mode = ApplePayShippingSession.resolveMode(
            checkoutModules: [module],
            applePayOptions: applePayOptions(requireShippingMethod: true)
        )

        XCTAssertEqual(mode, .callbacks)
    }

    func test_resolveMode_noShippingModule_usesCallbacksWhenShippingIsCollected() {
        let mode = ApplePayShippingSession.resolveMode(
            checkoutModules: nil,
            applePayOptions: applePayOptions(requireShippingMethod: true)
        )

        XCTAssertEqual(mode, .callbacks)
    }

    func test_resolveMode_shippingNotCollected_staysLegacy() {
        let mode = ApplePayShippingSession.resolveMode(
            checkoutModules: nil,
            applePayOptions: applePayOptions(requireShippingMethod: false)
        )

        XCTAssertEqual(mode, .legacy)
    }

    func test_resolveMode_postalAddressOnly_usesCallbacks() {
        let mode = ApplePayShippingSession.resolveMode(
            checkoutModules: nil,
            applePayOptions: applePayOptions(requireShippingMethod: false, contactFields: [.postalAddress])
        )

        XCTAssertEqual(mode, .callbacks)
    }

    // MARK: - Address change

    func test_addressChange_storesOptionsAndCommitsTheDefault() async throws {
        let committed = Box([PrimerShippingOption]())
        let sut = makeSession(
            callbacks: PrimerShippingCallbacks(
                onShippingAddressChange: { _ in [Self.standard, Self.express] },
                onShippingOptionChange: { committed.value.append($0) }
            ),
            shipping: shipping(methodId: "standard", amount: 500)
        )

        try await sut.handleShippingAddressChange(address)

        XCTAssertEqual(sut.options.map(\.id), ["standard", "express"])
        XCTAssertEqual(committed.value.map(\.id), ["standard"])
        XCTAssertEqual(sut.verifiedCommit?.id, "standard")
    }

    func test_addressChange_movesTheCommittedOptionToTheFront() async throws {
        let sut = makeSession(
            callbacks: PrimerShippingCallbacks(
                onShippingAddressChange: { _ in [Self.standard, Self.express] },
                onShippingOptionChange: { _ in }
            ),
            shipping: shipping(methodId: "express", amount: 1500)
        )

        try await sut.handleShippingAddressChange(address)

        XCTAssertEqual(sut.options.map(\.id), ["express", "standard"])
        XCTAssertEqual(sut.verifiedCommit?.id, "express")
    }

    func test_addressChange_emptyList_marksTheAddressUnserviceable() async throws {
        let sut = makeSession(
            callbacks: PrimerShippingCallbacks(onShippingAddressChange: { _ in [] })
        )

        try await sut.handleShippingAddressChange(address)

        XCTAssertTrue(sut.options.isEmpty)
        XCTAssertTrue(sut.isAddressUnserviceable)
        XCTAssertNil(sut.verifiedCommit)
    }

    func test_addressChange_withoutHandler_showsNoOptionsAndDoesNotThrow() async throws {
        let sut = makeSession(callbacks: PrimerShippingCallbacks())

        try await sut.handleShippingAddressChange(address)

        XCTAssertTrue(sut.options.isEmpty)
    }

    func test_addressChange_inLegacyMode_asksTheMerchantForNothing() async throws {
        let asked = Box(false)
        let sut = makeSession(
            mode: .legacy,
            callbacks: PrimerShippingCallbacks(onShippingAddressChange: { _ in
                asked.value = true
                return [Self.standard]
            })
        )

        try await sut.handleShippingAddressChange(address)

        XCTAssertFalse(asked.value)
        XCTAssertTrue(sut.options.isEmpty)
    }

    func test_addressChange_staleCommitIsDropped() async throws {
        let committed = Box(shipping(methodId: "standard", amount: 500)())
        let sut = makeSession(
            callbacks: PrimerShippingCallbacks(
                onShippingAddressChange: { _ in [Self.standard] },
                onShippingOptionChange: { _ in }
            ),
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
            callbacks: PrimerShippingCallbacks(
                onShippingAddressChange: { _ in [Self.standard, Self.express] },
                onShippingOptionChange: { committed.value.append($0.id) }
            ),
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
            callbacks: PrimerShippingCallbacks(
                onShippingAddressChange: { _ in [Self.standard, Self.express] },
                onShippingOptionChange: { _ in }
            ),
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
            callbacks: PrimerShippingCallbacks(
                onShippingAddressChange: { _ in [Self.standard] },
                onShippingOptionChange: { _ in }
            ),
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
            callbacks: PrimerShippingCallbacks(
                onShippingAddressChange: { _ in [Self.standard] },
                onShippingOptionChange: { _ in commits.value += 1 }
            ),
            shipping: shipping(methodId: "standard", amount: 500)
        )
        try await sut.handleShippingAddressChange(address)

        try await sut.handleShippingOptionChange(optionId: "unknown")

        XCTAssertEqual(commits.value, 1, "Only the eager default commit ran")
    }

    // MARK: - Authorization gate

    func test_authorizeCommit_verifiedOption_passesWithoutAskingAgain() async throws {
        let commits = Box(0)
        let sut = makeSession(
            callbacks: PrimerShippingCallbacks(
                onShippingAddressChange: { _ in [Self.standard] },
                onShippingOptionChange: { _ in commits.value += 1 }
            ),
            shipping: shipping(methodId: "standard", amount: 500)
        )
        try await sut.handleShippingAddressChange(address)

        try await sut.authorizeCommit(selectedOptionId: "standard")

        XCTAssertEqual(commits.value, 1)
    }

    func test_authorizeCommit_optionApplePayReportsButTheSessionNeverVerified_commitsHere() async throws {
        let commits = Box(0)
        let sut = makeSession(
            callbacks: PrimerShippingCallbacks(
                onShippingAddressChange: { _ in [Self.standard] },
                onShippingOptionChange: { _ in commits.value += 1 }
            ),
            shipping: shipping(methodId: "standard", amount: 500)
        )
        try await sut.handleShippingAddressChange(address)
        commits.value = 0

        try await sut.authorizeCommit(selectedOptionId: "express")

        XCTAssertEqual(commits.value, 1)
        XCTAssertEqual(sut.verifiedCommit?.id, "standard")
    }

    func test_authorizeCommit_noOptionsAtAll_blocksAuthorization() async {
        let sut = makeSession(callbacks: PrimerShippingCallbacks(onShippingAddressChange: { _ in [] }))

        do {
            try await sut.authorizeCommit(selectedOptionId: nil)
            XCTFail("Expected authorization to be blocked")
        } catch {
            XCTAssertTrue("\(error)".contains("no shipping option was committed"))
        }
    }

    func test_authorizeCommit_legacyMode_isNotGated() async throws {
        let sut = makeSession(mode: .legacy, callbacks: nil)

        try await sut.authorizeCommit(selectedOptionId: nil)
    }

    func test_authorizeCommit_shippingMethodNotRequired_isNotGated() async throws {
        let sut = makeSession(requireShippingMethod: false, callbacks: nil)

        try await sut.authorizeCommit(selectedOptionId: nil)
    }

    // MARK: - Timeout

    func test_addressChange_handlerThatNeverReturns_failsTheAttempt() async {
        let sut = makeSession(
            callbacks: PrimerShippingCallbacks(onShippingAddressChange: { _ in
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return []
            }),
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
            callbacks: PrimerShippingCallbacks(
                onShippingAddressChange: { _ in [Self.standard] },
                onShippingOptionChange: { _ in try await Task.sleep(nanoseconds: 5_000_000_000) }
            ),
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
        callbacks: PrimerShippingCallbacks?,
        shipping: @escaping () -> ClientSession.Order.ShippingMethod? = { nil },
        timeout: TimeInterval = ApplePayShippingSession.callbackTimeout
    ) -> ApplePayShippingSession {
        ApplePayShippingSession(
            mode: mode,
            requireShippingMethod: requireShippingMethod,
            callbacksProvider: { callbacks },
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
