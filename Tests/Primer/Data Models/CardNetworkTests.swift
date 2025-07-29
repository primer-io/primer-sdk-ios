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
}
