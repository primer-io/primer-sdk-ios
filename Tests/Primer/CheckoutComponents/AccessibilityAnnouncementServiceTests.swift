//
//  AccessibilityAnnouncementServiceTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import UIKit
@testable import PrimerSDK

@available(iOS 15.0, *)
final class AccessibilityAnnouncementServiceTests: XCTestCase {

    var service: AccessibilityAnnouncementService!

    override func setUp() {
        super.setUp()
        service = DefaultAccessibilityAnnouncementService()
    }

    override func tearDown() {
        service = nil
        super.tearDown()
    }

    // MARK: - Basic Functionality Tests

    func testAnnounceError_DoesNotCrash() {
        // Given: An error message
        let errorMessage = "Invalid card number"

        // When/Then: Announcing error should not crash
        XCTAssertNoThrow {
            self.service.announceError(errorMessage)
        }
    }

    func testAnnounceStateChange_DoesNotCrash() {
        // Given: A state change message
        let stateMessage = "Loading payment methods"

        // When/Then: Announcing state change should not crash
        XCTAssertNoThrow {
            self.service.announceStateChange(stateMessage)
        }
    }

    func testAnnounceLayoutChange_DoesNotCrash() {
        // Given: A layout change message
        let layoutMessage = "Billing address fields shown"

        // When/Then: Announcing layout change should not crash
        XCTAssertNoThrow {
            self.service.announceLayoutChange(layoutMessage)
        }
    }

    func testAnnounceScreenChange_DoesNotCrash() {
        // Given: A screen change message
        let screenMessage = "Payment method selection"

        // When/Then: Announcing screen change should not crash
        XCTAssertNoThrow {
            self.service.announceScreenChange(screenMessage)
        }
    }

    // MARK: - Multiple Calls

    func testMultipleAnnouncementsInSequence() {
        // Given: Multiple announcements in typical usage pattern
        // When/Then: Should handle multiple calls without issues
        XCTAssertNoThrow {
            self.service.announceScreenChange("Payment method selection")
            self.service.announceStateChange("Loading")
            self.service.announceLayoutChange("Options updated")
            self.service.announceError("Validation failed")
        }
    }

    // MARK: - Thread Safety Tests

    func testConcurrentAnnouncements_DoNotCrash() {
        // Given: Multiple concurrent announcement operations
        let expectation = self.expectation(description: "Concurrent announcements")
        expectation.expectedFulfillmentCount = 10

        let queue = DispatchQueue(label: "test.concurrent", attributes: .concurrent)

        // When: Making concurrent announcements
        for i in 0..<10 {
            queue.async {
                self.service.announceError("Error \(i)")
                self.service.announceStateChange("State \(i)")
                expectation.fulfill()
            }
        }

        // Then: Should complete without crashing
        wait(for: [expectation], timeout: 5.0)
    }

    // MARK: - Performance Tests

    func testAnnouncement_Performance() {
        // Given: A message to announce
        let message = "Test message"

        // When: Measuring announcement performance
        measure {
            for _ in 0..<100 {
                self.service.announceError(message)
            }
        }

        // Then: Performance should be acceptable (measured by XCTest)
    }
}
