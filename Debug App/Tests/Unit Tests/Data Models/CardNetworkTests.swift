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
    
    func testCardNetworksAvailable() throws {
        // Default value
        XCTAssertEqual(CardNetworks.allCardNetworks, CardNetwork.allCases)
        XCTAssertEqual(CardNetworks.supportedCardNetworks, CardNetwork.allCases)
        
        // w/ CB
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [.cartesBancaires])
        XCTAssertEqual(CardNetworks.allCardNetworks, CardNetwork.allCases)
        XCTAssertEqual(CardNetworks.supportedCardNetworks, [.cartesBancaires])
        
        // w/ mixed
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [.visa, .masterCard, .amex])
        XCTAssertEqual(CardNetworks.allCardNetworks, CardNetwork.allCases)
        XCTAssertEqual(CardNetworks.supportedCardNetworks, [.visa, .masterCard, .amex])
        
        // w/ none
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [])
        XCTAssertEqual(CardNetworks.allCardNetworks, CardNetwork.allCases)
        XCTAssertEqual(CardNetworks.supportedCardNetworks, [])
    }
}
