//
//  CheckoutSessionTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class CheckoutSessionTests: XCTestCase {
    func test_headless_cleanup() throws {
        XCTAssertFalse(Primer.shared.checkoutSessionIsActive())

        let expectation = self.expectation(description: "Wait for headless load")

        PrimerHeadlessUniversalCheckout.current.start(withClientToken: "") { _, _ in
            XCTAssertTrue(Primer.shared.checkoutSessionIsActive())
            expectation.fulfill()
        }

        waitForExpectations(timeout: 30)
        PrimerHeadlessUniversalCheckout.current.cleanUp()
        XCTAssertFalse(Primer.shared.checkoutSessionIsActive())
    }

    func test_headless_delegates() throws {
        let mockDelegate = MockDelegate()
        let expectation = self.expectation(description: "Wait for headless load")
        PrimerHeadlessUniversalCheckout.current.start(withClientToken: "", delegate: mockDelegate, uiDelegate: mockDelegate) { _, _ in
            expectation.fulfill()
        }

        waitForExpectations(timeout: 30)
        guard let mockDelegate = PrimerHeadlessUniversalCheckout.current.delegate as? MockDelegate, let mockUIDelegate = PrimerHeadlessUniversalCheckout.current.uiDelegate as? MockDelegate else {
            XCTFail("Delegates not set")
            return
        }

        XCTAssertEqual(mockDelegate.id, "mock-id")
        XCTAssertEqual(mockUIDelegate.id, "mock-id")
    }
}

private class MockDelegate: PrimerHeadlessUniversalCheckoutDelegate, PrimerHeadlessUniversalCheckoutUIDelegate {
    let id = "mock-id"
    func primerHeadlessUniversalCheckoutDidCompleteCheckoutWithData(_ data: PrimerSDK.PrimerCheckoutData) {}
}
