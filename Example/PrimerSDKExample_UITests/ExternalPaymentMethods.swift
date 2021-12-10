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
        try testPayment(pm)
    }
    
    func testAdyenGiropay() throws {
        let payment = Base.paymentMethods.filter({ $0.id == "ADYEN_GIROPAY" }).first!
        try testPayment(payment, cancelPayment: false)
        
        let safariWebView = app.otherElements.matching(NSPredicate(format: "identifier CONTAINS 'BrowserView?WebViewProcessID'"))
        
        let continueButton = app.webViews.firstMatch.buttons.firstMatch
        let continueButtonIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: continueButton, handler: nil)
        wait(for: [continueButtonIsHittable], timeout: 30)
        continueButton.tap()
        
        let scTextField = app.otherElements.containing(NSPredicate(format: "label == 'sc:'")).firstMatch.textFields.firstMatch
        let scTextFieldIsHittable = expectation(for: Expectation.isHittable, evaluatedWith: scTextField, handler: nil)
        wait(for: [scTextFieldIsHittable], timeout: 30)
        scTextField.tap()
        scTextField.typeText("10")
        
        let toolBarDoneButton = app.toolbars["Toolbar"].firstMatch.buttons["Done"].firstMatch
        toolBarDoneButton.tap()
        
        let extensionScTextField = app.otherElements.containing(NSPredicate(format: "label == 'extensionSc:'")).firstMatch.textFields.element(boundBy: 1)
        extensionScTextField.tap()
        extensionScTextField.typeText("4000")
        
        toolBarDoneButton.tap()
        safariWebView.webViews.firstMatch.pinch(withScale: 0.5, velocity: -0.5)
        
        let customerNameTextField = app.otherElements.containing(NSPredicate(format: "label == 'customerName1:'")).firstMatch.textFields.element(boundBy: 2)
        customerNameTextField.tap()
        customerNameTextField.typeText("John Smith")
        
        toolBarDoneButton.tap()
        safariWebView.webViews.firstMatch.pinch(withScale: 0.5, velocity: -0.5)
        
        let customerIbanTextField = app.otherElements.containing(NSPredicate(format: "label == 'customerIBAN:'")).firstMatch.textFields.element(boundBy: 3)
        customerIbanTextField.tap()
        customerIbanTextField.typeText("DE36444488881234567890")
        
        toolBarDoneButton.tap()
        safariWebView.webViews.firstMatch.pinch(withScale: 0.5, velocity: -0.5)
        
        let submitButton = app.buttons.matching(NSPredicate(format: "label == 'Absenden'")).firstMatch
        submitButton.tap()
        
        try base.testSuccessMessageExists()
        try base.testDismissSDK()
        try base.testResultScreenExpectations(for: payment)
    }
    
    func testAdyenMobilePay() throws {
        let pm = Base.paymentMethods.filter({ $0.id == "ADYEN_MOBILEPAY" }).first!
        try testPayment(pm)
    }
    
    func testPayNLBancontact() throws {
        let pm = Base.paymentMethods.filter({ $0.id == "PAY_NL_BANCONTACT" }).first!
        try testPayment(pm)
    }
    
    func testRec() throws {
        
        
        let app = XCUIApplication()
        app/*@START_MENU_TOKEN@*/.staticTexts["Initialize Primer SDK"]/*[[".buttons[\"Initialize Primer SDK\"].staticTexts[\"Initialize Primer SDK\"]",".buttons[\"initialize_primer_sdk\"].staticTexts[\"Initialize Primer SDK\"]",".staticTexts[\"Initialize Primer SDK\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.buttons["universal_checkout_button"]/*[[".buttons[\"Universal Checkout\"]",".buttons[\"universal_checkout_button\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        
        let primerContainerScrollViewScrollView = app.scrollViews["primer_container_scroll_view"]
        primerContainerScrollViewScrollView.otherElements/*@START_MENU_TOKEN@*/.buttons["ADYEN_GIROPAY"]/*[[".otherElements[\"adyen_giropay_surcharge_group_view\"]",".buttons[\"giropay logo\"]",".buttons[\"ADYEN_GIROPAY\"]"],[[[-1,2],[-1,1],[-1,0,1]],[[-1,2],[-1,1]]],[0]]@END_MENU_TOKEN@*/.tap()
        app/*@START_MENU_TOKEN@*/.otherElements["URL"]/*[[".otherElements[\"BrowserView?WebViewProcessID=46134\"]",".otherElements[\"TopBrowserBar\"]",".buttons[\"Address\"]",".otherElements[\"Address\"]",".otherElements[\"URL\"]",".buttons[\"URL\"]"],[[[-1,4],[-1,3],[-1,5,3],[-1,2,3],[-1,1,2],[-1,0,1]],[[-1,4],[-1,3],[-1,5,3],[-1,2,3],[-1,1,2]],[[-1,4],[-1,3],[-1,5,3],[-1,2,3]],[[-1,4],[-1,3]]],[0]]@END_MENU_TOKEN@*/.tap()
        primerContainerScrollViewScrollView.children(matching: .other).element(boundBy: 0).children(matching: .other).element.swipeDown()
        app.staticTexts["PENDING"].tap()
        app.staticTexts["USE_PRIMER_SDK"].tap()
        app.staticTexts["EUR 1.79"].tap()
                
        

                
                
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
    
    func testPayment(_ payment: Payment, cancelPayment: Bool = true) throws {
        try Base().testInitialize(
            env: payment.environment.rawValue,
            customerId: nil,
            phoneNumber: nil,
            countryCode: payment.countryCode,
            currency: payment.currency,
            amount: payment.amount,
            performPayment: true)

        let universalCheckoutButton = app.buttons["universal_checkout_button"]
        universalCheckoutButton.tap()

        // Test that title is correct
        let checkoutTitle = app.staticTexts["Choose payment method"]
        let vaultTitle = app.staticTexts["Add payment method"]

        
        expectation(for: Expectation.exists, evaluatedWith: checkoutTitle, handler: nil)
        expectation(for: Expectation.doesNotExist, evaluatedWith: vaultTitle, handler: nil)
        waitForExpectations(timeout: 30, handler: nil)

        if let amountExpectation = payment.expecations?.amount {
            let amountText = app.staticTexts[amountExpectation]
            XCTAssert(amountText.exists, "Amount '\(amountExpectation)' should exist")
        }
        
        let scrollView = app.scrollViews["primer_container_scroll_view"]
        if let surchargeExpectation = payment.expecations?.surcharge {
            Base.validateSurcharge(surchargeExpectation, forPaymentMethod: payment.id)
        }
        
        let paymentMethodButton = app.buttons[payment.id]
        
        if !paymentMethodButton.exists {
            var isHittable: Bool = false
            while !isHittable {
                scrollView.swipeUp()
                isHittable = paymentMethodButton.isHittable
            }
        }
        
        let adyenGiropayButton = scrollView.otherElements.buttons[payment.id]
        adyenGiropayButton.tap()
        
        let webViews = app.webViews
        if let webViewImageExpectation = payment.expecations?.webviewImage {
            let webViewGiroPayImage = webViews.images[webViewImageExpectation]
            let webViewGiroPayImageExists = expectation(for: Expectation.exists, evaluatedWith: webViewGiroPayImage, handler: nil)
            wait(for: [webViewGiroPayImageExists], timeout: 30)
        }
        
        if let webviewTexts = payment.expecations?.webviewTexts {
            var webviewTextsExpectations: [XCTestExpectation] = []
            for text in webviewTexts {
                let webViewText = webViews.staticTexts[text]
                let webViewTextExists = expectation(for: Expectation.exists, evaluatedWith: webViewText, handler: nil)
                webviewTextsExpectations.append(webViewTextExists)
                
            }
            
            wait(for: webviewTextsExpectations, timeout: 30)
        }
        
        if cancelPayment {
            let safariDoneButton = app.otherElements["TopBrowserBar"].buttons["Done"]
            safariDoneButton.tap()
            let canceledLabel = app.scrollViews["primer_container_scroll_view"].otherElements.staticTexts["User cancelled"]
            let canceledLabelExists = expectation(for: Expectation.exists, evaluatedWith: canceledLabel, handler: nil)
            wait(for: [canceledLabelExists], timeout: 3)
            
            scrollView.swipeDown()
            
            if let resultScreenTextExpectations = payment.expecations?.resultScreenTexts {
                var expectations: [XCTestExpectation] = []
                
                if let status = resultScreenTextExpectations["status"] as? String {
                    let statusText = app.staticTexts[status]
                    let statusTextExists = expectation(for: Expectation.exists, evaluatedWith: statusText, handler: nil)
                    expectations.append(statusTextExists)
                }
                
                if let actions = resultScreenTextExpectations["actions"] as? String {
                    let actionsText = app.staticTexts[actions]
                    let actionsTextExists = expectation(for: Expectation.exists, evaluatedWith: actionsText, handler: nil)
                    expectations.append(actionsTextExists)
                }
                
                if let amount = resultScreenTextExpectations["amount"] as? String {
                    let amountText = app.staticTexts[amount]
                    let amountTextExists = expectation(for: Expectation.exists, evaluatedWith: amountText, handler: nil)
                    expectations.append(amountTextExists)
                }
                
                if !expectations.isEmpty {
                    wait(for: expectations, timeout: 3)
                }
            }
        }
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
