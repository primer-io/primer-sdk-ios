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
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks(cardNetworks: [.cartesBancaires])), Set([.cartesBancaires]))
        
        // w/ mixed
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks(cardNetworks: [.visa, .masterCard, .amex, .cartesBancaires])), Set([.visa, .masterCard, .amex, .cartesBancaires]))
        
        // w/ none
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks(cardNetworks: [])), Set())
    }
    
    func testApplePaySupportedPaymentNetworksViaPrimerSettings() {
        
        // w/ CB
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [.cartesBancaires])
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks()), Set([.cartesBancaires]))
        
        // w/ mixed
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [.visa, .masterCard, .amex, .cartesBancaires])
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks()), Set([.visa, .masterCard, .amex, .cartesBancaires]))
        
        // w/ none
        PrimerSettings.current.paymentMethodOptions.cardPaymentOptions = .init(supportedCardNetworks: [])
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks()), Set())
    }

}
