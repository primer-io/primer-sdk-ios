//
//  ApplePayOrderItemTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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
