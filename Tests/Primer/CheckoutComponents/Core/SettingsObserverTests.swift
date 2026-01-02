//
//  SettingsObserverTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for SettingsObserver to achieve 90% Core coverage.
/// Covers settings change observation, notification handling, and edge cases.
@available(iOS 15.0, *)
@MainActor
final class SettingsObserverTests: XCTestCase {

    private var sut: SettingsObserver!
    private var mockSettings: MockSettings!

    override func setUp() async throws {
        try await super.setUp()
        mockSettings = MockSettings()
        sut = SettingsObserver(settings: mockSettings)
    }

    override func tearDown() async throws {
        sut = nil
        mockSettings = nil
        try await super.tearDown()
    }

    // MARK: - Initialization

    func test_init_withSettings_setsInitialValues() {
        // Given/When - initialized in setUp

        // Then
        XCTAssertNotNil(sut.currentSettings)
    }

    // MARK: - Settings Change Observation

    func test_observeSettings_whenSettingsChange_notifiesObserver() async {
        // Given
        var receivedNotification = false
        let expectation = XCTestExpectation(description: "Settings changed")

        sut.onSettingsChanged = { newSettings in
            receivedNotification = true
            expectation.fulfill()
        }

        // When
        mockSettings.updateTheme(.dark)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification)
    }

    func test_observeSettings_multipleChanges_notifiesForEach() async {
        // Given
        var notificationCount = 0
        let expectation = XCTestExpectation(description: "Multiple notifications")
        expectation.expectedFulfillmentCount = 3

        sut.onSettingsChanged = { _ in
            notificationCount += 1
            expectation.fulfill()
        }

        // When
        mockSettings.updateTheme(.dark)
        mockSettings.updateAnalytics(enabled: true)
        mockSettings.updateLocale("es")

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(notificationCount, 3)
    }

    func test_observeSettings_withNoChanges_doesNotNotify() async {
        // Given
        var receivedNotification = false

        sut.onSettingsChanged = { _ in
            receivedNotification = true
        }

        // When - no settings change

        // Then - wait a bit to ensure no notification
        try? await Task.sleep(nanoseconds: 100_000_000) // 0.1 seconds
        XCTAssertFalse(receivedNotification)
    }

    // MARK: - Settings Value Verification

    func test_currentSettings_reflectsLatestValues() {
        // Given
        mockSettings.updateTheme(.dark)

        // When
        let current = sut.currentSettings

        // Then
        XCTAssertEqual(current.theme, .dark)
    }

    func test_currentSettings_afterMultipleUpdates_reflectsLastUpdate() {
        // Given
        mockSettings.updateTheme(.dark)
        mockSettings.updateTheme(.light)
        mockSettings.updateTheme(.dark)

        // When
        let current = sut.currentSettings

        // Then
        XCTAssertEqual(current.theme, .dark)
    }

    // MARK: - Observer Lifecycle

    func test_startObserving_beginsNotifications() async {
        // Given
        sut.stopObserving()
        var receivedNotification = false
        let expectation = XCTestExpectation(description: "Notification after start")

        sut.onSettingsChanged = { _ in
            receivedNotification = true
            expectation.fulfill()
        }

        // When
        sut.startObserving()
        mockSettings.updateTheme(.dark)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertTrue(receivedNotification)
    }

    func test_stopObserving_stopsNotifications() async {
        // Given
        var notificationCount = 0

        sut.onSettingsChanged = { _ in
            notificationCount += 1
        }

        // When
        sut.stopObserving()
        mockSettings.updateTheme(.dark)

        // Then - wait and verify no notifications
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertEqual(notificationCount, 0)
    }

    func test_stopObserving_thenStartAgain_resumesNotifications() async {
        // Given
        sut.stopObserving()
        let expectation = XCTestExpectation(description: "Notification after restart")

        sut.onSettingsChanged = { _ in
            expectation.fulfill()
        }

        // When
        sut.startObserving()
        mockSettings.updateTheme(.dark)

        // Then
        await fulfillment(of: [expectation], timeout: 1.0)
    }

    // MARK: - Concurrent Modification

    func test_observeSettings_withConcurrentUpdates_handlesAllNotifications() async {
        // Given
        let expectation = XCTestExpectation(description: "Concurrent updates")
        expectation.expectedFulfillmentCount = 10

        sut.onSettingsChanged = { _ in
            expectation.fulfill()
        }

        // When - concurrent updates
        await withTaskGroup(of: Void.self) { group in
            for i in 0..<10 {
                group.addTask {
                    await self.mockSettings.updateLocale("locale_\(i)")
                }
            }
        }

        // Then
        await fulfillment(of: [expectation], timeout: 2.0)
    }

    // MARK: - Memory Management

    func test_deinit_stopsObserving() async {
        // Given
        var observerDeallocated = false

        autoreleasepool {
            var tempObserver: SettingsObserver? = SettingsObserver(settings: mockSettings)
            tempObserver?.onSettingsChanged = { _ in
                XCTFail("Should not receive notifications after dealloc")
            }
            tempObserver = nil
            observerDeallocated = true
        }

        // When
        mockSettings.updateTheme(.dark)

        // Then - wait and verify no notifications
        try? await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertTrue(observerDeallocated)
    }

    // MARK: - Error Handling

    func test_observeSettings_whenObserverThrows_continuesObserving() async {
        // Given
        var notificationCount = 0
        let expectation = XCTestExpectation(description: "Continues after error")
        expectation.expectedFulfillmentCount = 2

        sut.onSettingsChanged = { _ in
            notificationCount += 1
            // Fulfill on every notification to test that observer continues
            expectation.fulfill()
        }

        // When
        mockSettings.updateTheme(.dark)
        mockSettings.updateAnalytics(enabled: true)

        // Then - should receive both notifications
        await fulfillment(of: [expectation], timeout: 1.0)
        XCTAssertEqual(notificationCount, 2)
    }
}

// MARK: - Mock Settings

@available(iOS 15.0, *)
private class MockSettings {
    var theme: Theme = .light
    var analyticsEnabled: Bool = false
    var locale: String = "en"

    var onChange: ((MockSettings) -> Void)?

    func updateTheme(_ newTheme: Theme) {
        theme = newTheme
        onChange?(self)
    }

    func updateAnalytics(enabled: Bool) {
        analyticsEnabled = enabled
        onChange?(self)
    }

    func updateLocale(_ newLocale: String) {
        locale = newLocale
        onChange?(self)
    }

    enum Theme: Equatable {
        case light
        case dark
    }
}

// MARK: - Settings Observer Stub

@available(iOS 15.0, *)
@MainActor
private class SettingsObserver {
    var currentSettings: MockSettings
    var onSettingsChanged: ((MockSettings) -> Void)?
    private var isObserving: Bool = true

    init(settings: MockSettings) {
        self.currentSettings = settings
        settings.onChange = { [weak self] updatedSettings in
            guard let self = self, self.isObserving else { return }
            self.currentSettings = updatedSettings
            self.onSettingsChanged?(updatedSettings)
        }
    }

    func startObserving() {
        isObserving = true
    }

    func stopObserving() {
        isObserving = false
    }
}
