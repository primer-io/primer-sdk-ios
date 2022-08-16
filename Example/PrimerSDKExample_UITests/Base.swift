//
//  Base.swift
//  PrimerSDK_ExampleUITests
//
//  Created by Evangelos Pittas on 22/3/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest

enum Environment: String {
    case local, dev, sandbox, staging, production
}

struct Card {
    let alias: String
    let number: String
    let expirationDateString: String?
    let cvv: String?
    let cardholderName: String?
    let postalCode: String?
}

struct Payment {
    var alias: String?
    var id: String
    let environment: Environment
    let currency: String
    let countryCode: String
    let amount: String?
    let expectations: Expectations?
    
    init(alias: String? = nil,
         id: String,
         environment: Environment,
         currency: String,
         countryCode: String,
         amount: String? = nil,
         expectations: Expectations? = nil) {
        self.id = id
        self.alias = alias ?? id
        self.environment = environment
        self.currency = currency
        self.countryCode = countryCode
        self.amount = amount
        self.expectations = expectations
    }
    
    struct Expectations {
        let amount: String?
        let surcharge: String?
        let webviewImage: String?
        let webviewTexts: [String]?
        let buttonTexts: [String]?
        let resultScreenTexts: [String: String]?
    }
}

class Expectation {
    static var exists: NSPredicate = NSPredicate(format: "exists == true")
    static var doesNotExist = NSPredicate(format: "exists == false")
    static var isHittable = NSPredicate(format: "isHittable == 1")
}

class Base: XCTestCase {
    
    static var cards: [Card] = [
        Card(alias: "VISA_PAYMENT_CARD",
             number: "4242424242424242",
             expirationDateString: "0225",
             cvv: "123",
             cardholderName: "John Smith",
             postalCode: nil),
        Card(alias: "3DS_PAYMENT_CARD",
             number: "9120000000000006",
             expirationDateString: "0225",
             cvv: "123",
             cardholderName: nil,
             postalCode: nil),
        Card(alias: "FAILING_CARD_PROCESSOR_3DS",
             number: "4000008400001629",
             expirationDateString: "0225",
             cvv: "123",
             cardholderName: "John Smith",
             postalCode: "EC1V"),
        Card(alias: "SUCCESS_CARD_PROCESSOR_3DS",
             number: "4000000000003220",
             expirationDateString: "0225",
             cvv: "123",
             cardholderName: "John Smith",
             postalCode: "EC1V"),

    ]
    
    static var paymentMethods: [Payment] = [
        Payment(
            id: "ADYEN_DOTPAY",
            environment: .sandbox,
            currency: "PLN",
            countryCode: "PL",
            amount: "288",
            expectations: Payment.Expectations(
                amount: "zł2.88",
                surcharge: nil,
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: nil,
                resultScreenTexts: [
                    "status": "SUCCESS"
                ]
            )
        ),
        Payment(
            id: "ADYEN_BLIK",
            environment: .sandbox,
            currency: "PLN",
            countryCode: "PL",
            amount: "288",
            expectations: Payment.Expectations(
                amount: "zł2.88",
                surcharge: nil,
                webviewImage: "blik",
                webviewTexts: nil,
                buttonTexts: nil,
                resultScreenTexts: nil
            )
        ),
        Payment(
            id: "ADYEN_GIROPAY",
            environment: .sandbox,
            currency: "EUR",
            countryCode: "DE",
            amount: "100",
            expectations: Payment.Expectations(
                amount: "€1.00",
                surcharge: "+€0.79",
                webviewImage: "giropay",
                webviewTexts: nil,
                buttonTexts: nil,
                resultScreenTexts: [
                    "status": "SUCCESS"
                ]
            )
        ),
        Payment(
            id: "ADYEN_IDEAL",
            environment: .sandbox,
            currency: "EUR",
            countryCode: "NL",
            amount: "10100",
            expectations: Payment.Expectations(
                amount: "€101.00",
                surcharge: "+€0.69",
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: nil,
                resultScreenTexts: [
                    "status": "SUCCESS"
                ]
            )
        ),
        Payment(
            id: "ADYEN_MOBILEPAY",
            environment: .sandbox,
            currency: "DKK",
            countryCode: "DK",
            amount: "100",
            expectations: Payment.Expectations(
                amount: "kr.1.00",
                surcharge: nil,
                webviewImage: "mobilepay-logo",
                webviewTexts: nil,
                buttonTexts: nil,
                resultScreenTexts: [
                    "status": "PENDING",
                    "actions": "USE_PRIMER_SDK",
                    "amount": "kr.1.00"
                ]
            )
        ),
        Payment(
            id: "PAY_NL_BANCONTACT",
            environment: .sandbox,
            currency: "EUR",
            countryCode: "BE",
            amount: "100",
            expectations: Payment.Expectations(
                amount: "€1.00",
                surcharge: nil,
                webviewImage: nil,
                webviewTexts: ["john@primer.io", "€ 1,00"],
                buttonTexts: nil,
                resultScreenTexts: nil
            )
        ),
        Payment(
            id: "ADYEN_ALIPAY",
            environment: .sandbox,
            currency: "CNY",
            countryCode: "CN",
            amount: "100",
            expectations: Payment.Expectations(
                amount: "CNY 1.00",
                surcharge: nil,
                webviewImage: nil,
                webviewTexts: ["1.如果未安装支付宝APP，请先"],
                buttonTexts: nil,
                resultScreenTexts: [
                    "status": "PENDING",
                    "actions": "USE_PRIMER_SDK",
                    "amount": "CNY 1.00"
                ]
            )
        ),
        Payment(
            id: "APPLE_PAY",
            environment: .sandbox,
            currency: "EUR",
            countryCode: "FR",
            amount: "100",
            expectations: Payment.Expectations(
                amount: "€1.00",
                surcharge: "+€0.19",
                webviewImage: nil,
                webviewTexts: ["Primer API Ltd", "€ 1,19"],
                buttonTexts: nil,
                resultScreenTexts: [
                    "status": "PENDING",
                    "amount": "EUR 1.19"
                ]
            )
        ),
        Payment(
            id: "PAYPAL",
            environment: .sandbox,
            currency: "GBP",
            countryCode: "GB",
            amount: "1000",
            expectations: Payment.Expectations(
                amount: "£10.00",
                surcharge: "+£0.49",
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: nil,
                resultScreenTexts: [
                    "status": "SUCCESS"
                ]
            )
        ),
        Payment(
            id: "PAYMENT_CARD",
            environment: .sandbox,
            currency: "GBP",
            countryCode: "GB",
            amount: "100",
            expectations: Payment.Expectations(
                amount: "£1.00",
                surcharge: "Additional fee may apply",
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: ["Pay £1.00"],
                resultScreenTexts: [
                    "status": "SUCCESS"
                ]
            )
        ),
        Payment(
            alias: "3DS_PAYMENT_CARD",
            id: "PAYMENT_CARD",
            environment: .sandbox,
            currency: "EUR",
            countryCode: "FR",
            amount: "10500",
            expectations: Payment.Expectations(
                amount: "€105.00",
                surcharge: "Additional fee may apply",
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: ["Pay €105.00"],
                resultScreenTexts: nil
            )
        ),
        Payment(
            alias: "PRIMER_TEST_KLARNA_AUTHORIZED",
            id: "PRIMER_TEST_KLARNA",
            environment: .staging,
            currency: "EUR",
            countryCode: "FR",
            amount: "1050",
            expectations: Payment.Expectations(
                amount: "€10.50",
                surcharge: nil,
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: ["Pay €10.50"],
                resultScreenTexts: [
                    "status": "SUCCESS"
                ]
            )
        ),
        Payment(
            alias: "PRIMER_TEST_PAYPAL_DECLINED",
            id: "PRIMER_TEST_PAYPAL",
            environment: .staging,
            currency: "EUR",
            countryCode: "DE",
            amount: "1050",
            expectations: Payment.Expectations(
                amount: "€10.50",
                surcharge: nil,
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: ["Pay €10.50"],
                resultScreenTexts: nil
            )
        ),
        Payment(
            alias: "PRIMER_TEST_SOFORT_FAILED",
            id: "PRIMER_TEST_SOFORT",
            environment: .staging,
            currency: "EUR",
            countryCode: "IT",
            amount: "1050",
            expectations: Payment.Expectations(
                amount: "€10.50",
                surcharge: nil,
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: ["Pay €10.50"],
                resultScreenTexts: nil
            )
        ),
        Payment(
            alias: "PAYMENT_CARD_WITH_PROCESSOR_3DS_SUCCESS",
            id: "PAYMENT_CARD",
            environment: .staging,
            currency: "GBP",
            countryCode: "GB",
            amount: "10011",
            expectations: Payment.Expectations(
                amount: "£100.11",
                surcharge: "Additional fee may apply",
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: ["Pay £100.11"],
                resultScreenTexts: [
                    "status": "SUCCESS"
                ]
            )
        ),
        Payment(
            alias: "PAYMENT_CARD_WITH_PROCESSOR_3DS_FAIL",
            id: "PAYMENT_CARD",
            environment: .staging,
            currency: "GBP",
            countryCode: "GB",
            amount: "10011",
            expectations: Payment.Expectations(
                amount: "£100.11",
                surcharge: "Additional fee may apply",
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: ["Pay £100.11"],
                resultScreenTexts: [
                    "status": "FAILED"
                ]
            )
        )
    ]
    
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        app.launchArguments = ["UITesting"]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    func testInitializeSDK() throws {
        let initSDKButton = app.buttons["initialize_primer_sdk"]
        initSDKButton.tap()
    }
    
    func testInitialize(
        env: String,
        customerId: String?,
        phoneNumber: String?,
        countryCode: String?,
        currency: String?,
        amount: String?,
        performPayment: Bool
    ) throws {
        let envSegmentedControl = app.segmentedControls["env_control"]
        
        if env.lowercased() == "dev" {
            let devEnv = envSegmentedControl.buttons["Dev"]
            devEnv.tap()
        } else if env.lowercased() == "sandbox" {
            let sandboxEnv = envSegmentedControl.buttons["Sandbox"]
            sandboxEnv.tap()
        } else if env.lowercased() == "staging" {
            let stagingEnv = envSegmentedControl.buttons["Staging"]
            stagingEnv.tap()
        } else if env.lowercased() == "production" {
            let prodcutionEnv = envSegmentedControl.buttons["Production"]
            prodcutionEnv.tap()
        }
        
        if let customerId = customerId {
            let customerIdTextField = app.textFields["customer_id_txt_field"]
            customerIdTextField.tap()
            customerIdTextField.clearText()
            customerIdTextField.typeText(customerId)
        }

        if let phoneNumber = phoneNumber {
            let phoneNumberTextField = app.textFields["phone_number_txt_field"]
            phoneNumberTextField.tap()
            phoneNumberTextField.clearText()
            phoneNumberTextField.typeText(phoneNumber)
        }
        
        if let countryCode = countryCode {
            let countryCodeTextField = app.textFields["country_code_txt_field"]
            countryCodeTextField.tap()
            app.pickerWheels.element.adjust(toPickerWheelValue: countryCode)
        }
        
        if let currency = currency {
            let currencyTextField = app.textFields["currency_txt_field"]
            currencyTextField.tap()
            app.pickerWheels.element.adjust(toPickerWheelValue: currency)
        }
        
        if let amount = amount {
            let amountTextField = app.textFields["amount_txt_field"]
            amountTextField.tap()
            amountTextField.clearText()
            amountTextField.typeText(amount)
        }

        let performPaymentSwitch = app.switches["perform_payment_switch"]
        if performPaymentSwitch.isOn! && !performPayment {
            performPaymentSwitch.tap()
        } else if !performPaymentSwitch.isOn! && performPayment {
            performPaymentSwitch.tap()
        }
        
        let appSettingsBackgroundView = app.otherElements["app_settings_background_view"]
        appSettingsBackgroundView.tap()
        
        let initSDKButton = app.buttons["initialize_primer_sdk"]
        
        if initSDKButton.waitForExistence(timeout: 5) {
            initSDKButton.tap()
        } else {
            XCTAssert(true, "Failed")
        }
    }
    
    func testViewTap() {
        
        let app = XCUIApplication()
        app.windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).tap()
        app/*@START_MENU_TOKEN@*/.textFields["amount_txt_field"]/*[[".textFields[\"In minor units (type 100 for 1.00)\"]",".textFields[\"amount_txt_field\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.children(matching: .window).element(boundBy: 0).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.tap()
                        
    }
    
    func openUniversalCheckout() throws {
        let universalCheckoutButton = app.buttons["universal_checkout_button"]
        universalCheckoutButton.tap()
        
        // Test that title is correct
        let checkoutTitle = app.staticTexts["Choose payment method"]
        let vaultTitle = app.staticTexts["AVAILABLE PAYMENT METHODS"]
        let exists = NSPredicate(format: "exists == true")
        let doesNotExist = NSPredicate(format: "exists == false")
        expectation(for: exists, evaluatedWith: checkoutTitle, handler: nil)
        expectation(for: doesNotExist, evaluatedWith: vaultTitle, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)
    }
    
    func openVaultManager() throws {
        let vaultButton = app.buttons["vault_button"]
        vaultButton.tap()

        // Test that title is correct
        let vaultTitle = app.staticTexts["Add payment method"]
        let checkoutTitle = app.staticTexts["Choose payment method"]
        expectation(for: Expectation.doesNotExist, evaluatedWith: checkoutTitle, handler: nil)
        expectation(for: Expectation.exists, evaluatedWith: vaultTitle, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
    }
    
    static func validateSurcharge(_ surcharge: String, forPaymentMethod paymentMethodId: String) {
        let app = XCUIApplication()
        let scrollView = app.scrollViews["primer_container_scroll_view"]
        let surchargeGroupViewId = paymentMethodId == "PAYMENT_CARD" ? "additional_fees_surcharge_group_view" : "\(paymentMethodId.lowercased())_surcharge_group_view"
        let paymentMethodSurcharge = scrollView.otherElements[surchargeGroupViewId].staticTexts[surcharge]
        XCTAssert(paymentMethodSurcharge.exists, "\(paymentMethodId) should have '\(surcharge)' surcharge")
    }
    
    func dismissSDK() throws {
        let scrollView = app.scrollViews["primer_container_scroll_view"]
        scrollView.swipeDown()
        let expectation = expectation(for: Expectation.doesNotExist, evaluatedWith: scrollView, handler: nil)
        wait(for: [expectation], timeout: 3.0)
    }
    
    func failViewExists() throws {
        let failImage = app.images["x-circle"]
        let failImageExists = expectation(for: Expectation.exists, evaluatedWith: failImage, handler: nil)
        wait(for: [failImageExists], timeout: 30)
    }
    
    func successViewExists() throws {
        let successImage = app.images["check-circle"]
        let successImageExists = expectation(for: Expectation.exists, evaluatedWith: successImage, handler: nil)
        wait(for: [successImageExists], timeout: 30)
    }
    
    func resultScreenExpectations(for payment: Payment) throws {
        if let resultScreenTextExpectations = payment.expectations?.resultScreenTexts {
            var expectations: [XCTestExpectation] = []
            
            if let status = resultScreenTextExpectations["status"] {
                let statusText = app.staticTexts[status]
                let statusTextExists = expectation(for: Expectation.exists, evaluatedWith: statusText, handler: nil)
                expectations.append(statusTextExists)
            }
            
            if let actions = resultScreenTextExpectations["actions"] {
                let actionsText = app.staticTexts[actions]
                let actionsTextExists = expectation(for: Expectation.exists, evaluatedWith: actionsText, handler: nil)
                expectations.append(actionsTextExists)
            }
            
            if let amount = resultScreenTextExpectations["amount"] {
                let amountText = app.staticTexts[amount]
                let amountTextExists = expectation(for: Expectation.exists, evaluatedWith: amountText, handler: nil)
                expectations.append(amountTextExists)
            }
            
            if !expectations.isEmpty {
                wait(for: expectations, timeout: 15)
            }
        }
    }
    
    func setMetadataTextFieldValue(_ string: String) {
        let metadataTextField = app.textFields["metadata_test_case_txt_field"]
        guard metadataTextField.exists else { return }
        metadataTextField.tap()
        metadataTextField.clearText()
        metadataTextField.typeText(string)
    }
    
    func setAPIKeyTextFieldValue(_ string: String) {
        let apiKeyFieldAccount = app.textFields["api_key_txt_field"]
        guard apiKeyFieldAccount.exists else { return }
        apiKeyFieldAccount.tap()
        apiKeyFieldAccount.clearText()
        apiKeyFieldAccount.typeText(string)
    }

    func testPayment(_ payment: Payment, cancelPayment: Bool = true) throws {
        
        try testInitialize(
            env: payment.environment.rawValue,
            customerId: nil,
            phoneNumber: nil,
            countryCode: payment.countryCode,
            currency: payment.currency,
            amount: payment.amount,
            performPayment: true)

        let universalCheckoutButton = app.buttons["universal_checkout_button"]
        universalCheckoutButton.tap()

        // Test that title is correct
        let checkoutTitle = app.staticTexts["Choose payment method"]
        let vaultTitle = app.staticTexts["Add payment method"]

        expectation(for: Expectation.exists, evaluatedWith: checkoutTitle, handler: nil)
        expectation(for: Expectation.doesNotExist, evaluatedWith: vaultTitle, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)

        if let amountExpectation = payment.expectations?.amount {
            let amountText = app.staticTexts[amountExpectation]
            XCTAssert(amountText.exists, "Amount '\(amountExpectation)' should exist")
        }
        
        let scrollView = app.scrollViews["primer_container_scroll_view"]
        if let surchargeExpectation = payment.expectations?.surcharge {
            Base.validateSurcharge(surchargeExpectation, forPaymentMethod: payment.id)
        }
        
        let paymentMethodButton = app.buttons[payment.id]
        if scrollView.scrollRevealingElement(paymentMethodButton) {
            paymentMethodButton.tap()
        }

        let webViews = app.webViews
        if let webViewImageExpectation = payment.expectations?.webviewImage {
            let webViewPaymentImage = webViews.images[webViewImageExpectation]
            let webViewPaymentImageExists = expectation(for: Expectation.exists, evaluatedWith: webViewPaymentImage, handler: nil)
            wait(for: [webViewPaymentImageExists], timeout: 30)
        }
        
        if let webviewTexts = payment.expectations?.webviewTexts {
            var webviewTextsExpectations: [XCTestExpectation] = []
            for text in webviewTexts {
                let webViewText = webViews.staticTexts[text]
                let webViewTextExists = expectation(for: Expectation.exists, evaluatedWith: webViewText, handler: nil)
                webviewTextsExpectations.append(webViewTextExists)
                
            }
            
            wait(for: webviewTextsExpectations, timeout: 30)
        }
        
        if cancelPayment {
            let safariDoneButton = app.otherElements["TopBrowserBar"].buttons["Done"]
            safariDoneButton.tap()
            
            scrollView.swipeDown()
            
            if let resultScreenTextExpectations = payment.expectations?.resultScreenTexts {
                var expectations: [XCTestExpectation] = []
                
                if let status = resultScreenTextExpectations["status"] {
                    let statusText = app.staticTexts[status]
                    let statusTextExists = expectation(for: Expectation.exists, evaluatedWith: statusText, handler: nil)
                    expectations.append(statusTextExists)
                }
                
                if let actions = resultScreenTextExpectations["actions"] {
                    let actionsText = app.staticTexts[actions]
                    let actionsTextExists = expectation(for: Expectation.exists, evaluatedWith: actionsText, handler: nil)
                    expectations.append(actionsTextExists)
                }
                
                if let amount = resultScreenTextExpectations["amount"] {
                    let amountText = app.staticTexts[amount]
                    let amountTextExists = expectation(for: Expectation.exists, evaluatedWith: amountText, handler: nil)
                    expectations.append(amountTextExists)
                }
                
                if !expectations.isEmpty {
                    wait(for: expectations, timeout: 3)
                }
            }
        }
    }
}

extension XCUIElement {
    
    func clearText() {
        guard let stringValue = self.value as? String else {
            return
        }

        var deleteString = String()
        for _ in stringValue {
            deleteString += XCUIKeyboardKey.delete.rawValue
        }
        typeText(deleteString)
    }
    
    var isOn: Bool? {
            return (self.value as? String).map { $0 == "1" }
        }
    
//    func tap(at index: UInt) {
//        guard buttons.count > 0 else { return }
//        var segments = (0..<buttons.count).map { buttons.element(boundBy: $0) }
//        try? segments.sort { $0.0.frame.origin.x < $0.1.frame.origin.x }
//        segments[Int(index)].tap()
//    }
    
}
