//
//  UniversalCheckout.swift
//  PrimerSDKExample_UITests
//
//  Created by Evangelos Pittas on 15/6/21.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

import XCTest

class UniversalCheckout: XCTestCase {
    
    let app = XCUIApplication()

    override func setUp() {
        super.setUp()
        app.launchArguments = ["UITesting"]
        app.launch()
    }

    override func tearDown() {
        super.tearDown()
    }

//    func testUniversalCheckout() throws {
//        try Base().testInitializeSDK()
//        
//        let universalCheckoutButton = app.buttons["universal_checkout_button"]
//        universalCheckoutButton.tap()
//
//        // Test that title is correct
//        let checkoutTitle = app.staticTexts["Choose payment method"]
//        let vaultTitle = app.staticTexts["Add payment method"]
//        let exists = NSPredicate(format: "exists == true")
//        let doesNotExist = NSPredicate(format: "exists == false")
//        expectation(for: exists, evaluatedWith: checkoutTitle, handler: nil)
//        expectation(for: doesNotExist, evaluatedWith: vaultTitle, handler: nil)
//        waitForExpectations(timeout: 15, handler: nil)
//        
//        // UI tests are a black box, we cannot access the actual amount from the code.
//        // Test against € 0.05 since we know that this is the configuration we pass.
//        // Test that the amount exists
//        let amountText = app.staticTexts["€1.00"]
//        XCTAssert(amountText.exists, "Amount '€1.00' should exist")
//        
//        let savedPaymentMethodTitle = app.staticTexts["SAVED PAYMENT METHOD"]
//        let seeAllButton = app.buttons["See All"]
//        let savedPaymentMethodView = app.buttons["saved_payment_method_button"]
//        
//        if savedPaymentMethodTitle.exists {
//            // If there's a saved payment method, test that the view and the 'see all' button exist.
//            XCTAssert(seeAllButton.exists, "'See All' button should exist")
//            XCTAssert(savedPaymentMethodView.exists, "Saved payment method view should not exist")
//        } else {
//            // If there isn't a saved payment method, test that the view and the 'see all' button do not exist.
//            XCTAssert(!seeAllButton.exists, "'See All' button should exist")
//            XCTAssert(!savedPaymentMethodView.exists, "Saved payment method view should not exist")
//        }
//        
//        // Test that the table with the payment methods exists
//        let paymentMethodsTableView = app.tables["payment_methods_table_view"]
//        XCTAssert(paymentMethodsTableView.exists, "Payment methods table view should exist")
//        
//        // Test that Apple Pay exists and is able to be tapped
//        let applePayCell = paymentMethodsTableView.cells.element(matching: .cell, identifier: "payment_method_table_view_apple_pay_cell")
//        XCTAssert(applePayCell.exists, "ApplePay cell should exist")
//        XCTAssert(applePayCell.isHittable, "ApplePay cell should be able to be tapped")
//        
//        // Test that Klarna exists and is able to be tapped
////        let klarnaCell = paymentMethodsTableView.cells.element(matching: .cell, identifier: "payment_method_table_view_klarna_cell")
////        XCTAssert(klarnaCell.exists, "Klarna cell should exist")
////        XCTAssert(klarnaCell.isHittable, "Klarna cell should be able to be tapped")
//
//        // Test that PayPal exists and is able to be tapped
//        let payPalCell = paymentMethodsTableView.cells.element(matching: .cell, identifier: "payment_method_table_view_paypal_cell")
//        XCTAssert(payPalCell.exists, "PayPal cell should exist")
//        XCTAssert(payPalCell.isHittable, "PayPal cell should be able to be tapped")
//
//        // Test that Direct Debit exists and is able to be tapped
////        let directDebitCell = paymentMethodsTableView.cells.element(matching: .cell, identifier: "payment_method_table_view_direct_debit_cell")
////        XCTAssert(directDebitCell.exists, "Direct Debit cell should exist")
////        XCTAssert(directDebitCell.isHittable, "Direct Debit cell should be able to be tapped")
//
//        // Test that Card cell exists and is able to be tapped
//        let cardCell = paymentMethodsTableView.cells.element(matching: .cell, identifier: "payment_method_table_view_card_cell")
//        XCTAssert(cardCell.exists, "Card cell should exist")
//        XCTAssert(cardCell.isHittable, "Card cell should be able to be tapped")
//    }

}
