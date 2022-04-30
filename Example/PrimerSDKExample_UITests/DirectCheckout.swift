//
//  UniversalCheckout.swift
//  PrimerSDKExample_UITests
//
//  Created by Evangelos Pittas on 15/6/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest

class DirectCheckout: XCTestCase {
    
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
    
    func testPresentApplePay() throws {
        let payment = Base.paymentMethods.filter({ $0.id == "APPLE_PAY" }).first!
        
        try base.testInitialize(
            env: payment.environment.rawValue,
            customerId: nil,
            phoneNumber: nil,
            countryCode: payment.countryCode,
            currency: payment.currency,
            amount: payment.amount,
            performPayment: true)
        
        let applePayButton = app.buttons["apple_pay_checkout_button"]
        applePayButton.tap()
        
        let applePay = XCUIApplication(bundleIdentifier: "com.apple.PassbookUIService")
        let applePayExists = expectation(for: Expectation.exists, evaluatedWith: applePay, handler: nil)
        wait(for: [applePayExists], timeout: 15.0)
        _ = applePay.wait(for: .runningForeground, timeout: 10)

        applePay.buttons.matching(NSPredicate(format: "label == 'Pay Total, €1.19'")).firstMatch.tap()
    }


    func testPresentPayPal() throws {
        let payment = Base.paymentMethods.filter({ $0.id == "PAYPAL" }).first!
        try base.testInitialize(
            env: payment.environment.rawValue,
            customerId: nil,
            phoneNumber: nil,
            countryCode: payment.countryCode,
            currency: payment.currency,
            amount: payment.amount,
            performPayment: true)
        
        let payPalButton = app.buttons["add_paypal_button"]
        payPalButton.tap()
        
        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        let alert = springboard.alerts.firstMatch;
        let alertExists = expectation(for: Expectation.exists, evaluatedWith: alert, handler: nil)
        
        wait(for: [alertExists], timeout: 15)
        
        let alertContinueButton = alert.buttons["Continue"]
        alertContinueButton.tap()
    }
    
    
}
