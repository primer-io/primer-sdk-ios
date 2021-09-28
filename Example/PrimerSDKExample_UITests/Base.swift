//
//  Base.swift
//  PrimerSDK_ExampleUITests
//
//  Created by Evangelos Pittas on 22/3/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest

class Base: XCTestCase {
    
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
            countryCodeTextField.clearText()
            countryCodeTextField.typeText(countryCode)
        }
        
        if let currency = currency {
            let currencyTextField = app.textFields["currency_txt_field"]
            currencyTextField.tap()
            currencyTextField.clearText()
            currencyTextField.typeText(currency)
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
