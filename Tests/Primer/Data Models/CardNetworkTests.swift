//
//  CardNetworkTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@testable import PrimerSDK
import XCTest

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

    // MARK: - Traits Tests

    func testTraitsCoversAllCasesWithExpectedNilSet() {
        let knownNil: Set<CardNetwork> = [.bancontact, .cartesBancaires, .eftpos, .unknown]
        for network in CardNetwork.allCases {
            if knownNil.contains(network) {
                XCTAssertNil(network.traits, "\(network.rawValue) expected nil traits")
            } else {
                XCTAssertNotNil(network.traits, "\(network.rawValue) expected non-nil traits")
            }
        }
    }

    func testTraitsForAmex() throws {
        let traits = try XCTUnwrap(CardNetwork.amex.traits)
        XCTAssertEqual(traits.cardNetwork, .amex)
        XCTAssertEqual(traits.displayName, "American Express")
        XCTAssertEqual(traits.panLengths, [15])
        XCTAssertEqual(traits.gapPattern, [4, 10])
        XCTAssertEqual(traits.cvvLength, 4)
        XCTAssertEqual(traits.cvvLabel, "CID")
    }

    func testTraitsForVisa() throws {
        let traits = try XCTUnwrap(CardNetwork.visa.traits)
        XCTAssertEqual(traits.cardNetwork, .visa)
        XCTAssertEqual(traits.displayName, "Visa")
        XCTAssertEqual(traits.panLengths, [16, 18, 19])
        XCTAssertEqual(traits.gapPattern, [4, 8, 12])
        XCTAssertEqual(traits.cvvLength, 3)
        XCTAssertEqual(traits.cvvLabel, "CVV")
    }

    func testTraitsForMirAndEloPreserveCvvLabels() throws {
        let mir = try XCTUnwrap(CardNetwork.mir.traits)
        XCTAssertEqual(mir.cvvLabel, "CVP2")
        let elo = try XCTUnwrap(CardNetwork.elo.traits)
        XCTAssertEqual(elo.cvvLabel, "CVE")
    }
}
