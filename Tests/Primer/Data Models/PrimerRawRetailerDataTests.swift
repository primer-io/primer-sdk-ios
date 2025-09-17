//
//  PrimerRawRetailerDataTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

class PrimerRawRetailerDataTests: XCTestCase {

    func test_validateRawData_withInvalidRetailerData_shouldFail() async throws {
        // Given
        let rawRetailData = PrimerRetailerData(id: "")
        let tokenizationBuilder = PrimerRawRetailerDataTokenizationBuilder(paymentMethodType: "XENDIT_RETAIL_OUTLETS")

        // When & Then
        do {
            try await tokenizationBuilder.validateRawData(rawRetailData)
            XCTFail("Card data should not pass validation")
        } catch {
            // Expected to throw an error for invalid data
        }
    }

    func test_validateRawData_withValidRetailerData_shouldSucceed() async throws {
        // Given
        let rawRetailData = PrimerRetailerData(id: "test")
        let tokenizationBuilder = PrimerRawRetailerDataTokenizationBuilder(paymentMethodType: "XENDIT_RETAIL_OUTLETS")

        // When & Then
        do {
            try await tokenizationBuilder.validateRawData(rawRetailData)
            // Expected to succeed without throwing
        } catch {
            XCTFail("Card data should pass validation")
        }
    }
}
