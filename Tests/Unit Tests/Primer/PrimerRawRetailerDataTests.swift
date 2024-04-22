//
//  PrimerRawRetailDataTests.swift
//  ExampleAppTests
//
//  Created by Dario Carlomagno on 20/10/22.
//  Copyright © 2022 Primer API Ltd. All rights reserved.
//

import XCTest
@testable import PrimerSDK

class PrimerRawRetailerDataTests: XCTestCase {

    private static let expectationTimeout = 1.0

    func test_invalid_raw_retail_data() throws {
        let exp = expectation(description: "Await validation")

        let rawRetailData = PrimerRetailerData(id: "")

        let tokenizationBuilder = PrimerRawRetailerDataTokenizationBuilder(paymentMethodType: "XENDIT_RETAIL_OUTLETS")

        firstly {
            return tokenizationBuilder.validateRawData(rawRetailData)
        }
        .done {
            XCTAssert(false, "Card data should not pass validation")
            exp.fulfill()
        }
        .catch { _ in
            exp.fulfill()
        }

        wait(for: [exp], timeout: Self.expectationTimeout)
    }

    func test_valid_raw_retail_data() throws {
        let exp = expectation(description: "Await validation")

        let rawRetailData = PrimerRetailerData(id: "test")

        let tokenizationBuilder = PrimerRawRetailerDataTokenizationBuilder(paymentMethodType: "XENDIT_RETAIL_OUTLETS")

        firstly {
            return tokenizationBuilder.validateRawData(rawRetailData)
        }
        .done { _ in
            exp.fulfill()
        }
        .catch { _ in
            XCTAssert(false, "Card data should pass validation")
            exp.fulfill()
        }

        wait(for: [exp], timeout: Self.expectationTimeout)
    }

}
