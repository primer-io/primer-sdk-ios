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
    let base = Base()

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
    
    func testCardSurcharge() throws {
        let payment = Base.paymentMethods.filter({ $0.id == "PAYMENT_CARD" }).first!
        try openCardForm(for: payment)
        
        let cardnumberTextField = app/*@START_MENU_TOKEN@*/.textFields["card_txt_fld"]/*[[".textFields[\"4242 4242 4242 4242\"]",".textFields[\"card_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let expiryTextField = app.textFields["expiry_txt_fld"]
        let cvcTextField = app.textFields["cvc_txt_fld"]
        let cardholderTextField = app.textFields["card_holder_txt_fld"]
        let submitButton = app.buttons["submit_btn"]
        
        if let submitButtonTexts = payment.expecations?.buttonTexts {
            for text in submitButtonTexts {
                let submitButtonText = submitButton.staticTexts[text]
                XCTAssert(submitButtonText.exists, "Submit button should have text '\(text)'")
            }
        }
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.tap()
        cardnumberTextField.typeText("4")
        var submitButtonText = submitButton.staticTexts["Pay £2.09"]
        var submitButtonTextExists = expectation(for: Expectation.exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.clearText()
        submitButtonText = submitButton.staticTexts["Pay £1.00"]
        submitButtonTextExists = expectation(for: Expectation.exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        cardnumberTextField.typeText("51")
        submitButtonTextExists = expectation(for: Expectation.exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        submitButtonText = submitButton.staticTexts["Pay £2.29"]
        submitButtonTextExists = expectation(for: Expectation.exists, evaluatedWith: submitButtonText, handler: nil)
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
        let successLabelExists = expectation(for: Expectation.exists, evaluatedWith: successLabel, handler: nil)
        wait(for: [successLabelExists], timeout: 15)
        
        let scrollView = app.scrollViews["primer_container_scroll_view"]
        scrollView.swipeDown()
        
        try base.testResultScreenExpectations(for: payment)
    }
    
    func testPass3DSChallenge() throws {
        let threeDSPayment = Base.paymentMethods.filter({ $0.id == "3DS_PAYMENT_CARD" }).first!
        try openCardForm(for: threeDSPayment)
        
        let cardnumberTextField = app/*@START_MENU_TOKEN@*/.textFields["card_txt_fld"]/*[[".textFields[\"4242 4242 4242 4242\"]",".textFields[\"card_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let expiryTextField = app.textFields["expiry_txt_fld"]
        let cvcTextField = app.textFields["cvc_txt_fld"]
        let cardholderTextField = app.textFields["card_holder_txt_fld"]
        let submitButton = app.buttons["submit_btn"]
        
        if let submitButtonTexts = threeDSPayment.expecations?.buttonTexts {
            for text in submitButtonTexts {
                let submitButtonText = submitButton.staticTexts[text]
                XCTAssert(submitButtonText.exists, "Submit button should have text '\(text)'")
            }
        }
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.tap()
        cardnumberTextField.typeText("9120000000000006")
        
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
        
        let threeDSNavigationBar = app.otherElements.otherElements.navigationBars["SECURE CHECKOUT"]
        let threeDSNavigationBarExists = expectation(for: Expectation.exists, evaluatedWith: threeDSNavigationBar, handler: nil)
        wait(for: [threeDSNavigationBarExists], timeout: 15)
        
        let passChallengeRadioButton = app.children(matching: .window).element(boundBy: 0).scrollViews.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .button).element
        passChallengeRadioButton.tap()
        
        let submit3DSButton = app.buttons["Submit"]
        submit3DSButton.tap()
        
        let successLabel = app.staticTexts["success_screen_message_label"]
        let successLabelExists = expectation(for: Expectation.exists, evaluatedWith: successLabel, handler: nil)
        wait(for: [successLabelExists], timeout: 15)
    }
    
    func testFail3DSChallenge() throws {
        let threeDSPayment = Base.paymentMethods.filter({ $0.id == "3DS_PAYMENT_CARD" }).first!
        try openCardForm(for: threeDSPayment)
        
        let cardnumberTextField = app/*@START_MENU_TOKEN@*/.textFields["card_txt_fld"]/*[[".textFields[\"4242 4242 4242 4242\"]",".textFields[\"card_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let expiryTextField = app.textFields["expiry_txt_fld"]
        let cvcTextField = app.textFields["cvc_txt_fld"]
        let cardholderTextField = app.textFields["card_holder_txt_fld"]
        let submitButton = app.buttons["submit_btn"]
        
        if let submitButtonTexts = threeDSPayment.expecations?.buttonTexts {
            for text in submitButtonTexts {
                let submitButtonText = submitButton.staticTexts[text]
                XCTAssert(submitButtonText.exists, "Submit button should have text '\(text)'")
            }
        }
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.tap()
        cardnumberTextField.typeText("9120000000000006")
        
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
        
        let threeDSNavigationBar = app.otherElements.otherElements.navigationBars["SECURE CHECKOUT"]
        let threeDSNavigationBarExists = expectation(for: Expectation.exists, evaluatedWith: threeDSNavigationBar, handler: nil)
        wait(for: [threeDSNavigationBarExists], timeout: 15)
        
        let failChallengeRadioButton = app.children(matching: .window).element(boundBy: 0).scrollViews.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .button).element
        failChallengeRadioButton.tap()
        
        let submit3DSButton = app.buttons["Submit"]
        submit3DSButton.tap()
        
        let successLabel = app.staticTexts["success_screen_message_label"]
        let successLabelExists = expectation(for: Expectation.exists, evaluatedWith: successLabel, handler: nil)
        wait(for: [successLabelExists], timeout: 15)
    }
    
    func testCancel3DSChallenge() throws {
        let threeDSPayment = Base.paymentMethods.filter({ $0.id == "3DS_PAYMENT_CARD" }).first!
        try openCardForm(for: threeDSPayment)
        
        let cardnumberTextField = app/*@START_MENU_TOKEN@*/.textFields["card_txt_fld"]/*[[".textFields[\"4242 4242 4242 4242\"]",".textFields[\"card_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let expiryTextField = app.textFields["expiry_txt_fld"]
        let cvcTextField = app.textFields["cvc_txt_fld"]
        let cardholderTextField = app.textFields["card_holder_txt_fld"]
        let submitButton = app.buttons["submit_btn"]
        
        if let submitButtonTexts = threeDSPayment.expecations?.buttonTexts {
            for text in submitButtonTexts {
                let submitButtonText = submitButton.staticTexts[text]
                XCTAssert(submitButtonText.exists, "Submit button should have text '\(text)'")
            }
        }
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.tap()
        cardnumberTextField.typeText("9120000000000006")
        
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
        
        let threeDSNavigationBar = app.otherElements.otherElements.navigationBars["SECURE CHECKOUT"]
        let threeDSNavigationBarExists = expectation(for: Expectation.exists, evaluatedWith: threeDSNavigationBar, handler: nil)
        wait(for: [threeDSNavigationBarExists], timeout: 15)
        
        let cancel3DSButton = threeDSNavigationBar.buttons["Cancel"]
        cancel3DSButton.tap()
        
        let errorLabel = app.staticTexts["primer-error-message-3ds-failed"]
        let errorLabelExists = expectation(for: Expectation.exists, evaluatedWith: errorLabel, handler: nil)
        wait(for: [errorLabelExists], timeout: 15)
    }

    // MARK: Helpers
    
    func openCardForm(for payment: Payment) throws {
        try base.testInitialize(
            env: payment.environment.rawValue,
            customerId: nil,
            phoneNumber: nil,
            countryCode: payment.countryCode,
            currency: payment.currency,
            amount: payment.amount,
            performPayment: true)
        
        try base.openUniversalCheckout()

        if let amountExpectation = payment.expecations?.amount {
            let amountText = app.staticTexts[amountExpectation]
            XCTAssert(amountText.exists, "Amount '\(amountExpectation)' should exist")
        }

        let scrollView = app.scrollViews["primer_container_scroll_view"]
        if let surchargeExpectation = payment.expecations?.surcharge {
            Base.validateSurcharge(surchargeExpectation, forPaymentMethod: payment.id)
        }
        
        let paymentMethodButton = scrollView.otherElements.buttons[payment.id]
        
        if !paymentMethodButton.exists {
            var isHittable: Bool = false
            while !isHittable {
                scrollView.swipeUp()
                isHittable = paymentMethodButton.isHittable
            }
        }
        
        paymentMethodButton.tap()
    }
}
