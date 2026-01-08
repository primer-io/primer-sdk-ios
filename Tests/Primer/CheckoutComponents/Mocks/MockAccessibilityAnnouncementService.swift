//
//  MockAccessibilityAnnouncementService.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of AccessibilityAnnouncementService for testing
@available(iOS 15.0, *)
final class MockAccessibilityAnnouncementService: AccessibilityAnnouncementService {

    // MARK: - Call Tracking

    private(set) var announceErrorCallCount = 0
    private(set) var announceStateChangeCallCount = 0
    private(set) var announceLayoutChangeCallCount = 0
    private(set) var announceScreenChangeCallCount = 0

    private(set) var lastErrorMessage: String?
    private(set) var lastStateChangeMessage: String?
    private(set) var lastLayoutChangeMessage: String?
    private(set) var lastScreenChangeMessage: String?

    private(set) var allAnnouncements: [String] = []

    // MARK: - Protocol Implementation

    func announceError(_ message: String) {
        announceErrorCallCount += 1
        lastErrorMessage = message
        allAnnouncements.append("[ERROR] \(message)")
    }

    func announceStateChange(_ message: String) {
        announceStateChangeCallCount += 1
        lastStateChangeMessage = message
        allAnnouncements.append("[STATE] \(message)")
    }

    func announceLayoutChange(_ message: String) {
        announceLayoutChangeCallCount += 1
        lastLayoutChangeMessage = message
        allAnnouncements.append("[LAYOUT] \(message)")
    }

    func announceScreenChange(_ message: String) {
        announceScreenChangeCallCount += 1
        lastScreenChangeMessage = message
        allAnnouncements.append("[SCREEN] \(message)")
    }

    // MARK: - Test Helpers

    func reset() {
        announceErrorCallCount = 0
        announceStateChangeCallCount = 0
        announceLayoutChangeCallCount = 0
        announceScreenChangeCallCount = 0
        lastErrorMessage = nil
        lastStateChangeMessage = nil
        lastLayoutChangeMessage = nil
        lastScreenChangeMessage = nil
        allAnnouncements = []
    }

    var totalAnnouncementCount: Int {
        announceErrorCallCount + announceStateChangeCallCount +
            announceLayoutChangeCallCount + announceScreenChangeCallCount
    }
}
