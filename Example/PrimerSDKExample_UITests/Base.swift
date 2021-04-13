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

}
