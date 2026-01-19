//
//  LoggingSessionContextTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class LoggingSessionContextTests: XCTestCase {

    // MARK: - Test initialize()

    func test_initialize_extractsEnvironmentFromClientToken() async {
        // Given: A valid client token with environment data
        // Note: Session IDs are sourced dynamically from SDK state, not from JWT
        let clientToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbnZpcm9ubWVudCI6IlNBTkRCT1giLCJhcGkiOiJhcGkucHJpbWVyLmlvIn0.signature"

        let context = LoggingSessionContext.shared

        // When: Initializing session context
        await context.initialize(clientToken: clientToken, integrationType: .swiftUI)

        // Then: Environment should be extracted from JWT
        let sessionData = await context.getSessionData()
        XCTAssertEqual(sessionData.environment, .sandbox)
        // Session IDs come from SDK state, not JWT - they may be empty or have SDK-generated values
        XCTAssertFalse(sessionData.sdkVersion.isEmpty)
    }

    func test_initialize_withInvalidToken_setsDefaultEnvironment() async {
        // Given: An invalid or malformed client token
        let invalidToken = "invalid_token"

        let context = LoggingSessionContext.shared

        // When: Initializing with invalid token
        await context.initialize(clientToken: invalidToken, integrationType: .swiftUI)

        // Then: Should use default environment (production) but not crash
        let sessionData = await context.getSessionData()
        XCTAssertEqual(sessionData.environment, .production)
        XCTAssertFalse(sessionData.sdkVersion.isEmpty)
    }

    func test_initialize_withEmptyToken_setsDefaultEnvironment() async {
        // Given: An empty client token
        let emptyToken = ""

        let context = LoggingSessionContext.shared

        // When: Initializing with empty token
        await context.initialize(clientToken: emptyToken, integrationType: .swiftUI)

        // Then: Should use default environment (production)
        let sessionData = await context.getSessionData()
        XCTAssertEqual(sessionData.environment, .production)
        XCTAssertFalse(sessionData.sdkVersion.isEmpty)
    }

    // MARK: - Test recordInitStartTime()

    func test_recordInitStartTime_capturesTimestamp() async {
        // Given: A session context
        let context = LoggingSessionContext.shared

        // When: Recording init start time
        await context.recordInitStartTime()

        // Then: Should be able to calculate duration afterward
        try? await Task.sleep(nanoseconds: 10_000_000) // Sleep 10ms
        let duration = await context.calculateInitDuration()
        XCTAssertNotNil(duration)
        XCTAssertGreaterThanOrEqual(duration ?? 0, 10) // At least 10ms
    }

    // MARK: - Test calculateInitDuration()

    func test_calculateInitDuration_returnsNilWhenNotRecorded() async {
        // Given: A fresh session context with no recorded start time
        let context = LoggingSessionContext.shared
        await context.resetInitStartTime()

        // When: Calculating duration without recording start time
        let duration = await context.calculateInitDuration()

        // Then: Should return nil
        XCTAssertNil(duration)
    }

    func test_calculateInitDuration_returnsValidDuration() async {
        // Given: A session context with recorded start time
        let context = LoggingSessionContext.shared
        await context.recordInitStartTime()

        // When: Waiting some time and calculating duration
        try? await Task.sleep(nanoseconds: 50_000_000) // Sleep 50ms
        let duration = await context.calculateInitDuration()

        // Then: Duration should be at least 50ms
        XCTAssertNotNil(duration)
        XCTAssertGreaterThanOrEqual(duration ?? 0, 50)
    }

    func test_calculateInitDuration_returnsMilliseconds() async {
        // Given: A session context with recorded start time
        let context = LoggingSessionContext.shared
        await context.recordInitStartTime()

        // When: Calculating duration immediately
        let duration = await context.calculateInitDuration()

        // Then: Duration should be in milliseconds (small positive number)
        XCTAssertNotNil(duration)
        XCTAssertGreaterThanOrEqual(duration ?? 0, 0)
        XCTAssertLessThan(duration ?? 0, 1000) // Should be less than 1 second for immediate call
    }

    // MARK: - Test getSessionData()

    func test_getSessionData_returnsContextFields() async {
        // Given: An initialized session context
        let clientToken = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJlbnZpcm9ubWVudCI6IlNBTkRCT1giLCJhcGkiOiJhcGkucHJpbWVyLmlvIn0.signature"
        let context = LoggingSessionContext.shared
        await context.initialize(clientToken: clientToken, integrationType: .swiftUI)

        // When: Getting session data
        let sessionData = await context.getSessionData()

        // Then: Context-managed fields should be populated
        // Note: Session IDs come from SDK state and may be empty in test environment
        XCTAssertFalse(sessionData.hostname.isEmpty)
        XCTAssertFalse(sessionData.sdkVersion.isEmpty)
        XCTAssertEqual(sessionData.environment, .sandbox)
    }

    func test_getSessionData_includesSDKVersion() async {
        // Given: An initialized session context
        let context = LoggingSessionContext.shared
        await context.initialize(clientToken: "", integrationType: .swiftUI)

        // When: Getting session data
        let sessionData = await context.getSessionData()

        // Then: SDK version should not be empty
        XCTAssertFalse(sessionData.sdkVersion.isEmpty)
    }

    func test_getSessionData_includesHostnameFromBundleID() async {
        // Given: An initialized session context
        let context = LoggingSessionContext.shared
        await context.initialize(clientToken: "", integrationType: .swiftUI)

        // When: Getting session data
        let sessionData = await context.getSessionData()

        // Then: Hostname should be populated (either bundle ID or fallback)
        XCTAssertFalse(sessionData.hostname.isEmpty)
    }

}
