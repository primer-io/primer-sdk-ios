//
// Copyright (c) 2022 Primer API ltd
//
// Licensed under the MIT License 
//
// You may obtain a copy of the License at
// https://mit-license.org
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
        try Base().testInitialize(
            env: "sandbox",
            customerId: "customer_id",
            phoneNumber: nil,
            countryCode: "SE",
            currency: "SEK",
            amount: nil,
            performPayment: false)

        app.buttons["add_klarna_button"].tap()

        let exists = NSPredicate(format: "exists == 1")
        
        let webView = app.webViews["primer_webview"]
        expectation(for: exists, evaluatedWith: webView, handler: nil)
        waitForExpectations(timeout: 15, handler: nil)
        
        let continueButton = app.webViews.buttons["Continue"]
        expectation(for: exists, evaluatedWith: continueButton, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)
    }

}
