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

    func testPresentWallet() throws {
        let initSDKButton = app.buttons["initialize_primer_sdk"]
        initSDKButton.tap()
        
        let addCardButton = app/*@START_MENU_TOKEN@*/.buttons["add_card_button"]/*[[".buttons[\"Add Card\"]",".buttons[\"add_card_button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        XCTAssert(addCardButton.exists)
    }
    
    func testAddCard() throws {
        try testPresentWallet()
        
        let addCardButton = app.buttons["add_card_button"]
        addCardButton.tap()
        
        let nameField = app.textFields["nameField"]
        nameField.tap()
        nameField.typeText("John Doe")
        
        let cardField = app.textFields["cardField"]
        cardField.tap()
        cardField.typeText("4111111111111111")
        
        let expiryField = app.textFields["expiryField"]
        expiryField.tap()
        expiryField.typeText("0222")
        
        let cvcField = app.textFields["cvcField"]
        cvcField.tap()
        cvcField.typeText("123")
        
        let submitButton = app.buttons["submitButton"]
        submitButton.tap()

        let successLabel = app.staticTexts["Success!"]
        XCTAssert(successLabel.exists)
        
        app.navigationBars.buttons["Done"].tap()
    }
    
    func testDeleteCard() throws {
        try testAddCard()

        app/*@START_MENU_TOKEN@*/.buttons["open_wallet_button"]/*[[".buttons[\"Open Wallet\"]",".buttons[\"open_wallet_button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app.buttons["See All"].tap()
        
        app.navigationBars["Saved payment methods"].buttons["Edit"].tap()
        app.tables.buttons.containing(.staticText, identifier:"•••• 1111").firstMatch.tap()
        app.alerts["Confirmation"].scrollViews.otherElements.buttons["Delete"].tap()
    }
    
    func testInitKlarna() throws {
        try testPresentWallet()
        
        app/*@START_MENU_TOKEN@*/.buttons["add_klarna_button"]/*[[".buttons[\"Add Klarna\"]",".buttons[\"add_klarna_button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        let klarnaBuyButton = app.webViews.webViews.webViews/*@START_MENU_TOKEN@*/.buttons["Buy"]/*[[".otherElements.matching(identifier: \"Complete your purchase\").buttons[\"Buy\"]",".buttons[\"Buy\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        let exists = NSPredicate(format: "exists == 1")
        
        expectation(for: exists, evaluatedWith: klarnaBuyButton, handler: nil)
        waitForExpectations(timeout: 10, handler: nil)
    }

}
