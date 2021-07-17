//
//  ThreeDS.swift
//  PrimerSDKExample_UITests
//
//  Created by Evangelos Pittas on 17/7/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest

class ThreeDS: XCTestCase {
    
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        app.launchArguments = ["UITesting"]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

    func initializeSDK() throws {
        let initSDKButton = app.buttons["initialize_primer_sdk"]
        initSDKButton.tap()
    }
    
    // Test below only works the 1st time the card is added, then it just succeeds.
    func testThreeDSChallenge() throws {
        try initializeSDK()
        
        let addCardButton = app.buttons["add_card_button"]
        addCardButton.tap()
        
        let cardField = app.textFields["cardField"]
        cardField.tap()
        cardField.typeText("9120000000000006")
        
        let expiryField = app.textFields["expiryField"]
        expiryField.tap()
        expiryField.typeText("0222")
        
        let cvcField = app.textFields["cvcField"]
        cvcField.tap()
        cvcField.typeText("123")
        
        let nameField = app.textFields["nameField"]
        nameField.tap()
        nameField.typeText("John Doe")
        
        let submitButton = app.buttons["submitButton"]
        submitButton.tap()
        
        let secureCheckoutNavigationBar = app.navigationBars["SECURE CHECKOUT"]
        let exists = NSPredicate(format: "exists == 1")
        expectation(for: exists, evaluatedWith: secureCheckoutNavigationBar, handler: nil)
        waitForExpectations(timeout: 60, handler: nil)
        
        //    let elementsQuery = app.scrollViews.otherElements
        //    elementsQuery.staticTexts["Select outcome"].tap()
        //    elementsQuery.staticTexts["Please select the challenge outcome, to determine if you want to retry, pass or fail the challenge."].tap()
        //
        //    let secureCheckoutNavigationBar = app.navigationBars["SECURE CHECKOUT"]
        //    secureCheckoutNavigationBar.staticTexts["SECURE CHECKOUT"].tap()
        //    verticalScrollBar1PageScrollView.tap()
        //    secureCheckoutNavigationBar.buttons["Cancel"].tap()
    }
    
}
