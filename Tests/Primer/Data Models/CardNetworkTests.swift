//
//  CardNetworkTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class CardNetworkTests: XCTestCase {

    typealias CardNetworks = [CardNetwork]

    override func setUp() {
        SDKSessionHelper.setUp()
    }

    override func tearDown() {
        SDKSessionHelper.tearDown()
    }

    func testCardNetworksAvailable() throws {
        // Default value
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: .allCardNetworks)
        XCTAssertEqual(CardNetworks.allCardNetworks, CardNetwork.allCases)
        XCTAssertEqual(CardNetworks.allowedCardNetworks, CardNetwork.allCases)

        // w/ CB
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.cartesBancaires])
        XCTAssertEqual(CardNetworks.allCardNetworks, CardNetwork.allCases)
        XCTAssertEqual(CardNetworks.allowedCardNetworks, [.cartesBancaires])

        // w/ mixed
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.visa, .masterCard, .amex])
        XCTAssertEqual(CardNetworks.allCardNetworks, CardNetwork.allCases)
        XCTAssertEqual(CardNetworks.allowedCardNetworks, [.visa, .masterCard, .amex])

        // w/ none
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [])
        XCTAssertEqual(CardNetworks.allCardNetworks, CardNetwork.allCases)
        XCTAssertEqual(CardNetworks.allowedCardNetworks, [])
    }

    // MARK: - Surcharge Tests

    func testSurchargeReturnsValueForPositiveSurcharge() {
        SDKSessionHelper.setUp(paymentMethodOptions: [[
            "type": PrimerPaymentMethodType.paymentCard.rawValue,
            "networks": [
                ["type": "VISA", "surcharge": 100]
            ]
        ]])

        XCTAssertEqual(CardNetwork.visa.surcharge, 100)
    }

    func testSurchargeReturnsNilForZeroSurcharge() {
        SDKSessionHelper.setUp(paymentMethodOptions: [[
            "type": PrimerPaymentMethodType.paymentCard.rawValue,
            "networks": [
                ["type": "VISA", "surcharge": 0]
            ]
        ]])

        XCTAssertNil(CardNetwork.visa.surcharge)
    }

    func testSurchargeReturnsNilForNegativeSurcharge() {
        SDKSessionHelper.setUp(paymentMethodOptions: [[
            "type": PrimerPaymentMethodType.paymentCard.rawValue,
            "networks": [
                ["type": "VISA", "surcharge": -50]
            ]
        ]])

        XCTAssertNil(CardNetwork.visa.surcharge)
    }

    func testSurchargeReturnsNilWhenNotConfigured() {
        SDKSessionHelper.setUp(paymentMethodOptions: nil)

        XCTAssertNil(CardNetwork.visa.surcharge)
    }
}
