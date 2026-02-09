//
//  AccessibilityAnnouncementServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
import XCTest

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

    // MARK: - Thread Safety Tests

    func testConcurrentAnnouncements_DoNotCrash() {
        // Given: Multiple concurrent announcement operations
        let concurrentOperationCount = TestData.Accessibility.concurrentOperationCount
        let expectation = self.expectation(description: TestData.Accessibility.concurrentExpectationDescription)
        expectation.expectedFulfillmentCount = concurrentOperationCount

        let queue = DispatchQueue(label: TestData.Accessibility.testQueueLabel, attributes: .concurrent)

        // When: Making concurrent announcements
        for i in 0..<concurrentOperationCount {
            queue.async { [self] in
                service.announceError("\(TestData.Accessibility.errorPrefix) \(i)")
                service.announceStateChange("\(TestData.Accessibility.statePrefix) \(i)")
                expectation.fulfill()
            }
        }

        // Then: Should complete without crashing
        wait(for: [expectation], timeout: TestData.Accessibility.testTimeout)
    }

    // MARK: - Notification Type Verification Tests

    func testAnnouncements_UseCorrectNotificationTypes() {
        // Given: Test cases for each announcement type with expected notification
        let testCases: [(
            method: (DefaultAccessibilityAnnouncementService, String) -> Void,
            expectedType: UIAccessibility.Notification,
            message: String,
            description: String
        )] = [
            ({ $0.announceError($1) }, .announcement,
             TestData.Accessibility.errorMessage, TestData.Accessibility.errorDescription),
            ({ $0.announceStateChange($1) }, .announcement,
             TestData.Accessibility.stateChangeMessage, TestData.Accessibility.stateChangeDescription),
            ({ $0.announceLayoutChange($1) }, .layoutChanged,
             TestData.Accessibility.layoutChangeMessage, TestData.Accessibility.layoutChangeDescription),
            ({ $0.announceScreenChange($1) }, .screenChanged,
             TestData.Accessibility.screenChangeMessage, TestData.Accessibility.screenChangeDescription)
        ]

        // When/Then: Each announcement type should use the correct notification type
        for (method, expectedType, message, description) in testCases {
            let mockPublisher = MockUIAccessibilityNotificationPublisher()
            let service = DefaultAccessibilityAnnouncementService(publisher: mockPublisher)

            method(service, message)

            XCTAssertEqual(mockPublisher.lastNotificationType, expectedType,
                           "\(description) should use correct notification type")
            XCTAssertEqual(mockPublisher.lastMessage, message,
                           "\(description) should pass message to notification publisher")
            XCTAssertEqual(mockPublisher.postCallCount, 1,
                           "\(description) should post exactly one notification")
        }
    }
}
