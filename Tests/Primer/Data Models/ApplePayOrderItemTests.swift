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
            if case let PrimerError.invalidValue(key, value, userInfo, _) = error {
                XCTAssertEqual(key, "amount")
                XCTAssertNil(value)
                XCTAssertEqual(userInfo?["message"], ("amount cannot be null for non-pending items"))
            } else {
                XCTFail("Expected invalidValue error")
            }
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
            if case let PrimerError.invalidValue(key, value, userInfo, _) = error {
                XCTAssertEqual(key, "amount")
                XCTAssertEqual(value as? Int, 1)
                XCTAssertEqual(userInfo?["message"], ("amount should be null for pending items"))
            } else {
                XCTFail("Expected invalidValue error")
            }
        }
    }
}
