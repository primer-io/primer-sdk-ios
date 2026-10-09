//
//  AccessibilityAnnouncementServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
final class AccessibilityAnnouncementServiceTests: XCTestCase {

    // MARK: - Notification Type Verification Tests

    // The service is @MainActor (it posts main-thread-only UIAccessibility notifications), so this
    // runs on the main actor. Off-main-actor usage is now a compile error, which supersedes the
    // former concurrent-threads "does not crash" test — the threading contract is enforced by the type system.
    @MainActor
    func test_announcements_eachType_usesCorrectNotificationType() {
        // Given: Test cases for each announcement type with expected notification
        let testCases: [(
            method: @MainActor (DefaultAccessibilityAnnouncementService, String) -> Void,
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
