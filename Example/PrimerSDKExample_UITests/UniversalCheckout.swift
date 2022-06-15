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
            amount: "100",
            performPayment: false)
        
        let universalCheckoutButton = app.buttons["universal_checkout_button"]
        universalCheckoutButton.tap()

        // Test that title is correct
        let checkoutTitle = app.staticTexts["Choose payment method"]
        let vaultTitle = app.staticTexts["Add payment method"]

        
        expectation(for: Expectation.exists, evaluatedWith: checkoutTitle, handler: nil)
        expectation(for: Expectation.doesNotExist, evaluatedWith: vaultTitle, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        
        let amountText = app.staticTexts["£2.00"]
        XCTAssert(amountText.exists, "Amount '£2.00' should exist")
        
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
        let pm = Base.paymentMethods.filter({ $0.alias == "APPLE_PAY" }).first!
        
        try base.testInitialize(
            env: pm.environment.rawValue,
            customerId: nil,
            phoneNumber: nil,
            countryCode: pm.countryCode,
            currency: pm.currency,
            amount: pm.amount,
            performPayment: true)

        try base.openUniversalCheckout()

        if let amountExpectation = pm.expectations?.amount {
            let amountText = app.staticTexts[amountExpectation]
            XCTAssert(amountText.exists, "Amount '\(amountExpectation)' should exist")
        }
        
        let scrollView = app.scrollViews["primer_container_scroll_view"]
        if let surchargeExpectation = pm.expectations?.surcharge {
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
        let payment = Base.paymentMethods.filter({ $0.alias == "PAYPAL" }).first!
        try base.testPayment(payment, cancelPayment: false)

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch;
        let alertExists = expectation(for: Expectation.exists, evaluatedWith: alert, handler: nil)
        
        wait(for: [alertExists], timeout: 15)
        
        let alertContinueButton = alert.buttons["Continue"]
        alertContinueButton.tap()
        
        let cancelButton = app.buttons.matching(NSPredicate(format: "label == 'Cancel'")).firstMatch
        cancelButton.tap()

        try base.dismissSDK()
    }
    
    func testAdyenAlipay() throws {
        let payment = Base.paymentMethods.filter({ $0.alias == "ADYEN_ALIPAY" }).first!
        try base.testPayment(payment)
    }
    
    func testAdyenGiropay() throws {
        let payment = Base.paymentMethods.filter({ $0.alias == "ADYEN_GIROPAY" }).first!
        try base.testPayment(payment, cancelPayment: false)
        
        let safariWebView = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'BrowserView?WebViewProcessID'"))
        
        let banknameTextField = app.webViews.textFields.firstMatch
        let banknameTextFieldIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: banknameTextField, handler: nil)
        wait(for: [banknameTextFieldIsHittable], timeout: 30)
        banknameTextField.tap()
        banknameTextField.typeText("Testbank Fiducia 44448888 GENODETT488")
                
        let autocompleteButton = app.webViews.firstMatch.staticTexts.matching(NSPredicate(format: "label == 'Testbank Fiducia 44448888 GENODETT488'")).firstMatch

        if autocompleteButton.exists {
            let autocompleteButtonIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: autocompleteButton, handler: nil)
            wait(for: [autocompleteButtonIsHittable], timeout: 30)
            autocompleteButton.tap()
        }
        
        let continueButton = app.webViews.firstMatch.buttons.matching(NSPredicate(format: "label == 'Weiter zum Bezahlen'")).firstMatch
        let continueButtonIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: continueButton, handler: nil)
        wait(for: [continueButtonIsHittable], timeout: 30)
        continueButton.tap()
                
        let agreeButton = app.webViews.firstMatch.buttons.matching(NSPredicate(format: "label == 'Annehmen'")).firstMatch
        if agreeButton.exists {
            let agreeButtonIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: agreeButton, handler: nil)
            wait(for: [agreeButtonIsHittable], timeout: 30)
            agreeButton.tap()
        }
                
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
        
        try base.successViewExists()
        try base.dismissSDK()
        try base.resultScreenExpectations(for: payment)
    }
    
    func testAdyenMobilePay() throws {
        let payment = Base.paymentMethods.filter({ $0.alias == "ADYEN_MOBILEPAY" }).first!
        try base.testPayment(payment)
    }
    
    func testAdyenBlik() throws {
        let payment = Base.paymentMethods.filter({ $0.id == "ADYEN_BLIK" }).first!
        try openCardForm(for: payment)
        
        XCTAssert(app.images.matching(NSPredicate(format: "identifier CONTAINS 'blik-logo'")).firstMatch.exists, "The Blik logo should be visible")
        
        let sixDigitsBlikTextField = app.textFields.matching(NSPredicate(format: "identifier == 'generic_txt_fld'")).firstMatch
        sixDigitsBlikTextField.tap()
        sixDigitsBlikTextField.typeText("777")
        
        let confirmButton = app.buttons.matching(NSPredicate(format: "label == 'Confirm'")).firstMatch
        
        XCTAssert(confirmButton.isEnabled == false, "The Confirm button should be disabled logo should be visible")

        sixDigitsBlikTextField.typeText("666")
        
        XCTAssert(confirmButton.isEnabled, "The Confirm button should be enabled now")
        
        // Tested till this point as Blik is raising an endless PENDING
    }
    
    func testAdyenDotPayViaBlik() throws {
        let payment = Base.paymentMethods.filter({ $0.id == "ADYEN_DOTPAY" }).first!
        try openCardForm(for: payment)
        
        let safariWebView = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'BrowserView?WebViewProcessID'"))
        
        let buttonImage = safariWebView.images.matching(NSPredicate(format: "label CONTAINS 'BLIK'")).firstMatch
        let buttonImageIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: buttonImage, handler: nil)
        wait(for: [buttonImageIsHittable], timeout: 30)
        buttonImage.tap()

        let firstNameTextField = app.otherElements.containing(NSPredicate(format: "label == 'Firstname:'")).firstMatch.textFields.firstMatch
        let firstNameTextFieldIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: firstNameTextField, handler: nil)
        wait(for: [firstNameTextFieldIsHittable], timeout: 30)
        firstNameTextField.tap()
        firstNameTextField.typeText("John")
        
        let toolBarDoneButton = app.toolbars["Toolbar"].firstMatch.buttons["Done"].firstMatch
        toolBarDoneButton.tap()
        
        let surnameTextField = app.otherElements.containing(NSPredicate(format: "label == 'Surname:'")).firstMatch.textFields.element(boundBy: 1)
        let surnameTextFieldIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: surnameTextField, handler: nil)
        wait(for: [surnameTextFieldIsHittable], timeout: 30)
        surnameTextField.tap()
        surnameTextField.typeText("Smith")

        toolBarDoneButton.tap()
        safariWebView.webViews.firstMatch.pinch(withScale: 0.5, velocity: -0.5)
        
        let emailTextField = app.otherElements.containing(NSPredicate(format: "label == 'Email:'")).firstMatch.textFields.element(boundBy: 2)
        let emailTextFieldIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: emailTextField, handler: nil)
        wait(for: [emailTextFieldIsHittable], timeout: 30)
        emailTextField.tap()
        emailTextField.typeText("john.smith@example.mail.com")
        
        toolBarDoneButton.tap()
        safariWebView.webViews.firstMatch.pinch(withScale: 0.5, velocity: -0.5)
                
        let payButton = app.buttons.matching(NSPredicate(format: "label CONTAINS 'Pay 2.88 PLN'")).firstMatch
        payButton.tap()
        
        let acceptButton = app.buttons.containing(NSPredicate(format: "label == 'accept'")).firstMatch
        let acceptButtonIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: acceptButton, handler: nil)
        wait(for: [acceptButtonIsHittable], timeout: 30)
        acceptButton.tap()
        
        let successLabel = app.staticTexts["result_component_view_message_label"]
        let successLabelExists = expectation(for: Expectation.exists, evaluatedWith: successLabel, handler: nil)
        wait(for: [successLabelExists], timeout: 15)
        
        let scrollView = app.scrollViews["primer_container_scroll_view"]
        scrollView.swipeDown()
        
        try base.resultScreenExpectations(for: payment)
    }
    
    ///  Not possible to test at the moment
    ///  Requires 3DS all the time + real account
    func testPayNLBancontact() throws {
        let payment = Base.paymentMethods.filter({ $0.alias == "PAY_NL_BANCONTACT" }).first!
        try base.testPayment(payment)
    }
    
    func testCardSurcharge() throws {
        let payment = Base.paymentMethods.filter({ $0.alias == "PAYMENT_CARD" }).first!
        try openCardForm(for: payment)
        
        let cardnumberTextField = app/*@START_MENU_TOKEN@*/.textFields["card_txt_fld"]/*[[".textFields[\"4242 4242 4242 4242\"]",".textFields[\"card_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let expiryTextField = app.textFields["expiry_txt_fld"]
        let cvcTextField = app.textFields["cvc_txt_fld"]
        let cardholderTextField = app.textFields["card_holder_txt_fld"]
        let postalCodeTextField = app.textFields["postal_code_txt_fld"]
        let submitButton = app.buttons["submit_btn"]
        
        if let submitButtonTexts = payment.expectations?.buttonTexts {
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
        submitButtonText = submitButton.staticTexts["Pay £2.29"]
        submitButtonTextExists = expectation(for: Expectation.exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardnumberTextField.clearText()
        cardnumberTextField.typeText("4242424242424242")
        submitButtonText = submitButton.staticTexts["Pay £2.09"]
        submitButtonTextExists = expectation(for: Expectation.exists, evaluatedWith: submitButtonText, handler: nil)
        wait(for: [submitButtonTextExists], timeout: 15)
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        expiryTextField.tap()
        expiryTextField.typeText("0225")
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cvcTextField.tap()
        cvcTextField.typeText("123")
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        
        cardholderTextField.tap()
        cardholderTextField.typeText("John Smith")
        
        XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")

        postalCodeTextField.tap()
        postalCodeTextField.typeText("EC1V")
        
        XCTAssert(submitButton.isEnabled, "Submit button should be enabled")
        
        submitButton.tap()
        
        let successLabel = app.staticTexts["result_component_view_message_label"]
        let successLabelExists = expectation(for: Expectation.exists, evaluatedWith: successLabel, handler: nil)
        wait(for: [successLabelExists], timeout: 15)
        
        let scrollView = app.scrollViews["primer_container_scroll_view"]
        scrollView.swipeDown()
        
        try base.resultScreenExpectations(for: payment)
    }
    
    func testPassProcessor3DSChallenge() throws {
        let threeDSPayment = Base.paymentMethods.filter({ $0.alias == "PAYMENT_CARD_WITH_PROCESSOR_3DS_SUCCESS" }).first!
        let card = Base.cards.filter({ $0.alias == "FAILING_CARD_PROCESSOR_3DS" }).first!
        try openCardForm(for: threeDSPayment)
        fillCardDataWithCard(card, for: threeDSPayment, tappingPayOnceEnabled: true)
                
        let completeButton = app.webViews.firstMatch.buttons.containing(NSPredicate(format: "label CONTAINS 'COMPLETE'")).firstMatch
        let completeButtonIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: completeButton, handler: nil)
        wait(for: [completeButtonIsHittable], timeout: 30)
        completeButton.tap()
                
        try base.successViewExists()
        try base.dismissSDK()
        try base.resultScreenExpectations(for: threeDSPayment)
    }
    
    func testFailProcessor3DSChallenge() throws {
        let threeDSPayment = Base.paymentMethods.filter({ $0.alias == "PAYMENT_CARD_WITH_PROCESSOR_3DS_FAIL" }).first!
        let card = Base.cards.filter({ $0.alias == "FAILING_CARD_PROCESSOR_3DS" }).first!
        try openCardForm(for: threeDSPayment)
        fillCardDataWithCard(card, for: threeDSPayment, tappingPayOnceEnabled: true)
                
        let completeButton = app.webViews.firstMatch.buttons.containing(NSPredicate(format: "label CONTAINS 'COMPLETE'")).firstMatch
        let completeButtonIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: completeButton, handler: nil)
        wait(for: [completeButtonIsHittable], timeout: 30)
        completeButton.tap()
                
        try base.successViewExists()
        try base.dismissSDK()
        try base.resultScreenExpectations(for: threeDSPayment)
    }

    
    func testPass3DSChallenge() throws {
        let threeDSPayment = Base.paymentMethods.filter({ $0.alias == "3DS_PAYMENT_CARD" }).first!
        let card = Base.cards.filter({ $0.alias == "3DS_PAYMENT_CARD" }).first!
        try openCardForm(for: threeDSPayment)
        fillCardDataWithCard(card, for: threeDSPayment, tappingPayOnceEnabled: true)
        
        let threeDSNavigationBar = app.otherElements.otherElements.navigationBars["SECURE CHECKOUT"]
        let threeDSNavigationBarExists = expectation(for: Expectation.exists, evaluatedWith: threeDSNavigationBar, handler: nil)
        wait(for: [threeDSNavigationBarExists], timeout: 15)
        
        let passChallengeRadioButton = app.children(matching: .window).element(boundBy: 0).scrollViews.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 0).children(matching: .other).element.children(matching: .button).element
        passChallengeRadioButton.tap()
        
        let submit3DSButton = app.buttons["Submit"]
        submit3DSButton.tap()
        
        let successImage = app.images["check-circle"]
        let successImageExists = expectation(for: Expectation.exists, evaluatedWith: successImage, handler: nil)
        wait(for: [successImageExists], timeout: 15)
    }
    
    func testFail3DSChallenge() throws {
        let threeDSPayment = Base.paymentMethods.filter({ $0.alias == "3DS_PAYMENT_CARD" }).first!
        let card = Base.cards.filter({ $0.alias == "3DS_PAYMENT_CARD" }).first!
        try openCardForm(for: threeDSPayment)
        fillCardDataWithCard(card, for: threeDSPayment, tappingPayOnceEnabled: true)
        
        let threeDSNavigationBar = app.otherElements.otherElements.navigationBars["SECURE CHECKOUT"]
        let threeDSNavigationBarExists = expectation(for: Expectation.exists, evaluatedWith: threeDSNavigationBar, handler: nil)
        wait(for: [threeDSNavigationBarExists], timeout: 15)
        
        let failChallengeRadioButton = app.children(matching: .window).element(boundBy: 0).scrollViews.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element(boundBy: 0).children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .button).element
        failChallengeRadioButton.tap()

        let submit3DSButton = app.buttons["Submit"]
        submit3DSButton.tap()
        
        let errorImage = app.images["x-circle"]
        let errorImageExists = expectation(for: Expectation.exists, evaluatedWith: errorImage, handler: nil)
        wait(for: [errorImageExists], timeout: 15)
    }
    
    func testCancel3DSChallenge() throws {
        let threeDSPayment = Base.paymentMethods.filter({ $0.alias == "3DS_PAYMENT_CARD" }).first!
        let card = Base.cards.filter({ $0.alias == "3DS_PAYMENT_CARD" }).first!
        try openCardForm(for: threeDSPayment)
        fillCardDataWithCard(card, for: threeDSPayment, tappingPayOnceEnabled: true)
        
        let threeDSNavigationBar = app.otherElements.otherElements.navigationBars["SECURE CHECKOUT"]
        let threeDSNavigationBarExists = expectation(for: Expectation.exists, evaluatedWith: threeDSNavigationBar, handler: nil)
        wait(for: [threeDSNavigationBarExists], timeout: 15)
        
        let cancel3DSButton = threeDSNavigationBar.buttons["Cancel"]
        cancel3DSButton.tap()
        
        let errorImage = app.images["x-circle"]
        let errorImageExists = expectation(for: Expectation.exists, evaluatedWith: errorImage, handler: nil)
        wait(for: [errorImageExists], timeout: 15)
    }
    
    
}

extension UniversalCheckout {
    
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

        if let amountExpectation = payment.expectations?.amount {
            let amountText = app.staticTexts[amountExpectation]
            XCTAssert(amountText.exists, "Amount '\(amountExpectation)' should exist")
        }

        let scrollView = app.scrollViews["primer_container_scroll_view"]
        if let surchargeExpectation = payment.expectations?.surcharge {
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
    
    func fillCardDataWithCard(_ card: Card,
                              for payment: Payment,
                              checkingSubmitButton: Bool = true,
                              tappingPayOnceEnabled: Bool = false) {
        
        let cardnumberTextField = app/*@START_MENU_TOKEN@*/.textFields["card_txt_fld"]/*[[".textFields[\"4242 4242 4242 4242\"]",".textFields[\"card_txt_fld\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let expiryTextField = app.textFields["expiry_txt_fld"]
        let cvcTextField = app.textFields["cvc_txt_fld"]
        let cardholderTextField = app.textFields["card_holder_txt_fld"]
        let postalCodeTextField = app.textFields["postal_code_txt_fld"]
        let submitButton = app.buttons["submit_btn"]

        if let submitButtonTexts = payment.expectations?.buttonTexts {
            for text in submitButtonTexts {
                let submitButtonText = submitButton.staticTexts[text]
                XCTAssert(submitButtonText.exists, "Submit button should have text '\(text)'")
            }
        }
        
        if checkingSubmitButton {
            XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        }

        cardnumberTextField.tap()
        cardnumberTextField.typeText(card.number)
        
        if checkingSubmitButton {
            XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        }
        
        if let expirationDateString = card.expirationDateString {
            expiryTextField.tap()
            expiryTextField.typeText(expirationDateString)
        }
        
        if checkingSubmitButton {
            XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
        }
        
        if let cvv = card.cvv {
            cvcTextField.tap()
            cvcTextField.typeText(cvv)
        }
                
        if let cardholderName = card.cardholderName {

            if checkingSubmitButton {
                XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
            }

            cardholderTextField.tap()
            cardholderTextField.typeText(cardholderName)
        }
        
        if let postalCode = card.postalCode {
            
            if checkingSubmitButton {
                XCTAssert(!submitButton.isEnabled, "Submit button should be disabled")
            }
            
            postalCodeTextField.tap()
            postalCodeTextField.typeText(postalCode)
        }
        
        if checkingSubmitButton {
            XCTAssert(submitButton.isEnabled, "Submit button should be enabled")
        }
        
        if tappingPayOnceEnabled {
            submitButton.tap()
        }
        
    }
}
