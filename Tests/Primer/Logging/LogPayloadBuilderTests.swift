//
//  LogPayloadBuilderTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class LogPayloadBuilderTests: XCTestCase {

    var builder: LogPayloadBuilder!
    var mockSessionData: LoggingSessionContext.SessionData!

    override func setUp() {
        super.setUp()
        builder = LogPayloadBuilder()
        mockSessionData = LoggingSessionContext.SessionData(
            environment: .sandbox,
            checkoutSessionId: "test-checkout-id",
            clientSessionId: "test-client-id",
            primerAccountId: "test-account-id",
            sdkVersion: "2.41.0",
            clientSessionToken: nil,
            hostname: "com.test.app",
            integrationType: .swiftUI
        )
    }

    override func tearDown() {
        builder = nil
        mockSessionData = nil
        super.tearDown()
    }

    // MARK: - Info Payload Tests

    func test_buildInfoPayload_containsDeviceInfo() throws {
        let payload = try builder.buildInfoPayload(
            message: "test",
            event: "TEST",
            initDurationMs: nil,
            sessionData: mockSessionData
        )

        let json = try parseJSON(payload.message)
        let deviceInfo = json["device_info"] as? [String: Any]

        XCTAssertNotNil(deviceInfo?["model"])
        XCTAssertNotNil(deviceInfo?["os_version"])
        XCTAssertNotNil(deviceInfo?["network_type"])
    }

    func test_buildInfoPayload_containsAppMetadata() throws {
        let payload = try builder.buildInfoPayload(
            message: "test",
            event: "TEST",
            initDurationMs: nil,
            sessionData: mockSessionData
        )

        let json = try parseJSON(payload.message)
        let appMetadata = json["app_metadata"] as? [String: Any]

        XCTAssertNotNil(appMetadata?["app_name"])
        XCTAssertNotNil(appMetadata?["app_version"])
        XCTAssertNotNil(appMetadata?["bundle_id"])
    }

    func test_buildInfoPayload_networkTypeIsValid() throws {
        let payload = try builder.buildInfoPayload(
            message: "test",
            event: "TEST",
            initDurationMs: nil,
            sessionData: mockSessionData
        )

        let json = try parseJSON(payload.message)
        let deviceInfo = json["device_info"] as? [String: Any]
        let networkType = deviceInfo?["network_type"] as? String

        XCTAssertTrue(["WIFI", "CELLULAR", "NONE"].contains(networkType ?? ""))
    }

    // MARK: - Error Payload Tests

    func test_buildErrorPayload_containsErrorDetails() throws {
        let payload = try builder.buildErrorPayload(
            message: "Payment failed",
            errorMessage: "Invalid card",
            errorStack: "at line 42",
            sessionData: mockSessionData
        )

        XCTAssertTrue(payload.message.contains("error"))
        XCTAssertTrue(payload.message.contains("Invalid card"))
    }

    // MARK: - Helper

    private func parseJSON(_ jsonString: String) throws -> [String: Any] {
        let data = jsonString.data(using: .utf8)!
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }
}
