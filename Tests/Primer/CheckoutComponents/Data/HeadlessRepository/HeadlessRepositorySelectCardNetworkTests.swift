//
//  HeadlessRepositorySelectCardNetworkTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class SelectCardNetworkTests: XCTestCase {

    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [self] in mockClientSessionActions }
        )
    }

    override func tearDown() {
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func testSelectCardNetwork_AllNetworks_MapToCorrectStrings() async throws {
        let expectedMappings: [(CardNetwork, String)] = [
            (.visa, "VISA"),
            (.masterCard, "MASTERCARD"),
            (.amex, "AMEX"),
            (.discover, "DISCOVER"),
            (.jcb, "JCB"),
            (.diners, "DINERS_CLUB"),
            (.maestro, "MAESTRO"),
            (.elo, "ELO"),
            (.mir, "MIR"),
            (.unionpay, "UNIONPAY"),
            (.bancontact, "BANCONTACT"),
            (.cartesBancaires, "CARTES_BANCAIRES"),
            (.unknown, "OTHER")
        ]

        for (network, expectedString) in expectedMappings {
            mockClientSessionActions.reset()

            await repository.selectCardNetwork(network)
            try await Task.sleep(nanoseconds: 100_000_000)

            XCTAssertEqual(
                mockClientSessionActions.selectPaymentMethodCalls.count,
                1,
                "Expected exactly 1 call for \(network)"
            )
            XCTAssertEqual(
                mockClientSessionActions.selectPaymentMethodCalls.first?.type,
                "PAYMENT_CARD",
                "Expected PAYMENT_CARD type for \(network)"
            )
            XCTAssertEqual(
                mockClientSessionActions.selectPaymentMethodCalls.first?.network,
                expectedString,
                "Expected \(expectedString) for \(network)"
            )
        }
    }

    func testSelectCardNetwork_MultipleNetworks_CallsSelectPaymentMethodMultipleTimes() async throws {
        let networks: [CardNetwork] = [.visa, .masterCard, .amex]

        for network in networks {
            await repository.selectCardNetwork(network)
        }

        try await Task.sleep(nanoseconds: 300_000_000)

        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 3)
    }

    func testSelectCardNetwork_WithError_DoesNotThrow() async throws {
        let network = CardNetwork.visa
        mockClientSessionActions.selectPaymentMethodError = NSError(domain: "test", code: 500)

        await repository.selectCardNetwork(network)

        try await Task.sleep(nanoseconds: 100_000_000)

        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
    }
}
