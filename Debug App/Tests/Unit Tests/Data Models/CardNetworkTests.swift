//
//  CardNetworkTests.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 08/11/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class CardNetworkTests: XCTestCase {

    typealias CardNetworks = Array<CardNetwork>
    
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
        XCTAssertEqual(CardNetworks.supportedCardNetworks, CardNetwork.allCases)
        
        // w/ CB
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.cartesBancaires])
        XCTAssertEqual(CardNetworks.allCardNetworks, CardNetwork.allCases)
        XCTAssertEqual(CardNetworks.supportedCardNetworks, [.cartesBancaires])
        
        // w/ mixed
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.visa, .masterCard, .amex])
        XCTAssertEqual(CardNetworks.allCardNetworks, CardNetwork.allCases)
        XCTAssertEqual(CardNetworks.supportedCardNetworks, [.visa, .masterCard, .amex])
        
        // w/ none
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [])
        XCTAssertEqual(CardNetworks.allCardNetworks, CardNetwork.allCases)
        XCTAssertEqual(CardNetworks.supportedCardNetworks, [])
    }
}
