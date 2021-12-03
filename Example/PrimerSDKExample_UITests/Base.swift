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

struct Payment {
    let id: String
    let environment: Environment
    let currency: String
    let countryCode: String
    let amount: String?
    let expecations: Expecations?
    
    struct Expecations {
        let amount: String?
        let surcharge: String?
        let webviewImage: String?
        let webviewTexts: [String]?
        let buttonTexts: [String]?
    }
}

class Expectation {
    static var exists: NSPredicate = NSPredicate(format: "exists == true")
    static var doesNotExist = NSPredicate(format: "exists == false")
}

class Base: XCTestCase {
    
    static var paymentMethods: [Payment] = [
        Payment(
            id: "ADYEN_GIROPAY",
            environment: .sandbox,
            currency: "EUR",
            countryCode: "DE",
            amount: "1.00",
            expecations: Payment.Expecations(
                amount: "€1.00",
                surcharge: "€0.29",
                webviewImage: "giropay",
                webviewTexts: nil,
                buttonTexts: nil
            )
        ),
        Payment(
            id: "ADYEN_MOBILEPAY",
            environment: .sandbox,
            currency: "DKK",
            countryCode: "DK",
            amount: "1.00",
            expecations: Payment.Expecations(
                amount: "DKK 1.00",
                surcharge: nil,
                webviewImage: "mobilepay-logo",
                webviewTexts: nil,
                buttonTexts: nil
            )
        ),
        Payment(
            id: "PAY_NL_BANCONTACT",
            environment: .sandbox,
            currency: "EUR",
            countryCode: "NL",
            amount: "1.00",
            expecations: Payment.Expecations(
                amount: "€1.00",
                surcharge: "€0.49",
                webviewImage: nil,
                webviewTexts: ["Primer API Ltd", "€ 1,49"],
                buttonTexts: nil
            )
        ),
        Payment(
            id: "ADYEN_ALIPAY",
            environment: .sandbox,
            currency: "CNY",
            countryCode: "CN",
            amount: "1.00",
            expecations: Payment.Expecations(
                amount: "CNY 1.00",
                surcharge: nil,
                webviewImage: nil,
                webviewTexts: ["1.如果未安装支付宝APP，请先"],
                buttonTexts: nil
            )
        ),
        Payment(
            id: "APPLE_PAY",
            environment: .sandbox,
            currency: "EUR",
            countryCode: "FR",
            amount: "1.00",
            expecations: Payment.Expecations(
                amount: "€1.00",
                surcharge: "€1.19",
                webviewImage: nil,
                webviewTexts: ["Primer API Ltd", "€ 1,49"],
                buttonTexts: nil
            )
        ),
        Payment(
            id: "PAYMENT_CARD",
            environment: .sandbox,
            currency: "GBP",
            countryCode: "GB",
            amount: "1.00",
            expecations: Payment.Expecations(
                amount: "£1.00",
                surcharge: "Additional fee may apply",
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: ["Pay £1.00"])),
        Payment(
            id: "3DS_PAYMENT_CARD",
            environment: .sandbox,
            currency: "RON",
            countryCode: "RO",
            amount: "1.00",
            expecations: Payment.Expecations(
                amount: "RON 1.00",
                surcharge: "Additional fee may apply",
                webviewImage: nil,
                webviewTexts: nil,
                buttonTexts: ["Pay RON 1.00"]))
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
        
        let initSDKButton = app.buttons["initialize_primer_sdk"]
        initSDKButton.tap()
    }
    
    func openUniversalCheckout() throws {
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
