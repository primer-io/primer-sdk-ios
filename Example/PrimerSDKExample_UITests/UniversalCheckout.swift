//
//  UniversalCheckout.swift
//  PrimerSDKExample_UITests
//
//  Created by Evangelos Pittas on 15/6/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest

class UniversalCheckout: XCTestCase {
    
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        app.launchArguments = ["UITesting"]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testInitialization() throws {
        let envSegmentedControl = app.segmentedControls["env_control"]
        let devEnv = envSegmentedControl.buttons["Dev"]
        let sandboxEnv = envSegmentedControl.buttons["Sandbox"]
        let stagingEnv = envSegmentedControl.buttons["Staging"]
        let prodcutionEnv = envSegmentedControl.buttons["Production"]

        sandboxEnv.tap()
        devEnv.tap()
        let phoneNumberTextField = app.textFields["phone_number_txt_field"]
        phoneNumberTextField.tap()
        let countryCodeTextField = app.textFields["country_code_txt_field"]
        countryCodeTextField.tap()
        let currencyTextField = app.textFields["currency_txt_field"]
        currencyTextField.tap()
        let amountTextField = app.textFields["amount_txt_field"]
        amountTextField.tap()
        let performPaymentSwitch = app.switches["perform_payment_switch"]
        performPaymentSwitch.tap()
    }

    func testUniversalCheckout() throws {
        try Base().testInitialize(
            env: "sandbox",
            customerId: "customer_id",
            phoneNumber: "+447888888888",
            countryCode: "GB",
            currency: "GBP",
            amount: "1.00",
            performPayment: false)
        
        let universalCheckoutButton = app.buttons["universal_checkout_button"]
        universalCheckoutButton.tap()

        // Test that title is correct
        let checkoutTitle = app.staticTexts["Choose payment method"]
        let vaultTitle = app.staticTexts["Add payment method"]
        let exists = NSPredicate(format: "exists == true")
        let doesNotExist = NSPredicate(format: "exists == false")
        expectation(for: exists, evaluatedWith: checkoutTitle, handler: nil)
        expectation(for: doesNotExist, evaluatedWith: vaultTitle, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        
        // UI tests are a black box, we cannot access the actual amount from the code.
        // Test against € 0.05 since we know that this is the configuration we pass.
        // Test that the amount exists
        let amountText = app.staticTexts["£1.00"]
//        XCTAssert(amountText.exists, "Amount '£1.00' should exist")
        
        let savedPaymentMethodTitle = app.staticTexts["SAVED PAYMENT METHOD"]
        let seeAllButton = app.staticTexts["See all"]
        let savedPaymentMethodView = app.buttons["saved_payment_method_button"]
        
        if savedPaymentMethodTitle.exists {
            // If there's a saved payment method, test that the view and the 'see all' button exist.
            XCTAssert(seeAllButton.exists, "'See All' button should exist")
            XCTAssert(savedPaymentMethodView.exists, "Saved payment method view should not exist")
        } else {
            // If there isn't a saved payment method, test that the view and the 'see all' button do not exist.
            XCTAssert(!seeAllButton.exists, "'See All' button should exist")
            XCTAssert(!savedPaymentMethodView.exists, "Saved payment method view should not exist")
        }
    }

}
