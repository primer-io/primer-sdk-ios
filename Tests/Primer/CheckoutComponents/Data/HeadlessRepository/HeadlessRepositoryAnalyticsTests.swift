//
//  HeadlessRepositoryAnalyticsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerNetworking
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

// MARK: - Redirect Tracking
//
// 3DS challenge tracking moved off this repository: the challenge is now reported by
// `CheckoutAnalyticsTracker` when `Notification.Name.primer3DSChallengePresented` fires
// (see `CheckoutAnalyticsTrackerTests`), so `trackThreeDSChallengeIfNeeded` no longer exists here.

@available(iOS 15.0, *)
@MainActor
final class TrackRedirectToThirdPartyTests: XCTestCase {

    private var sut: HeadlessRepositoryImpl!
    private var mockAnalytics: MockTrackingAnalyticsInteractor!

    override func setUp() async throws {
        try await super.setUp()
        mockAnalytics = MockTrackingAnalyticsInteractor()
        let container = try await ContainerTestHelpers.createTestContainer(analyticsInteractor: mockAnalytics)
        await DIContainer.setContainer(container)
        sut = HeadlessRepositoryImpl()
    }

    override func tearDown() async throws {
        sut = nil
        mockAnalytics = nil
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    func test_trackRedirect_withNilAdditionalInfo_doesNotCrash() {
        // When / Then
        sut.trackRedirectToThirdPartyIfNeeded(from: nil, paymentMethodType: "PAYMENT_CARD")
    }

    func test_trackRedirect_withValidInfo_tracksRedirectToThirdPartyViaTypedCall() async throws {
        // Given
        let additionalInfo = PromptPayCheckoutAdditionalInfo(
            expiresAt: "2026-01-01T00:00:00Z",
            qrCodeUrl: "https://redirect.example.com/pay",
            qrCodeBase64: nil
        )

        // When
        sut.trackRedirectToThirdPartyIfNeeded(from: additionalInfo, paymentMethodType: "PROMPT_PAY")

        // Then
        let event = try await waitForTrackedEvent()
        XCTAssertEqual(event.eventType, .paymentRedirectToThirdParty)
        XCTAssertEqual(event.metadata?.paymentMethod, "PROMPT_PAY")
        XCTAssertEqual(event.metadata?.redirectDestinationUrl, "https://redirect.example.com")
    }

    func test_trackRedirect_sameUrlTwice_tracksOnlyOnce() async throws {
        // Given
        let additionalInfo = PromptPayCheckoutAdditionalInfo(
            expiresAt: "2026-01-01T00:00:00Z",
            qrCodeUrl: "https://redirect.example.com/pay",
            qrCodeBase64: nil
        )

        // When
        sut.trackRedirectToThirdPartyIfNeeded(from: additionalInfo, paymentMethodType: "PROMPT_PAY")
        _ = try await waitForTrackedEvent()
        sut.trackRedirectToThirdPartyIfNeeded(from: additionalInfo, paymentMethodType: "PROMPT_PAY")

        // Then — no second call lands for the deduplicated destination
        // why: negative assertion — the first call already awaited fully, there is no
        // further positive signal to await for the (intentionally absent) second one.
        try await Task.sleep(nanoseconds: 100_000_000)
        let count = await mockAnalytics.trackEventCallCount
        XCTAssertEqual(count, 1)
    }

    private func waitForTrackedEvent(
        timeout: TimeInterval = 2.0
    ) async throws -> (eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) {
        let deadline = Date().addingTimeInterval(timeout)
        while true {
            if let event = await mockAnalytics.trackedEvents.first { return event }
            if Date() > deadline { throw TestError.timeout }
            try await Task.sleep(nanoseconds: 10_000_000)
        }
    }
}

// MARK: - Bin Data Stream

@available(iOS 15.0, *)
@MainActor
final class BinDataStreamTests: XCTestCase {

    private var sut: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        sut = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    func test_getBinDataStream_returnsNonNilStream() {
        // When
        let stream = sut.getBinDataStream()

        // Then
        XCTAssertNotNil(stream)
    }
}
