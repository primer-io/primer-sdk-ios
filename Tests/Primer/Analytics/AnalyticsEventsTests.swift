//
//  AnalyticsEventsTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class AnalyticsEventsTests: XCTestCase {

    // MARK: - checkoutInitialized Tests

    func testCheckoutInitialized_createsMessageEventWithCorrectProperties() {
        // Given
        let timeToCheckoutMs = 1500
        let environment = "sandbox"

        // When
        let event = Analytics.Event.checkoutInitialized(
            timeToCheckoutMs: timeToCheckoutMs,
            environment: environment
        )

        // Then
        XCTAssertEqual(event.eventType, .message)

        guard let properties = event.properties as? MessageEventProperties else {
            XCTFail("Expected MessageEventProperties")
            return
        }

        XCTAssertEqual(properties.message, "Checkout initialized")
        XCTAssertEqual(properties.messageType, .info)
        XCTAssertEqual(properties.severity, .info)
        XCTAssertNil(properties.diagnosticsId)

        // Verify context contains expected values
        XCTAssertNotNil(properties.context)
        XCTAssertEqual(properties.context?["timeToCheckoutMs"] as? Int, timeToCheckoutMs)
        XCTAssertEqual(properties.context?["environment"] as? String, environment)
    }

    func testCheckoutInitialized_withNilEnvironment_usesUnknown() {
        // Given
        let timeToCheckoutMs = 2000

        // When
        let event = Analytics.Event.checkoutInitialized(
            timeToCheckoutMs: timeToCheckoutMs,
            environment: nil
        )

        // Then
        guard let properties = event.properties as? MessageEventProperties else {
            XCTFail("Expected MessageEventProperties")
            return
        }

        XCTAssertEqual(properties.context?["environment"] as? String, "unknown")
    }

    func testCheckoutInitialized_withZeroTime_createsValidEvent() {
        // Given
        let timeToCheckoutMs = 0
        let environment = "production"

        // When
        let event = Analytics.Event.checkoutInitialized(
            timeToCheckoutMs: timeToCheckoutMs,
            environment: environment
        )

        // Then
        guard let properties = event.properties as? MessageEventProperties else {
            XCTFail("Expected MessageEventProperties")
            return
        }

        XCTAssertEqual(properties.context?["timeToCheckoutMs"] as? Int, 0)
    }

    func testCheckoutInitialized_includesSDKTypeAndVersion() {
        // When
        let event = Analytics.Event.checkoutInitialized(
            timeToCheckoutMs: 1000,
            environment: "sandbox"
        )

        // Then
        XCTAssertNotNil(event.sdkType)
        XCTAssertFalse(event.sdkType.isEmpty)
        // sdkVersion may be nil in test environment, but sdkType should always be set
        XCTAssertTrue(event.sdkType == "IOS_NATIVE" || event.sdkType == "RN_IOS")
    }

    // MARK: - UDID Tests

    func testUDIDPersistsAcrossEvents() throws {
        let event1 = Analytics.Event.message(
            message: "",
            messageType: .other,
            severity: .debug
        )
        let event2 = Analytics.Event.sdk(
            name: "",
            params: nil
        )
        let event3 = Analytics.Event.ui(
            action: .click,
            context: nil,
            extra: nil,
            objectType: .button,
            objectId: nil,
            objectClass: nil,
            place: .cardForm
        )

        XCTAssertEqual(event1.device.uniqueDeviceIdentifier, event2.device.uniqueDeviceIdentifier)
        XCTAssertEqual(event2.device.uniqueDeviceIdentifier, event3.device.uniqueDeviceIdentifier)
    }
}
