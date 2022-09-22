//
//  Vault.swift
//  PrimerSDKExample_UITests
//
//  Created by Evangelos Pittas on 15/6/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest

class Vault: XCTestCase {
    
    let app = XCUIApplication()
    let base = Base()

    override func setUp() {
        super.setUp()
        app.launchArguments = ["UITesting"]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testVault() throws {
        try base.testInitialize(
            env: "sandbox",
            customerId: "customer_id",
            phoneNumber: "+447888888888",
            countryCode: "GB",
            currency: "GBP",
            amount: "1.00",
            performPayment: false)
        
        try base.openVaultManager()
        
        // UI tests are a black box, we cannot access the actual amount from the code.
        // Test against € 0.05 since we know that this is the configuration we pass.
        // Test that the amount exists
        let amountText = app.staticTexts["£1.00"]
        XCTAssert(!amountText.exists, "Amount '£1.00' should not exist")
        
        let savedPaymentMethodTitle = app.staticTexts["SAVED PAYMENT METHOD"]
        let seeAllButton = app.buttons["See All"]
        let savedPaymentMethodView = app.buttons["saved_payment_method_button"]
        
        XCTAssert(!savedPaymentMethodTitle.exists, "Saved payment method should not exist")
        XCTAssert(!seeAllButton.exists, "'See All' button should not exist")
        XCTAssert(!savedPaymentMethodView.exists, "Saved payment method view should not exist")
    }

}
