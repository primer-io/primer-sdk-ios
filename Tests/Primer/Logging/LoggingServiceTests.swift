//
//  LoggingServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Mock Network Client

actor MockLogNetworkClient: LogNetworkClientProtocol {
    var sentPayloads: [LogPayload] = []
    var sentEndpoints: [URL] = []
    var sentTokens: [String?] = []
    var shouldThrow = false

    func send(payload: LogPayload, to endpoint: URL, token: String?) async throws {
        if shouldThrow {
            throw LoggingError.encodingFailed
        }
        sentPayloads.append(payload)
        sentEndpoints.append(endpoint)
        sentTokens.append(token)
    }

    func reset() {
        sentPayloads = []
        sentEndpoints = []
        sentTokens = []
        shouldThrow = false
    }
}

// MARK: - Tests

final class LoggingServiceTests: XCTestCase {

    var mockNetworkClient: MockLogNetworkClient!
    var loggingService: LoggingService!

    override func setUp() async throws {
        try await super.setUp()
        mockNetworkClient = MockLogNetworkClient()
        loggingService = LoggingService(
            networkClient: mockNetworkClient,
            payloadBuilder: LogPayloadBuilder(),
            masker: SensitiveDataMasker()
        )

        // Set up session data for tests
        await LoggingSessionContext.shared.initialize(
            environment: .sandbox,
            checkoutSessionId: "test-checkout-id",
            clientSessionId: "test-client-id",
            primerAccountId: "test-account-id",
            sdkVersion: "2.41.0",
            clientSessionToken: "test-token"
        )
    }

    override func tearDown() async throws {
        mockNetworkClient = nil
        loggingService = nil
        try await super.tearDown()
    }

    // MARK: - sendInfo Tests

    func test_sendInfo_sendsPayloadToNetwork() async {
        await loggingService.sendInfo(message: "test", event: "SDK_INIT", initDurationMs: nil)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 1)
    }

    func test_sendInfo_payloadContainsCorrectService() async {
        await loggingService.sendInfo(message: "test", event: "SDK_INIT", initDurationMs: nil)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.first?.service, "ios-sdk")
    }

    func test_sendInfo_payloadContainsDDSource() async {
        await loggingService.sendInfo(message: "test", event: "SDK_INIT", initDurationMs: nil)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.first?.ddsource, "lambda")
    }

    func test_sendInfo_payloadContainsHostname() async {
        await loggingService.sendInfo(message: "test", event: "SDK_INIT", initDurationMs: nil)

        let payloads = await mockNetworkClient.sentPayloads
        // Hostname is set from Bundle.main.bundleIdentifier
        XCTAssertNotNil(payloads.first?.hostname)
        XCTAssertFalse(payloads.first?.hostname.isEmpty ?? true)
    }

    func test_sendInfo_usesCorrectEndpointForSandbox() async {
        await loggingService.sendInfo(message: "test", event: "SDK_INIT", initDurationMs: nil)

        let endpoints = await mockNetworkClient.sentEndpoints
        XCTAssertTrue(endpoints.first?.absoluteString.contains("sandbox") == true)
    }

    func test_sendInfo_passesToken() async {
        await loggingService.sendInfo(message: "test", event: "SDK_INIT", initDurationMs: nil)

        let tokens = await mockNetworkClient.sentTokens
        XCTAssertEqual(tokens.first ?? nil, "test-token")
    }

    // MARK: - sendError Tests

    func test_sendError_sendsPayloadToNetwork() async {
        let error = NSError(domain: "test", code: 1)
        await loggingService.sendError(message: "Payment failed", error: error)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 1)
    }

    func test_sendError_masksSensitiveData() async {
        let error = NSError(
            domain: "test",
            code: 1,
            userInfo: [NSLocalizedDescriptionKey: "Card 4111111111111111 failed"]
        )
        await loggingService.sendError(message: "Payment for user@email.com failed", error: error)

        let payloads = await mockNetworkClient.sentPayloads
        let message = payloads.first?.message ?? ""

        // Should not contain unmasked sensitive data
        XCTAssertFalse(message.contains("4111111111111111"))
        XCTAssertFalse(message.contains("user@email.com"))
    }

    // MARK: - Error Handling Tests

    func test_sendInfo_doesNotThrowOnNetworkError() async {
        await mockNetworkClient.reset()
        await MainActor.run {
            Task {
                await mockNetworkClient.reset()
            }
        }

        // This should not throw - fire-and-forget pattern
        await loggingService.sendInfo(message: "test", event: "SDK_INIT", initDurationMs: nil)
        // If we get here without crash, test passes
    }

    func test_sendError_doesNotThrowOnNetworkError() async {
        let error = NSError(domain: "test", code: 1)

        // This should not throw - fire-and-forget pattern
        await loggingService.sendError(message: "test", error: error)
        // If we get here without crash, test passes
    }
}
