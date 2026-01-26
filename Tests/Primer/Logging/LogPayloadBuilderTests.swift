//
//  LogPayloadBuilderTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - Mock LogPayloadBuilding

final class MockLogPayloadBuilder: LogPayloadBuilding {
    typealias InfoPayloadCall = (message: String, event: String, userInfo: [String: Any]?)
    typealias ErrorPayloadCall = (message: String, errorMessage: String?, diagnosticsId: String?, stack: String?, event: String?, userInfo: [String: Any]?)

    var buildInfoPayloadCalls: [InfoPayloadCall] = []
    var buildErrorPayloadCalls: [ErrorPayloadCall] = []
    var shouldThrow = false

    func buildInfoPayload(
        message: String,
        event: String,
        userInfo: [String: Any]?,
        sessionData: LoggingSessionContext.SessionData
    ) throws -> LogPayload {
        if shouldThrow { throw LoggingError.encodingFailed }
        buildInfoPayloadCalls.append((message: message, event: event, userInfo: userInfo))
        return LogPayload(message: message, hostname: "test-host", ddtags: "env:test")
    }

    func buildErrorPayload(
        message: String,
        errorMessage: String?,
        diagnosticsId: String?,
        stack: String?,
        event: String?,
        userInfo: [String: Any]?,
        sessionData: LoggingSessionContext.SessionData
    ) throws -> LogPayload {
        if shouldThrow { throw LoggingError.encodingFailed }
        buildErrorPayloadCalls.append((message: message, errorMessage: errorMessage, diagnosticsId: diagnosticsId, stack: stack, event: event, userInfo: userInfo))
        return LogPayload(message: message, hostname: "test-host", ddtags: "env:test")
    }

    func reset() {
        buildInfoPayloadCalls = []
        buildErrorPayloadCalls = []
        shouldThrow = false
    }
}

// MARK: - Tests

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
            userInfo: nil,
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
            userInfo: nil,
            sessionData: mockSessionData
        )

        let json = try parseJSON(payload.message)
        let appMetadata = json["app_metadata"] as? [String: Any]

        XCTAssertNotNil(appMetadata?["app_name"])
        XCTAssertNotNil(appMetadata?["app_version"])
        XCTAssertNotNil(appMetadata?["app_id"])
    }

    func test_buildInfoPayload_networkTypeIsValid() throws {
        let payload = try builder.buildInfoPayload(
            message: "test",
            event: "TEST",
            userInfo: nil,
            sessionData: mockSessionData
        )

        let json = try parseJSON(payload.message)
        let deviceInfo = json["device_info"] as? [String: Any]
        let networkType = deviceInfo?["network_type"] as? String

        XCTAssertTrue(["WIFI", "CELLULAR", "NONE"].contains(networkType ?? ""))
    }

    func test_buildInfoPayload_extractsInitDurationMsFromUserInfo() throws {
        let payload = try builder.buildInfoPayload(
            message: "Checkout initialized (150ms)",
            event: "checkout-initialized",
            userInfo: ["init_duration_ms": 150],
            sessionData: mockSessionData
        )

        let json = try parseJSON(payload.message)
        XCTAssertEqual(json["init_duration_ms"] as? Int, 150)
    }

    func test_buildInfoPayload_addsCustomFieldsToRootLevel() throws {
        let payload = try builder.buildInfoPayload(
            message: "test",
            event: "TEST",
            userInfo: ["custom_key": "customValue", "another_key": 123],
            sessionData: mockSessionData
        )

        let json = try parseJSON(payload.message)
        XCTAssertEqual(json["custom_key"] as? String, "customValue")
        XCTAssertEqual(json["another_key"] as? Int, 123)
    }

    // MARK: - Error Payload Tests

    func test_buildErrorPayload_containsErrorDetails() throws {
        let payload = try builder.buildErrorPayload(
            message: "Payment failed",
            errorMessage: "Invalid card",
            diagnosticsId: "test-diagnostics-id",
            stack: "at line 42",
            event: "failed-to-create-payment",
            userInfo: nil,
            sessionData: mockSessionData
        )

        XCTAssertTrue(payload.message.contains("error"))
        XCTAssertTrue(payload.message.contains("Invalid card"))
    }

    func test_buildErrorPayload_containsEvent() throws {
        let payload = try builder.buildErrorPayload(
            message: "Payment failed",
            errorMessage: "Invalid card",
            diagnosticsId: "test-diagnostics-id",
            stack: "at line 42",
            event: "failed-to-create-payment",
            userInfo: nil,
            sessionData: mockSessionData
        )

        let json = try parseJSON(payload.message)
        XCTAssertEqual(json["event"] as? String, "failed-to-create-payment")
    }

    func test_buildErrorPayload_eventIsNilWhenNotProvided() throws {
        let payload = try builder.buildErrorPayload(
            message: "Payment failed",
            errorMessage: "Invalid card",
            diagnosticsId: nil,
            stack: nil,
            event: nil,
            userInfo: nil,
            sessionData: mockSessionData
        )

        let json = try parseJSON(payload.message)
        XCTAssertNil(json["event"])
    }

    func test_buildErrorPayload_addsUserInfoToRootLevel() throws {
        let payload = try builder.buildErrorPayload(
            message: "Payment failed",
            errorMessage: "Invalid card",
            diagnosticsId: nil,
            stack: nil,
            event: "payment-failed",
            userInfo: ["payment_method": "CARD", "retry_count": 2],
            sessionData: mockSessionData
        )

        let json = try parseJSON(payload.message)
        XCTAssertEqual(json["payment_method"] as? String, "CARD")
        XCTAssertEqual(json["retry_count"] as? Int, 2)
    }

    // MARK: - Protocol Mockability Tests

    func test_logPayloadBuildingProtocol_canBeMocked() throws {
        // Given
        let mock = MockLogPayloadBuilder()

        // When
        _ = try mock.buildInfoPayload(
            message: "test",
            event: "SDK_INIT",
            userInfo: ["init_duration_ms": 100],
            sessionData: mockSessionData
        )

        // Then
        XCTAssertEqual(mock.buildInfoPayloadCalls.count, 1)
        XCTAssertEqual(mock.buildInfoPayloadCalls.first?.event, "SDK_INIT")
        XCTAssertEqual(mock.buildInfoPayloadCalls.first?.userInfo?["init_duration_ms"] as? Int, 100)
    }

    func test_logPayloadBuildingProtocol_mockCanBeUsedAsProtocolType() throws {
        // Given
        let mock = MockLogPayloadBuilder()
        let builder: LogPayloadBuilding = mock

        // When
        _ = try builder.buildErrorPayload(
            message: "Payment failed",
            errorMessage: "Card declined",
            diagnosticsId: nil,
            stack: nil,
            event: "failed-to-create-payment",
            userInfo: nil,
            sessionData: mockSessionData
        )

        // Then
        XCTAssertEqual(mock.buildErrorPayloadCalls.count, 1)
        XCTAssertEqual(mock.buildErrorPayloadCalls.first?.message, "Payment failed")
        XCTAssertEqual(mock.buildErrorPayloadCalls.first?.errorMessage, "Card declined")
        XCTAssertEqual(mock.buildErrorPayloadCalls.first?.event, "failed-to-create-payment")
    }

    func test_logPayloadBuildingProtocol_mockCanThrowErrors() {
        // Given
        let mock = MockLogPayloadBuilder()
        mock.shouldThrow = true

        // When/Then
        XCTAssertThrowsError(try mock.buildInfoPayload(
            message: "test",
            event: "TEST",
            userInfo: nil,
            sessionData: mockSessionData
        ))
    }

    // MARK: - Helper

    private func parseJSON(_ jsonString: String) throws -> [String: Any] {
        let data = jsonString.data(using: .utf8)!
        return try JSONSerialization.jsonObject(with: data) as! [String: Any]
    }
}
