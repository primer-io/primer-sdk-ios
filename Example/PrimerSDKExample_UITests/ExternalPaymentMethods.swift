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
