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

    override func setUp() {
        super.setUp()
        app.launchArguments = ["UITesting"]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func testVault() throws {
        let initSDKButton = app.buttons["initialize_primer_sdk"]
        initSDKButton.tap()
        
        let vaultButton = app.buttons["vault_button"]
        vaultButton.tap()

        // Test that title is correct
        let vaultTitle = app.staticTexts["Add payment method"]
        let checkoutTitle = app.staticTexts["Choose payment method"]
        let exists = NSPredicate(format: "exists == true")
        let doesNotExist = NSPredicate(format: "exists == false")
        expectation(for: doesNotExist, evaluatedWith: checkoutTitle, handler: nil)
        expectation(for: exists, evaluatedWith: vaultTitle, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        
        // UI tests are a black box, we cannot access the actual amount from the code.
        // Test against € 0.05 since we know that this is the configuration we pass.
        // Test that the amount exists
        let amountText = app.staticTexts["€0.05"]
        XCTAssert(!amountText.exists, "Amount '€0.05' should not exist")
        
        let savedPaymentMethodTitle = app.staticTexts["SAVED PAYMENT METHOD"]
        let seeAllButton = app.buttons["See All"]
        let savedPaymentMethodView = app.buttons["saved_payment_method_button"]
        
        XCTAssert(!savedPaymentMethodTitle.exists, "Saved payment method should not exist")
        XCTAssert(!seeAllButton.exists, "'See All' button should not exist")
        XCTAssert(!savedPaymentMethodView.exists, "Saved payment method view should not exist")
    }

}
