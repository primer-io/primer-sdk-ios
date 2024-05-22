//
//  CountryCodeTests.swift
//  
//
//  Created by Jack Newcombe on 13/05/2024.
//

import XCTest
@testable import PrimerSDK

final class ApplePayOrderItemTests: XCTestCase {

    func testInitWithErrors() {
        do {
            _ = try ApplePayOrderItem(name: "",
                                      unitAmount: nil,
                                      quantity: 1,
                                      discountAmount: nil,
                                      taxAmount: 1,
                                      isPending: false)
            XCTFail("Error should be thrown for nil unitAmount when not pending")
        } catch let error {
            XCTAssertTrue(error.localizedDescription.contains("Message: amount cannot be null for non-pending items"))
        }

        do {
            _ = try ApplePayOrderItem(name: "",
                                      unitAmount: 1,
                                      quantity: 1,
                                      discountAmount: nil,
                                      taxAmount: 1,
                                      isPending: true)
            XCTFail("Error should be thrown for non-nil unitAmount when pending")
        } catch let error {
            XCTAssertTrue(error.localizedDescription.contains("Message: amount should be null for pending items"))
        }
    }
}
