//
//  Klarna.swift
//  PrimerSDKExample_UITests
//
//  Created by Evangelos Pittas on 16/6/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest

class Klarna: XCTestCase {
    
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        app.launchArguments = ["UITesting"]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testInitKlarna() throws {
        try Base().testInitializeSDK()

        app.buttons["vault_klarna_button"].tap()

        let exists = NSPredicate(format: "exists == 1")
        
        let webView = app.webViews["primer_webview"]
        expectation(for: exists, evaluatedWith: webView, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        
        let continueButton = app.webViews.buttons["Continue"]
        expectation(for: exists, evaluatedWith: continueButton, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)
    }

}
