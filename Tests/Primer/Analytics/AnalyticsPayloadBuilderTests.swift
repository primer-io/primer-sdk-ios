//
//  AnalyticsPayloadBuilderTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

final class AnalyticsPayloadBuilderTests: XCTestCase {

    private var builder: AnalyticsPayloadBuilder!

    override func setUp() {
        super.setUp()
        builder = AnalyticsPayloadBuilder()
    }

    override func tearDown() {
        builder = nil
        super.tearDown()
    }

    // MARK: - Payload Construction Tests

    func testBuildPayload_WithMinimalData_CreatesValidPayload() {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart
        let config = makeTestConfig()

        // When
        let payload = builder.buildPayload(
            eventType: eventType,
            metadata: nil,
            config: config
        )

        // Then
        XCTAssertEqual(payload.eventName, eventType.rawValue)
        XCTAssertEqual(payload.checkoutSessionId, config.checkoutSessionId)
        XCTAssertEqual(payload.clientSessionId, config.clientSessionId)
        XCTAssertEqual(payload.primerAccountId, config.primerAccountId)
        XCTAssertEqual(payload.sdkVersion, config.sdkVersion)
        XCTAssertFalse(payload.id.isEmpty)
        XCTAssertGreaterThan(payload.timestamp, 0)
    }

    func testBuildPayload_WithMetadata_IncludesMetadataFields() {
        // Given
        let eventType = AnalyticsEventType.paymentSuccess
        let config = makeTestConfig()
        let metadata: AnalyticsEventMetadata = .payment(PaymentEvent(
            paymentMethod: "PAYMENT_CARD",
            paymentId: "pay_123"
        ))

        // When
        let payload = builder.buildPayload(
            eventType: eventType,
            metadata: metadata,
            config: config
        )

        // Then
        XCTAssertEqual(payload.paymentMethod, "PAYMENT_CARD")
        XCTAssertEqual(payload.paymentId, "pay_123")
    }

    func testBuildPayload_WithRedirectMetadata_IncludesRedirectURL() {
        // Given
        let eventType = AnalyticsEventType.paymentRedirectToThirdParty
        let config = makeTestConfig()
        let metadata: AnalyticsEventMetadata = .redirect(RedirectEvent(
            destinationUrl: "https://example.com/redirect"
        ))

        // When
        let payload = builder.buildPayload(
            eventType: eventType,
            metadata: metadata,
            config: config
        )

        // Then
        XCTAssertEqual(payload.redirectDestinationUrl, "https://example.com/redirect")
    }

    func testBuildPayload_WithThreeDSMetadata_IncludesThreeDSFields() {
        // Given
        let eventType = AnalyticsEventType.paymentThreeds
        let config = makeTestConfig()
        let metadata: AnalyticsEventMetadata = .threeDS(ThreeDSEvent(
            paymentMethod: "PAYMENT_CARD",
            provider: "Netcetera",
            response: "authenticated"
        ))

        // When
        let payload = builder.buildPayload(
            eventType: eventType,
            metadata: metadata,
            config: config
        )

        // Then
        XCTAssertEqual(payload.threedsProvider, "Netcetera")
        XCTAssertEqual(payload.threedsResponse, "authenticated")
    }

    func testBuildPayload_AutoFillsUserAgent() {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart
        let config = makeTestConfig()

        // When
        let payload = builder.buildPayload(
            eventType: eventType,
            metadata: nil,
            config: config
        )

        // Then - userAgent should always be filled
        XCTAssertNotNil(payload.userAgent)
        XCTAssertTrue(payload.userAgent.contains("iOS/"))

        // But device and deviceType should be nil for SDK lifecycle events (nil metadata)
        XCTAssertNil(payload.device)
        XCTAssertNil(payload.deviceType)
    }

    func testBuildPayload_WithMetadata_AutoFillsDeviceInfo() {
        // Given
        let eventType = AnalyticsEventType.checkoutFlowStarted
        let config = makeTestConfig()
        let metadata: AnalyticsEventMetadata = .general(GeneralEvent())

        // When
        let payload = builder.buildPayload(
            eventType: eventType,
            metadata: metadata,
            config: config
        )

        // Then - device info should be auto-filled when metadata is present
        XCTAssertNotNil(payload.userAgent)
        XCTAssertNotNil(payload.device)
        XCTAssertNotNil(payload.deviceType)
        XCTAssertTrue(payload.userAgent.contains("iOS/"))
    }

    func testBuildPayload_WithCustomLocale_UsesProvidedLocale() {
        // Given
        let eventType = AnalyticsEventType.paymentMethodSelection
        let config = makeTestConfig()
        let metadata: AnalyticsEventMetadata = .general(GeneralEvent(locale: "fr-FR"))

        // When
        let payload = builder.buildPayload(
            eventType: eventType,
            metadata: metadata,
            config: config
        )

        // Then
        XCTAssertEqual(payload.userLocale, "fr-FR")
    }

    func testBuildPayload_WithoutMetadata_DoesNotIncludeLocale() {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart
        let config = makeTestConfig()

        // When
        let payload = builder.buildPayload(
            eventType: eventType,
            metadata: nil,
            config: config
        )

        // Then - should not include locale for SDK lifecycle events
        XCTAssertNil(payload.userLocale)
    }

    func testBuildPayload_GeneratesUniqueIds() {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart
        let config = makeTestConfig()

        // When
        let payload1 = builder.buildPayload(eventType: eventType, metadata: nil, config: config)
        let payload2 = builder.buildPayload(eventType: eventType, metadata: nil, config: config)

        // Then
        XCTAssertNotEqual(payload1.id, payload2.id)
    }

    func testBuildPayload_GeneratesUUIDv4Format() {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart
        let config = makeTestConfig()

        // When
        let payload = builder.buildPayload(eventType: eventType, metadata: nil, config: config)

        // Then - verify UUID v4 format
        let uuidComponents = payload.id.split(separator: "-")
        XCTAssertEqual(uuidComponents.count, 5, "UUID should have 5 segments separated by dashes")

        // Extract version bits (should be 0100 = 4 for UUID v4)
        let versionSegment = uuidComponents[2]
        let versionChar = versionSegment.first!
        XCTAssertTrue(versionChar == "4", "UUID version should be 4, got \(versionChar)")

        // Extract variant bits (should be 10xx = 8, 9, A, or B in hex)
        let variantSegment = uuidComponents[3]
        let variantChar = variantSegment.first!
        XCTAssertTrue(["8", "9", "A", "B", "a", "b"].contains(variantChar),
                     "UUID variant should be 8, 9, A, or B, got \(variantChar)")

        // Verify basic UUID structure
        XCTAssertEqual(uuidComponents[0].count, 8, "First segment should be 8 hex characters")
        XCTAssertEqual(uuidComponents[1].count, 4, "Second segment should be 4 hex characters")
        XCTAssertEqual(uuidComponents[2].count, 4, "Third segment should be 4 hex characters")
        XCTAssertEqual(uuidComponents[3].count, 4, "Fourth segment should be 4 hex characters")
        XCTAssertEqual(uuidComponents[4].count, 12, "Fifth segment should be 12 hex characters")
    }

    func testBuildPayload_GeneratesTimestamps() {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart
        let config = makeTestConfig()
        let beforeTimestamp = Int(Date().timeIntervalSince1970)

        // When
        let payload = builder.buildPayload(eventType: eventType, metadata: nil, config: config)
        let afterTimestamp = Int(Date().timeIntervalSince1970)

        // Then
        XCTAssertGreaterThanOrEqual(payload.timestamp, beforeTimestamp)
        XCTAssertLessThanOrEqual(payload.timestamp, afterTimestamp)
    }

    func testBuildPayload_DetectsNativeSDKType() {
        // Given
        let eventType = AnalyticsEventType.checkoutFlowStarted
        let config = makeTestConfig()

        // When
        let payload = builder.buildPayload(eventType: eventType, metadata: nil, config: config)

        // Then - in test environment without React Native, should be native
        XCTAssertEqual(payload.sdkType, "IOS_NATIVE")
    }

    // MARK: - Timestamp Override Tests

    func testBuildPayload_WithTimestampOverride_UsesProvidedTimestamp() {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart
        let config = makeTestConfig()
        let customTimestamp = 1609459200 // 2021-01-01 00:00:00 UTC

        // When
        let payload = builder.buildPayload(
            eventType: eventType,
            metadata: nil,
            config: config,
            timestamp: customTimestamp
        )

        // Then
        XCTAssertEqual(payload.timestamp, customTimestamp, "Payload should use the provided timestamp override")
    }

    func testBuildPayload_WithoutTimestampOverride_UsesCurrentTime() {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart
        let config = makeTestConfig()
        let beforeTimestamp = Int(Date().timeIntervalSince1970)

        // When
        let payload = builder.buildPayload(
            eventType: eventType,
            metadata: nil,
            config: config,
            timestamp: nil // Explicitly no override
        )

        let afterTimestamp = Int(Date().timeIntervalSince1970)

        // Then
        XCTAssertGreaterThanOrEqual(payload.timestamp, beforeTimestamp)
        XCTAssertLessThanOrEqual(payload.timestamp, afterTimestamp)
    }

    func testBuildPayload_TimestampOverride_PreservesOldTimestamps() {
        // Given
        let eventType = AnalyticsEventType.sdkInitStart
        let config = makeTestConfig()
        let oldTimestamp = Int(Date().timeIntervalSince1970) - 3600 // 1 hour ago

        // When
        let payload = builder.buildPayload(
            eventType: eventType,
            metadata: nil,
            config: config,
            timestamp: oldTimestamp
        )

        let currentTimestamp = Int(Date().timeIntervalSince1970)

        // Then
        XCTAssertEqual(payload.timestamp, oldTimestamp)
        XCTAssertLessThan(payload.timestamp, currentTimestamp, "Buffered event timestamp should be older than current time")
        XCTAssertEqual(currentTimestamp - payload.timestamp, 3600, accuracy: 5, "Timestamp should be approximately 1 hour old")
    }

    // MARK: - Helper Methods

    private func makeTestConfig() -> AnalyticsSessionConfig {
        AnalyticsSessionConfig(
            environment: .dev,
            checkoutSessionId: "cs_test_123",
            clientSessionId: "client_test_456",
            primerAccountId: "acc_test_789",
            sdkVersion: "2.46.7",
            clientSessionToken: "test_token_abc"
        )
    }
}
