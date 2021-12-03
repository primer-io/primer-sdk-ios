//
//  PaymentCard.swift
//  PrimerSDKExample_UITests
//
//  Created by Evangelos on 1/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest

class PaymentCard: XCTestCase {
    
    let app = XCUIApplication()
    let pm = PaymentMethod(
        id: "PAYMENT_CARD",
        environment: .sandbox,
        currency: "GBP",
        countryCode: "GB",
        amount: "1.00",
        expecations: PaymentMethod.Expecations(
            amount: "£1.00",
            surcharge: "Additional fee may apply",
            webviewImage: nil,
            webviewTexts: nil,
            buttonTexts: ["Pay £1.00"]))

    override func setUp() {
        super.setUp()
        app.launchArguments = ["UITesting"]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testCard() throws {
        try Base().testInitialize(
            env: pm.environment.rawValue,
            customerId: nil,
            phoneNumber: nil,
            countryCode: pm.countryCode,
            currency: pm.currency,
            amount: pm.amount,
            performPayment: true)
        
        let universalCheckoutButton = app.buttons["universal_checkout_button"]
        universalCheckoutButton.tap()

        // Test that title is correct
        let checkoutTitle = app.staticTexts["Choose payment method"]
        let vaultTitle = app.staticTexts["Add payment method"]
        let exists = NSPredicate(format: "exists == true")
        let doesNotExist = NSPredicate(format: "exists == false")
        expectation(for: exists, evaluatedWith: checkoutTitle, handler: nil)
        expectation(for: doesNotExist, evaluatedWith: vaultTitle, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)

        if let amountExpectation = pm.expecations?.amount {
            let amountText = app.staticTexts[amountExpectation]
            XCTAssert(amountText.exists, "Amount '\(amountExpectation)' should exist")
        }

        let scrollView = app.scrollViews["primer_container_scroll_view"]
        if let surchargeExpectation = pm.expecations?.surcharge {
            Base.validateSurcharge(surchargeExpectation, forPaymentMethod: pm.id)
        }
        
        let paymentMethodButton = scrollView.otherElements.buttons[pm.id]
        
        if !paymentMethodButton.exists {
            var isHittable: Bool = false
            while !isHittable {
                scrollView.swipeUp()
                isHittable = paymentMethodButton.isHittable
            }
        }
        
        paymentMethodButton.tap()
        
        let cardnumberTextField = app/*@START_MENU_TOKEN@*/.textFields["card_txt_fld"]/*[[".textFields[\"4242 4242 4242 4242\"]",".textFields[\"card_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let expiryTextField = app.textFields["expiry_txt_fld"]
        let cvcTextField = app.textFields["cvc_txt_fld"]
        let cardholderTextField = app.textFields["card_holder_txt_fld"]
        let submitButton = app.buttons["submit_btn"]
        
        if let submitButtonTexts = pm.expecations?.buttonTexts {
            for text in submitButtonTexts {
                let submitButtonText = submitButton.staticTexts[text]
                XCTAssert(submitButtonText.exists, "Submit button should have text '\(text)'")
            }
        }
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.tap()
        cardnumberTextField.typeText("4")
        var submitButtonText = submitButton.staticTexts["Pay £3.88"]
        var submitButtonTextExists = expectation(for: exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.clearText()
        submitButtonText = submitButton.staticTexts["Pay £1.00"]
        submitButtonTextExists = expectation(for: exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        cardnumberTextField.typeText("51")
        submitButtonTextExists = expectation(for: exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        submitButtonText = submitButton.staticTexts["Pay £4.88"]
        submitButtonTextExists = expectation(for: exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.clearText()
        cardnumberTextField.typeText("4242424242424242")
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        expiryTextField.tap()
        expiryTextField.typeText("0222")
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cvcTextField.tap()
        cvcTextField.typeText("123")
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardholderTextField.tap()
        cardholderTextField.typeText("John Smith")
        
        XCTAssert(submitButton.isEnabled, "Submit button should be enabled")
        
        submitButton.tap()
        
        let successLabel = app.staticTexts["success_screen_message_label"]
        let successLabelExists = expectation(for: exists, evaluatedWith: successLabel, handler: nil)
        wait(for: [successLabelExists], timeout: 15)
    }
    
    func testRec() throws {
        
        let app = XCUIApplication()
        app/*@START_MENU_TOKEN@*/.staticTexts["Initialize Primer SDK"]/*[[".buttons[\"Initialize Primer SDK\"].staticTexts[\"Initialize Primer SDK\"]",".buttons[\"initialize_primer_sdk\"].staticTexts[\"Initialize Primer SDK\"]",".staticTexts[\"Initialize Primer SDK\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Universal Checkout"]/*[[".buttons[\"Universal Checkout\"].staticTexts[\"Universal Checkout\"]",".buttons[\"universal_checkout_button\"].staticTexts[\"Universal Checkout\"]",".staticTexts[\"Universal Checkout\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        let elementsQuery = app.scrollViews["primer_container_scroll_view"].otherElements
        elementsQuery/*@START_MENU_TOKEN@*/.buttons["ADYEN_MOBILEPAY"]/*[[".otherElements[\"no_additional_fees_surcharge_group_view\"]",".buttons[\"mobile pay logo\"]",".buttons[\"ADYEN_MOBILEPAY\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.swipeUp()
        elementsQuery/*@START_MENU_TOKEN@*/.staticTexts["Pay with card"]/*[[".otherElements[\"additional_fees_surcharge_group_view\"]",".buttons[\"Pay with card\"].staticTexts[\"Pay with card\"]",".buttons[\"PAYMENT_CARD\"].staticTexts[\"Pay with card\"]",".staticTexts[\"Pay with card\"]"],[[[-1,3],[-1,2],[-1,1],[-1,0,1]],[[-1,3],[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        elementsQuery/*@START_MENU_TOKEN@*/.textFields["card_txt_fld"]/*[[".textFields[\"4242 4242 4242 4242\"]",".textFields[\"card_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.staticTexts["Paste"]/*[[".menus",".menuItems[\"Paste\"].staticTexts[\"Paste\"]",".staticTexts[\"Paste\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        elementsQuery/*@START_MENU_TOKEN@*/.textFields["expiry_txt_fld"]/*[[".textFields[\"02\/22\"]",".textFields[\"expiry_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        elementsQuery/*@START_MENU_TOKEN@*/.textFields["cvc_txt_fld"]/*[[".textFields[\"123\"]",".textFields[\"cvc_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        elementsQuery/*@START_MENU_TOKEN@*/.textFields["card_holder_txt_fld"]/*[[".textFields[\"John Smith\"]",".textFields[\"card_holder_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        elementsQuery/*@START_MENU_TOKEN@*/.buttons["submit_btn"]/*[[".buttons[\"Pay RON 0.20\"]",".buttons[\"submit_btn\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
    }
    
    func test3DS() throws {
        try Base().testInitialize(
            env: pm.environment.rawValue,
            customerId: nil,
            phoneNumber: nil,
            countryCode: pm.countryCode,
            currency: "RON",
            amount: pm.amount,
            performPayment: true)
        
        let universalCheckoutButton = app.buttons["universal_checkout_button"]
        universalCheckoutButton.tap()

        // Test that title is correct
        let checkoutTitle = app.staticTexts["Choose payment method"]
        let vaultTitle = app.staticTexts["Add payment method"]
        let exists = NSPredicate(format: "exists == true")
        let doesNotExist = NSPredicate(format: "exists == false")
        expectation(for: exists, evaluatedWith: checkoutTitle, handler: nil)
        expectation(for: doesNotExist, evaluatedWith: vaultTitle, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)

        if let amountExpectation = pm.expecations?.amount {
            let amountText = app.staticTexts[amountExpectation]
            XCTAssert(amountText.exists, "Amount '\(amountExpectation)' should exist")
        }

        let scrollView = app.scrollViews["primer_container_scroll_view"]
        if let surchargeExpectation = pm.expecations?.surcharge {
            Base.validateSurcharge(surchargeExpectation, forPaymentMethod: pm.id)
        }
        
        let paymentMethodButton = scrollView.otherElements.buttons[pm.id]
        
        if !paymentMethodButton.exists {
            var isHittable: Bool = false
            while !isHittable {
                scrollView.swipeUp()
                isHittable = paymentMethodButton.isHittable
            }
        }
        
        paymentMethodButton.tap()
        
        let cardnumberTextField = app/*@START_MENU_TOKEN@*/.textFields["card_txt_fld"]/*[[".textFields[\"4242 4242 4242 4242\"]",".textFields[\"card_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let expiryTextField = app.textFields["expiry_txt_fld"]
        let cvcTextField = app.textFields["cvc_txt_fld"]
        let cardholderTextField = app.textFields["card_holder_txt_fld"]
        let submitButton = app.buttons["submit_btn"]
        
        if let submitButtonTexts = pm.expecations?.buttonTexts {
            for text in submitButtonTexts {
                let submitButtonText = submitButton.staticTexts[text]
                XCTAssert(submitButtonText.exists, "Submit button should have text '\(text)'")
            }
        }
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.tap()
        cardnumberTextField.typeText("4")
        var submitButtonText = submitButton.staticTexts["Pay £3.88"]
        var submitButtonTextExists = expectation(for: exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.clearText()
        submitButtonText = submitButton.staticTexts["Pay £1.00"]
        submitButtonTextExists = expectation(for: exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        cardnumberTextField.typeText("51")
        submitButtonTextExists = expectation(for: exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        submitButtonText = submitButton.staticTexts["Pay £4.88"]
        submitButtonTextExists = expectation(for: exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.clearText()
        cardnumberTextField.typeText("4242424242424242")
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        expiryTextField.tap()
        expiryTextField.typeText("0222")
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cvcTextField.tap()
        cvcTextField.typeText("123")
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardholderTextField.tap()
        cardholderTextField.typeText("John Smith")
        
        XCTAssert(submitButton.isEnabled, "Submit button should be enabled")
        
        submitButton.tap()
        
        let successLabel = app.staticTexts["success_screen_message_label"]
        let successLabelExists = expectation(for: exists, evaluatedWith: successLabel, handler: nil)
        wait(for: [successLabelExists], timeout: 15)
    }

}
