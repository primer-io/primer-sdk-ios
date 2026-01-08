//
//  HeadlessRepositorySelectCardNetworkTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Select Card Network Tests

@available(iOS 15.0, *)
final class SelectCardNetworkTests: XCTestCase {

    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [weak self] in
                self?.mockClientSessionActions ?? MockClientSessionActionsModule()
            }
        )
    }

    override func tearDown() {
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func testSelectCardNetwork_Visa_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.visa

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "VISA")
    }

    func testSelectCardNetwork_Mastercard_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.masterCard

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "MASTERCARD")
    }

    func testSelectCardNetwork_Amex_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.amex

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "AMEX")
    }

    func testSelectCardNetwork_Unknown_CallsSelectPaymentMethodWithOther() async throws {
        // Given
        let network = CardNetwork.unknown

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "OTHER")
    }

    func testSelectCardNetwork_MultipleNetworks_CallsSelectPaymentMethodMultipleTimes() async throws {
        // Given
        let networks: [CardNetwork] = [.visa, .masterCard, .amex]

        // When
        for network in networks {
            await repository.selectCardNetwork(network)
        }

        // Wait for all Tasks to complete
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 3)
    }

    func testSelectCardNetwork_WithError_DoesNotThrow() async throws {
        // Given
        let network = CardNetwork.visa
        mockClientSessionActions.selectPaymentMethodError = NSError(domain: "test", code: 500)

        // When/Then - Should not throw since it's fire-and-forget
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify the call was made
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
    }
}

// MARK: - Select Card Network Additional Tests

@available(iOS 15.0, *)
final class SelectCardNetworkAdditionalTests: XCTestCase {

    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [weak self] in
                self?.mockClientSessionActions ?? MockClientSessionActionsModule()
            }
        )
    }

    override func tearDown() {
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func testSelectCardNetwork_Diners_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.diners

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "DINERS_CLUB")
    }

    func testSelectCardNetwork_JCB_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.jcb

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "JCB")
    }

    func testSelectCardNetwork_Discover_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.discover

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "DISCOVER")
    }

    func testSelectCardNetwork_Maestro_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.maestro

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "MAESTRO")
    }

    func testSelectCardNetwork_Elo_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.elo

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "ELO")
    }

    func testSelectCardNetwork_Mir_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.mir

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "MIR")
    }

    func testSelectCardNetwork_UnionPay_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.unionpay

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "UNIONPAY")
    }

    func testSelectCardNetwork_Bancontact_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.bancontact

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "BANCONTACT")
    }

    func testSelectCardNetwork_CartesBancaires_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.cartesBancaires

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "CARTES_BANCAIRES")
    }
}
