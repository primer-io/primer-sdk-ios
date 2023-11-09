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

    typealias CardNetworks = Set<CardNetwork>
    
    override func tearDown() {
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init()
        super.tearDown()
    }
    
    func testCardNetworksAvailable() throws {
        // Default value
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init()
        XCTAssertEqual(CardNetworks.allCardNetworks, Set(CardNetwork.allCases))
        XCTAssertEqual(CardNetworks.supportedCardNetworks, Set(CardNetwork.allCases))
        
        // w/ CB
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [.cartesBancaires])
        XCTAssertEqual(CardNetworks.allCardNetworks, Set(CardNetwork.allCases))
        XCTAssertEqual(CardNetworks.supportedCardNetworks, [.cartesBancaires])
        
        // w/ mixed
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [.visa, .masterCard, .amex])
        XCTAssertEqual(CardNetworks.allCardNetworks, Set(CardNetwork.allCases))
        XCTAssertEqual(CardNetworks.supportedCardNetworks, [.visa, .masterCard, .amex])
        
        // w/ none
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [])
        XCTAssertEqual(CardNetworks.allCardNetworks, Set(CardNetwork.allCases))
        XCTAssertEqual(CardNetworks.supportedCardNetworks, [])
    }
}
