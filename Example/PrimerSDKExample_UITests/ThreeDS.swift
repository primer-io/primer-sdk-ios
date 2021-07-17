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
    
    func testAddCard() throws {
        try initializeSDK()
        
        let addCardButton = app.buttons["add_card_button"]
        addCardButton.tap()
        
        let cardField = app.textFields["cardField"]
        cardField.tap()
        cardField.typeText("9110040000000004")
        
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
    }
    
    func testRecord() throws {
                
    }

}
