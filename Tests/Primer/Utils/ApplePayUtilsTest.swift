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

    override func setUp() {
        SDKSessionHelper.setUp()
    }

    override func tearDown() {
        SDKSessionHelper.tearDown()
    }

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
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.cartesBancaires])
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks()), Set([.cartesBancaires]))

        // w/ mixed
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [.visa, .masterCard, .amex, .cartesBancaires])
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks()), Set([.visa, .masterCard, .amex, .cartesBancaires]))

        // w/ none
        SDKSessionHelper.updateAllowedCardNetworks(cardNetworks: [])
        XCTAssertEqual(Set(ApplePayUtils.supportedPKPaymentNetworks()), Set())
    }
}
