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
    
    func testSandbox() throws {
        app.buttons["Sandbox"].tap()
    }
    
    func testDev() throws {
        app.buttons["Dev"].tap()
    }
    
    func testStaging() throws {
        app/*@START_MENU_TOKEN@*/.buttons["Staging"]/*[[".segmentedControls.buttons[\"Staging\"]",".buttons[\"Staging\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
    }

}
