//
//  ApplePayShippingSessionLoggingTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) @testable import PrimerCore
@_spi(PrimerInternal) @testable import PrimerFoundation
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class ApplePayShippingSessionLoggingTests: XCTestCase {

    private static let standard = PrimerShippingOption(id: "standard", name: "Standard", description: "3-5 days", amount: 500)
    private static let express = PrimerShippingOption(id: "express", name: "Express", description: "1-2 days", amount: 1500)
    private let address = PrimerAddress(
        firstName: nil, lastName: nil, addressLine1: nil, addressLine2: nil,
        postalCode: "SW1A 1AA", city: "London", state: nil, countryCode: "GB"
    )
    private let logs = Box([ExpressCheckoutShippingLog]())

    // MARK: - Answered and committed

    func test_sheetOpen_logsTheAddressTheDefaultOptionAndItsCommit() async throws {
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard, Self.express] },
            onOptionChange: { _ in },
            shipping: shipping(methodId: "standard", amount: 500)
        )

        try await sut.handleShippingAddressChange(address)

        XCTAssertEqual(summaries, [
            "SHIPPING_ADDRESS_CHANGE sheet_open answered",
            "SHIPPING_OPTION_CHANGE default answered",
            "SHIPPING_COMMIT default committed"
        ])
        XCTAssertEqual(logs.value[0].optionsCount, 2)
        XCTAssertNotNil(logs.value[0].durationMs)
        XCTAssertNotNil(logs.value[1].durationMs)
        XCTAssertNil(logs.value[1].optionsCount)
        XCTAssertEqual(logs.value[2].shippingMethodId, "standard")
        XCTAssertNil(logs.value[2].durationMs)
    }

    func test_laterAddress_isAnAddressEdit() async throws {
        let sut = makeSession(onAddressChange: { _ in [] })

        try await sut.handleShippingAddressChange(address)
        try await sut.handleShippingAddressChange(address)

        XCTAssertEqual(summaries, [
            "SHIPPING_ADDRESS_CHANGE sheet_open answered",
            "SHIPPING_ADDRESS_CHANGE address_edit answered"
        ])
        XCTAssertEqual(logs.value.map(\.optionsCount), [0, 0])
    }

    func test_optionChange_preselectedOptionIsDefault_anotherIsTheShoppers() async throws {
        let held = Box(shipping(methodId: "standard", amount: 500)())
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard, Self.express] },
            onOptionChange: { held.value = ClientSession.Order.ShippingMethod(
                amount: $0.selectedShippingOption.amount,
                methodId: $0.selectedShippingOption.id,
                methodName: nil,
                methodDescription: nil
            ) },
            shipping: { held.value }
        )
        try await sut.handleShippingAddressChange(address)
        logs.value.removeAll()

        try await sut.handleShippingOptionChange(optionId: "standard")
        try await sut.handleShippingOptionChange(optionId: "express")

        XCTAssertEqual(summaries, [
            "SHIPPING_OPTION_CHANGE default answered",
            "SHIPPING_COMMIT default committed",
            "SHIPPING_OPTION_CHANGE shopper answered",
            "SHIPPING_COMMIT shopper committed"
        ])
        XCTAssertEqual(logs.value[3].shippingMethodId, "express")
    }

    func test_addressOnly_logsOnlyTheAddress() async throws {
        let sut = makeSession(mode: .addressOnly, onAddressChange: { _ in [] })

        try await sut.handleShippingAddressChange(address)

        XCTAssertEqual(summaries, ["SHIPPING_ADDRESS_CHANGE sheet_open answered"])
    }

    func test_legacyMode_logsNothing() async throws {
        let sut = makeSession(mode: .legacy, onAddressChange: { _ in [Self.standard] })

        try await sut.handleShippingAddressChange(address)
        try await sut.handleShippingOptionChange(optionId: "standard")

        XCTAssertTrue(logs.value.isEmpty)
    }

    // MARK: - No handler

    func test_addressChange_withoutHandler_logsNoHandler() async throws {
        let sut = makeSession()

        try await sut.handleShippingAddressChange(address)

        XCTAssertEqual(summaries, ["SHIPPING_ADDRESS_CHANGE sheet_open no_handler"])
        XCTAssertNil(logs.value[0].durationMs)
    }

    func test_optionChange_withoutHandler_logsNoHandlerThenTheCommit() async throws {
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard] },
            shipping: shipping(methodId: "standard", amount: 500)
        )

        try await sut.handleShippingAddressChange(address)

        XCTAssertEqual(summaries, [
            "SHIPPING_ADDRESS_CHANGE sheet_open answered",
            "SHIPPING_OPTION_CHANGE default no_handler",
            "SHIPPING_COMMIT default committed"
        ])
    }

    // MARK: - Timeout and failure

    func test_addressHandlerTimeout_logsTimeoutWithItsDuration() async {
        let sut = makeSession(
            onAddressChange: { _ in
                try await Task.sleep(nanoseconds: 5_000_000_000)
                return []
            },
            timeout: 0.2
        )

        try? await sut.handleShippingAddressChange(address)

        XCTAssertEqual(summaries, ["SHIPPING_ADDRESS_CHANGE sheet_open timeout"])
        XCTAssertGreaterThanOrEqual(logs.value[0].durationMs ?? 0, 200)
        XCTAssertNil(logs.value[0].optionsCount)
    }

    func test_optionHandlerTimeout_logsTimeoutAndNoCommit() async {
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard] },
            onOptionChange: { _ in try await Task.sleep(nanoseconds: 5_000_000_000) },
            timeout: 0.2
        )

        try? await sut.handleShippingAddressChange(address)

        XCTAssertEqual(summaries, [
            "SHIPPING_ADDRESS_CHANGE sheet_open answered",
            "SHIPPING_OPTION_CHANGE default timeout"
        ])
        XCTAssertGreaterThanOrEqual(logs.value[1].durationMs ?? 0, 200)
    }

    func test_throwingHandler_logsFailed() async {
        let sut = makeSession(onAddressChange: { _ in throw PrimerError.unknown(message: "rates unavailable") })

        try? await sut.handleShippingAddressChange(address)

        XCTAssertEqual(summaries, ["SHIPPING_ADDRESS_CHANGE sheet_open failed"])
        XCTAssertNotNil(logs.value[0].durationMs)
    }

    func test_cancelledAttempt_logsNothingForTheHandler() async {
        let sut = makeSession(onAddressChange: { _ in
            try await Task.sleep(nanoseconds: 5_000_000_000)
            return []
        })

        let attempt = Task { try await sut.handleShippingAddressChange(address) }
        try? await Task.sleep(nanoseconds: 50_000_000)
        attempt.cancel()
        _ = await attempt.result

        XCTAssertTrue(logs.value.isEmpty)
    }

    // MARK: - Commit verification

    func test_commitMismatch_logsMismatch() async {
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard] },
            onOptionChange: { _ in },
            shipping: shipping(methodId: "standard", amount: 100)
        )

        try? await sut.handleShippingAddressChange(address)

        XCTAssertEqual(summaries.last, "SHIPPING_COMMIT default mismatch")
        XCTAssertNil(logs.value.last?.shippingMethodId)
    }

    func test_commitRefreshFailure_logsRefreshFailed() async {
        let sut = makeSession(
            onAddressChange: { _ in [Self.standard] },
            onOptionChange: { _ in },
            shipping: shipping(methodId: "standard", amount: 500),
            refresh: { throw PrimerError.unknown() }
        )

        try? await sut.handleShippingAddressChange(address)

        XCTAssertEqual(summaries, [
            "SHIPPING_ADDRESS_CHANGE sheet_open answered",
            "SHIPPING_OPTION_CHANGE default answered",
            "SHIPPING_COMMIT default refresh_failed"
        ])
    }

    // MARK: - Helpers

    private final class Box<T>: @unchecked Sendable {
        var value: T
        init(_ value: T) { self.value = value }
    }

    private var summaries: [String] {
        logs.value.map { "\($0.event.rawValue) \($0.trigger.rawValue) \($0.outcome.rawValue)" }
    }

    private func makeSession(
        mode: ApplePayShippingSession.Mode = .callbacks,
        onAddressChange: ShippingAddressChangeHandler? = nil,
        onOptionChange: ShippingOptionChangeHandler? = nil,
        shipping: @escaping () -> ClientSession.Order.ShippingMethod? = { nil },
        refresh: @escaping () async throws -> Void = {},
        timeout: TimeInterval = ApplePayShippingSession.callbackTimeout
    ) -> ApplePayShippingSession {
        ApplePayShippingSession(
            mode: mode,
            addressChangeProvider: { onAddressChange },
            optionChangeProvider: { onOptionChange },
            refreshConfiguration: refresh,
            currentShipping: shipping,
            timeout: timeout,
            report: { [logs] in logs.value.append($0) }
        )
    }

    private func shipping(methodId: String, amount: Int) -> () -> ClientSession.Order.ShippingMethod? {
        { ClientSession.Order.ShippingMethod(amount: amount, methodId: methodId, methodName: nil, methodDescription: nil) }
    }
}
