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
        let presentWalletButton = app.buttons["walletButton"]
        XCTAssert(presentWalletButton.exists)
        presentWalletButton.tap()
        
        let addCard = app/*@START_MENU_TOKEN@*/.staticTexts["Add Card"]/*[[".buttons[\"Add Card\"].staticTexts[\"Add Card\"]",".staticTexts[\"Add Card\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        XCTAssert(addCard.exists)
    }
    
}
