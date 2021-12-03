//
//  ExternalPaymentMethods.swift
//  PrimerSDKExample_UITests
//
//  Created by Evangelos on 1/12/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest

class ExternalPaymentMethods: XCTestCase {
    
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
    
    override func setUpWithError() throws {
        continueAfterFailure = false
        XCUIApplication().launch()
    }

    override func tearDownWithError() throws {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }
    
    func testAdyenAlipay() throws {
        let pm = Base.paymentMethods.filter({ $0.id == "ADYEN_ALIPAY" }).first!
        try testPaymentMethod(pm)
    }
    
    func testAdyenGiropay() throws {
        let pm = Base.paymentMethods.filter({ $0.id == "ADYEN_GIROPAY" }).first!
        try testPaymentMethod(pm)
    }
    
    func testAdyenMobilePay() throws {
        let pm = Base.paymentMethods.filter({ $0.id == "ADYEN_MOBILEPAY" }).first!
        try testPaymentMethod(pm)
    }
    
    func testPayNLBancontact() throws {
        let pm = Base.paymentMethods.filter({ $0.id == "PAY_NL_BANCONTACT" }).first!
        try testPaymentMethod(pm)
    }
    
    func testRec() throws {
        
        
        let app = XCUIApplication()
        app/*@START_MENU_TOKEN@*/.staticTexts["Universal Checkout"]/*[[".buttons[\"Universal Checkout\"].staticTexts[\"Universal Checkout\"]",".buttons[\"universal_checkout_button\"].staticTexts[\"Universal Checkout\"]",".staticTexts[\"Universal Checkout\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        let primerContainerScrollViewScrollView = app.scrollViews["primer_container_scroll_view"]
        primerContainerScrollViewScrollView.children(matching: .other).element(boundBy: 0).children(matching: .other).element/*@START_MENU_TOKEN@*/.swipeRight()/*[[".swipeUp()",".swipeRight()"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        primerContainerScrollViewScrollView.otherElements/*@START_MENU_TOKEN@*/.buttons["APPLE_PAY"]/*[[".otherElements[\"apple_pay_surcharge_group_view\"]",".buttons[\"apple pay logo\"]",".buttons[\"APPLE_PAY\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        let applePayStaticText = app.staticTexts["Apple Pay"]
        applePayStaticText.tap()
        applePayStaticText.tap()
        app.windows.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 1).children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element.children(matching: .other).element(boundBy: 0).tap()
        
        let elementsQuery = app.scrollViews.otherElements
        elementsQuery.buttons["Simulated Card - AmEx, ‪•••• 1234‬"].tap()
        app.tables.cells["Simulated Card - Visa, ‪•••• 1234‬"].children(matching: .other).element(boundBy: 0).children(matching: .other).element.tap()
        app.buttons["Pay Total, €2.19"].tap()
        elementsQuery.staticTexts["Total, €2.19"].tap()

                
                
    }
    
    func testPresentApplePay() throws {
        let pm = Base.paymentMethods.filter({ $0.id == "APPLE_PAY" }).first!
        
        try base.testInitialize(
            env: pm.environment.rawValue,
            customerId: nil,
            phoneNumber: nil,
            countryCode: pm.countryCode,
            currency: pm.currency,
            amount: pm.amount,
            performPayment: true)

        try base.openUniversalCheckout()

        if let amountExpectation = pm.expecations?.amount {
            let amountText = app.staticTexts[amountExpectation]
            XCTAssert(amountText.exists, "Amount '\(amountExpectation)' should exist")
        }
        
        let scrollView = app.scrollViews["primer_container_scroll_view"]
        if let surchargeExpectation = pm.expecations?.surcharge {
            Base.validateSurcharge(surchargeExpectation, forPaymentMethod: pm.id)
        }
        
        let applePayButton = scrollView.buttons[pm.id]
        applePayButton.tap()
    }
    
    func testPaymentMethod(_ pm: Payment) throws {
        try Base().testInitialize(
            env: pm.environment.rawValue,
            customerId: nil,
            phoneNumber: nil,
            countryCode: pm.countryCode,
            currency: pm.currency,
            amount: pm.amount,
            performPayment: true)

        let universalCheckoutButton = app.buttons["universal_checkout_button"]
        universalCheckoutButton.tap()

        // Test that title is correct
        let checkoutTitle = app.staticTexts["Choose payment method"]
        let vaultTitle = app.staticTexts["Add payment method"]

        
        expectation(for: Expectation.exists, evaluatedWith: checkoutTitle, handler: nil)
        expectation(for: Expectation.doesNotExist, evaluatedWith: vaultTitle, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)

        if let amountExpectation = pm.expecations?.amount {
            let amountText = app.staticTexts[amountExpectation]
            XCTAssert(amountText.exists, "Amount '\(amountExpectation)' should exist")
        }
        
        let scrollView = app.scrollViews["primer_container_scroll_view"]
        if let surchargeExpectation = pm.expecations?.surcharge {
            Base.validateSurcharge(surchargeExpectation, forPaymentMethod: pm.id)
        }
        
        let paymentMethodButton = app.buttons[pm.id]
        
        if !paymentMethodButton.exists {
            var isHittable: Bool = false
            while !isHittable {
                scrollView.swipeUp()
                isHittable = paymentMethodButton.isHittable
            }
        }
        
        let adyenGiropayButton = scrollView.otherElements.buttons[pm.id]
        adyenGiropayButton.tap()
        
        let webViews = app.webViews
        if let webViewImageExpectation = pm.expecations?.webviewImage {
            let webViewGiroPayImage = webViews.images[webViewImageExpectation]
            let webViewGiroPayImageExists = expectation(for: Expectation.exists, evaluatedWith: webViewGiroPayImage, handler: nil)
            wait(for: [webViewGiroPayImageExists], timeout: 30)
        }
        
        if let webviewTexts = pm.expecations?.webviewTexts {
            var webviewTextsExpectations: [XCTestExpectation] = []
            for text in webviewTexts {
                let webViewText = webViews.staticTexts[text]
                let webViewTextExists = expectation(for: Expectation.exists, evaluatedWith: webViewText, handler: nil)
                webviewTextsExpectations.append(webViewTextExists)
                
            }
            
            wait(for: webviewTextsExpectations, timeout: 30)
        }
        
        let safariDoneButton = app.otherElements["TopBrowserBar"].buttons["Done"]
        safariDoneButton.tap()
        let canceledLabel = app.scrollViews["primer_container_scroll_view"].otherElements.staticTexts["User cancelled"]
        let canceledLabelExists = expectation(for: Expectation.exists, evaluatedWith: canceledLabel, handler: nil)
        wait(for: [canceledLabelExists], timeout: 3)
    }
    
    
//    func wait(forWebViewElement element: XCUIElementTypeQueryProvider, timeout: TimeInterval = 20) {
//        // xcode has bug, so we cannot directly access webViews XCUIElements
//        // as a workaround we can check debugDesciption and parse it, that works
//        let predicate = NSPredicate { obj, _ in
//            guard let el = obj as? XCUIElement else {
//                return false
//            }
//            // If element has firstMatch, than there will be description of that at the end
//            // If no match - it will be ended with "FirstMatch\n"
//            return !el.firstMatch.debugDescription.hasSuffix("First Match\n")
//        }
//
//        // we need to take .firstMatch, because we parse description for that
//        let e = XCTNSPredicateExpectation(predicate: predicate, object: element.firstMatch)
//        let result = XCTWaiter().wait(for: [ e ], timeout: timeout)
//        XCTAssert(result == .completed)
//    }
//
//    private func coordinate(forWebViewElement element: XCUIElement) -> XCUICoordinate? {
//        // wait for element to appear before searching
//        wait(forWebViewElement: element)
//
//        // parse description to find its frame
//        let descr = element.firstMatch.debugDescription
//        guard let rangeOpen = descr.range(of: "{{", options: [.backwards]),
//            let rangeClose = descr.range(of: "}}", options: [.backwards]) else {
//                return nil
//        }
//
//        let frameStr = String(descr[rangeOpen.lowerBound..<rangeClose.upperBound])
//        let rect = NSCoder.cgRect(for: frameStr)
//
//        // get the center of rect
//        let center = CGVector(dx: rect.midX, dy: rect.midY)
//        let coordinate = XCUIApplication().coordinate(withNormalizedOffset: .zero).withOffset(center)
//        return coordinate
//    }
//
//    func tap(onWebViewElement element: XCUIElement) {
//        // xcode has bug, so we cannot directly access webViews XCUIElements
//        // as workaround we can check debugDesciption, find frame and tap by coordinate
//        let coord = coordinate(forWebViewElement: element)
//        coord?.tap()
//    }
//
//    func exists(webViewElement element: XCUIElement) -> Bool {
//        return coordinate(forWebViewElement: element) != nil
//    }
//
//    func typeText(_ text: String, toWebViewField element: XCUIElement) {
//        // xcode has bug, so we cannot directly access webViews XCUIElements
//        // as workaround we can check debugDesciption, find frame, tap by coordinate,
//        // and then paste text there
//        guard let coordBeforeTap = coordinate(forWebViewElement: element) else {
//            XCTFail("no element \(element)")
//            return
//        }
//        // "typeText" doesn't work, so we paste text
//        // first tap to activate field
//        UIPasteboard.general.string = text
//        coordBeforeTap.tap()
//        // wait for keyboard to appear
//        wait(forWebViewElement: XCUIApplication().keyboards.firstMatch)
//        // after tap coordinate can change
//        guard let coordAfterTap = coordinate(forWebViewElement: element) else {
//            XCTFail("no element \(element)")
//            return
//        }
//        // tap one more time for "paste" menu
//        coordAfterTap.press(forDuration: 1)
////        wait(forElement: XCUIApplication().menuItems["Paste"])
////        wait(for: [XCUIApplication().menuItems["Paste"]], timeout: 10)
//
//        if XCUIApplication().menuItems["Select All"].exists {
//            // if there was a text - remove it, by pressing Select All and Cut
//            XCUIApplication().menuItems["Select All"].tap()
//            XCUIApplication().menuItems["Cut"].tap()
//            // close keyboard
//            XCUIApplication().toolbars.buttons["Done"].tap()
//            // call this method one more time
//            typeText(text, toWebViewField: element)
//            return
//        }
//
//        XCUIApplication().menuItems["Paste"].tap()
//        // close keyboard
//        XCUIApplication().toolbars.buttons["Done"].tap()
//    }

}
