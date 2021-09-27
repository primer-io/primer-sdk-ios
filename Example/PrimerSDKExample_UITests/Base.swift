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

//    func testPresentWallet() throws {
//        let initSDKButton = app.buttons["initialize_primer_sdk"]
//        initSDKButton.tap()
//        
//        let addCardButton = app/*@START_MENU_TOKEN@*/.buttons["add_card_button"]/*[[".buttons[\"Add Card\"]",".buttons[\"add_card_button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
//        XCTAssert(addCardButton.exists)
//    }
//    
//    func testAddCard() throws {
//        try testPresentWallet()
//        
//        let addCardButton = app.buttons["add_card_button"]
//        addCardButton.tap()
//        
//        let nameField = app.textFields["nameField"]
//        nameField.tap()
//        nameField.typeText("John Doe")
//        
//        let cardField = app.textFields["cardField"]
//        cardField.tap()
//        cardField.typeText("4111111111111111")
//        
//        let expiryField = app.textFields["expiryField"]
//        expiryField.tap()
//        expiryField.typeText("0222")
//        
//        let cvcField = app.textFields["cvcField"]
//        cvcField.tap()
//        cvcField.typeText("123")
//        
//        let submitButton = app.buttons["submitButton"]
//        submitButton.tap()
//
//        let successLabel = app.staticTexts["Success!"]
//        XCTAssert(successLabel.exists)
//        
//        app.navigationBars.buttons["Done"].tap()
//    }
//    
//    func testDeleteCard() throws {
//        try testAddCard()
//
//        app/*@START_MENU_TOKEN@*/.buttons["open_wallet_button"]/*[[".buttons[\"Open Wallet\"]",".buttons[\"open_wallet_button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
//        app.buttons["See All"].tap()
//        
//        app.navigationBars["Saved payment methods"].buttons["Edit"].tap()
//        app.tables.buttons.containing(.staticText, identifier:"•••• 1111").firstMatch.tap()
//        app.alerts["Confirmation"].scrollViews.otherElements.buttons["Delete"].tap()
//    }

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
