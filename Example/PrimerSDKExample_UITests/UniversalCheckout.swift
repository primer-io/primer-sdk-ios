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
    let base = Base()

    override func setUp() {
        super.setUp()
        app.launchArguments = ["UITesting"]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
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

        
        expectation(for: Expectation.exists, evaluatedWith: checkoutTitle, handler: nil)
        expectation(for: Expectation.doesNotExist, evaluatedWith: vaultTitle, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        
        let amountText = app.staticTexts["£1.00"]
        XCTAssert(amountText.exists, "Amount '£1.00' should exist")
        
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
    
    func testPresentApplePay() throws {
        let pm = Base.paymentMethods.filter({ $0.id == "APPLE_PAY" }).first!
        
        try base.testInitialize(
            env: pm.environment.rawValue,
            customerId: nil,
            phoneNumber: nil,
            countryCode: pm.countryCode,
            currency: pm.currency,
            amount: pm.amount,
            performPayment: true)

        try base.openUniversalCheckout()

        if let amountExpectation = pm.expecations?.amount {
            let amountText = app.staticTexts[amountExpectation]
            XCTAssert(amountText.exists, "Amount '\(amountExpectation)' should exist")
        }
        
        let scrollView = app.scrollViews["primer_container_scroll_view"]
        if let surchargeExpectation = pm.expecations?.surcharge {
            Base.validateSurcharge(surchargeExpectation, forPaymentMethod: pm.id)
        }
        
        let applePayButton = scrollView.buttons[pm.id]
        applePayButton.tap()
        
        let applePay = XCUIApplication(bundleIdentifier: "com.apple.PassbookUIService")
        let applePayExists = expectation(for: Expectation.exists, evaluatedWith: applePay, handler: nil)
        wait(for: [applePayExists], timeout: 15.0)
        _ = applePay.wait(for: .runningForeground, timeout: 5)

        applePay.buttons["Pay Total, €1.19"].tap()
    }


    func testPayPal() throws {
        let payment = Base.paymentMethods.filter({ $0.id == "PAYPAL" }).first!
        try base.testPayment(payment, cancelPayment: false)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch;
        let alertExists = expectation(for: Expectation.exists, evaluatedWith: alert, handler: nil)
        
        wait(for: [alertExists], timeout: 15)
        
        let alertContinueButton = alert.buttons["Continue"]
        alertContinueButton.tap()
        
        let payNowButton = app.webViews.buttons["Pay Now"].firstMatch
        let payNowButtonExists = expectation(for: Expectation.exists, evaluatedWith: payNowButton, handler: nil)
        wait(for: [payNowButtonExists], timeout: 15)
        payNowButton.tap()

        try base.testSuccessMessageExists()
        try base.testDismissSDK()
        try base.testResultScreenExpectations(for: payment)
    }
    
    func testAdyenAlipay() throws {
        let payment = Base.paymentMethods.filter({ $0.id == "ADYEN_ALIPAY" }).first!
        try base.testPayment(payment)
    }
    
    func testAdyenGiropay() throws {
        let payment = Base.paymentMethods.filter({ $0.id == "ADYEN_GIROPAY" }).first!
        try base.testPayment(payment, cancelPayment: false)
        
        let safariWebView = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'BrowserView?WebViewProcessID'"))
        
        let continueButton = app.webViews.firstMatch.buttons.firstMatch
        let continueButtonIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: continueButton, handler: nil)
        wait(for: [continueButtonIsHittable], timeout: 30)
        continueButton.tap()
        
        let scTextField = app.otherElements.containing(NSPredicate(format: "label == 'sc:'")).firstMatch.textFields.firstMatch
        let scTextFieldIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: scTextField, handler: nil)
        wait(for: [scTextFieldIsHittable], timeout: 30)
        scTextField.tap()
        scTextField.typeText("10")
        
        let toolBarDoneButton = app.toolbars["Toolbar"].firstMatch.buttons["Done"].firstMatch
        toolBarDoneButton.tap()
        
        let extensionScTextField = app.otherElements.containing(NSPredicate(format: "label == 'extensionSc:'")).firstMatch.textFields.element(boundBy: 1)
        extensionScTextField.tap()
        extensionScTextField.typeText("4000")
        
        toolBarDoneButton.tap()
        safariWebView.webViews.firstMatch.pinch(withScale: 0.5, velocity: -0.5)
        
        let customerNameTextField = app.otherElements.containing(NSPredicate(format: "label == 'customerName1:'")).firstMatch.textFields.element(boundBy: 2)
        customerNameTextField.tap()
        customerNameTextField.typeText("John Smith")
        
        toolBarDoneButton.tap()
        safariWebView.webViews.firstMatch.pinch(withScale: 0.5, velocity: -0.5)
        
        let customerIbanTextField = app.otherElements.containing(NSPredicate(format: "label == 'customerIBAN:'")).firstMatch.textFields.element(boundBy: 3)
        customerIbanTextField.tap()
        customerIbanTextField.typeText("DE36444488881234567890")
        
        toolBarDoneButton.tap()
        safariWebView.webViews.firstMatch.pinch(withScale: 0.5, velocity: -0.5)
        
        let submitButton = app.buttons.matching(NSPredicate(format: "label == 'Absenden'")).firstMatch
        submitButton.tap()
        
        try base.testSuccessMessageExists()
        try base.testDismissSDK()
        try base.testResultScreenExpectations(for: payment)
    }
    
    func testAdyenMobilePay() throws {
        let payment = Base.paymentMethods.filter({ $0.id == "ADYEN_MOBILEPAY" }).first!
        try base.testPayment(payment)
    }
    
    func testPayNLBancontact() throws {
        let payment = Base.paymentMethods.filter({ $0.id == "PAY_NL_BANCONTACT" }).first!
        try base.testPayment(payment)
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
