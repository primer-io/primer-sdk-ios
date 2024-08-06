//
//  File.swift
//  
//
//  Created by Niall Quinn on 06/08/24.
//

import XCTest
@testable import PrimerSDK

final class CheckoutSessionTests: XCTestCase {
    func test_headless_cleanup() {
        XCTAssertFalse(Primer.shared.checkoutSessionIsActive())

        let expectation = self.expectation(description: "Wait for headless load")

        PrimerHeadlessUniversalCheckout.current.start(withClientToken: "") { paymentMethods, err in
            XCTAssertTrue(Primer.shared.checkoutSessionIsActive())
            expectation.fulfill()
        }

        waitForExpectations(timeout: 30)
        PrimerHeadlessUniversalCheckout.current.cleanUp()
        XCTAssertFalse(Primer.shared.checkoutSessionIsActive())
    }
}
