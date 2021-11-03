//
//  Klarna.swift
//  PrimerSDKExample_UITests
//
//  Created by Evangelos Pittas on 16/6/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest

class ExternalPaymentMethodsTest: XCTestCase {
    
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
    
    func testInitPayNLIdeal() throws {
        try Base().testInitialize(
            env: "sandbox",
            customerId: "customer_id",
            phoneNumber: nil,
            countryCode: "NL",
            currency: "EUR",
            amount: nil,
            performPayment: true)
        
        let exists = NSPredicate(format: "exists == 1")
        let universalCheckoutButton = app.buttons["universal_checkout_button"]
        let expectation1 = expectation(for: exists, evaluatedWith: universalCheckoutButton, handler: nil)
        wait(for: [expectation1], timeout: 15.0)
        universalCheckoutButton.tap()
        
        let iDealButton = app.scrollViews.otherElements.buttons["iDeal logo"]
        let expectation2 = expectation(for: exists, evaluatedWith: iDealButton, handler: nil)
        wait(for: [expectation2], timeout: 15.0)
        iDealButton.tap()
        
        let urlElement = app/*@START_MENU_TOKEN@*/.otherElements["URL"]/*[[".otherElements[\"async_payment_method_view_controller\"]",".otherElements[\"BrowserView?WebViewProcessID=20310\"]",".otherElements[\"TopBrowserBar\"]",".buttons[\"Address\"]",".otherElements[\"Address\"]",".otherElements[\"URL\"]",".buttons[\"URL\"]"],[[[-1,5],[-1,4],[-1,6,4],[-1,3,4],[-1,2,3],[-1,1,2],[-1,0,1]],[[-1,5],[-1,4],[-1,6,4],[-1,3,4],[-1,2,3],[-1,1,2]],[[-1,5],[-1,4],[-1,6,4],[-1,3,4],[-1,2,3]],[[-1,5],[-1,4],[-1,6,4],[-1,3,4]],[[-1,5],[-1,4]]],[0]]@END_MENU_TOKEN@*/
        let expectation3 = expectation(for: exists, evaluatedWith: urlElement, handler: nil)
        wait(for: [expectation3], timeout: 60.0)
    }

}
