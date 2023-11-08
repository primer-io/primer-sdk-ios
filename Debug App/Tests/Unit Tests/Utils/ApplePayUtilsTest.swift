//
//  ApplePayUtilsTest.swift
//  Debug App Tests
//
//  Created by Jack Newcombe on 08/11/2023.
//  Copyright © 2023 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

final class ApplePayUtilsTest: XCTestCase {

    func testApplePaySupportedPaymentNetworks() {
        // w/ CB
        XCTAssertEqual(ApplePayUtils.supportedPKPaymentNetworks(cardNetworks: [.cartesBancaires]), [.cartesBancaires])
        
        // w/ mixed
        XCTAssertEqual(ApplePayUtils.supportedPKPaymentNetworks(cardNetworks: [.visa, .masterCard, .amex, .cartesBancaires]), [.visa, .masterCard, .amex, .cartesBancaires])
        
        // w/ none
        XCTAssertEqual(ApplePayUtils.supportedPKPaymentNetworks(cardNetworks: []), [])
    }
    
    func testApplePaySupportedPaymentNetworksViaPrimerSettings() {
        
        // w/ CB
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [.cartesBancaires])
        XCTAssertEqual(ApplePayUtils.supportedPKPaymentNetworks(), [.cartesBancaires])
        
        // w/ mixed
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [.visa, .masterCard, .amex, .cartesBancaires])
        XCTAssertEqual(ApplePayUtils.supportedPKPaymentNetworks(), [.visa, .masterCard, .amex, .cartesBancaires])
        
        // w/ none
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [])
        XCTAssertEqual(ApplePayUtils.supportedPKPaymentNetworks(), [])
    }

}
