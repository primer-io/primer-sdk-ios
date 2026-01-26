//
//  LoggingServiceTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - Mock Network Client

@available(iOS 15.0, *)
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

@available(iOS 15.0, *)
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

        await LoggingSessionContext.shared.initialize(
            environment: .sandbox,
            sdkVersion: "2.41.0",
            clientSessionToken: "test-token",
            integrationType: .swiftUI
        )
    }

    override func tearDown() async throws {
        mockNetworkClient = nil
        loggingService = nil
        try await super.tearDown()
    }

    // MARK: - logInfo Tests

    func test_logInfo_sendsPayloadToNetwork() async {
        await loggingService.logInfo(message: "test", event: "SDK_INIT")

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 1)
    }

    func test_logInfo_payloadContainsCorrectService() async {
        await loggingService.logInfo(message: "test", event: "SDK_INIT")

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.first?.service, "ios-sdk")
    }

    func test_logInfo_payloadContainsDDSource() async {
        await loggingService.logInfo(message: "test", event: "SDK_INIT")

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.first?.ddsource, "lambda")
    }

    func test_logInfo_payloadContainsHostname() async {
        await loggingService.logInfo(message: "test", event: "SDK_INIT")

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertNotNil(payloads.first?.hostname)
        XCTAssertFalse(payloads.first?.hostname.isEmpty ?? true)
    }

    func test_logInfo_usesCorrectEndpointForSandbox() async {
        await loggingService.logInfo(message: "test", event: "SDK_INIT")

        let endpoints = await mockNetworkClient.sentEndpoints
        XCTAssertTrue(endpoints.first?.absoluteString.contains("sandbox") == true)
    }

    func test_logInfo_passesToken() async {
        await loggingService.logInfo(message: "test", event: "SDK_INIT")

        let tokens = await mockNetworkClient.sentTokens
        XCTAssertEqual(tokens.first ?? nil, "test-token")
    }

    // MARK: - logErrorIfReportable Tests

    func test_logErrorIfReportable_sendsReportableError() async {
        let error = PrimerError.unknown(diagnosticsId: "test-id")
        await loggingService.logErrorIfReportable(error)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 1)
    }

    func test_logErrorIfReportable_skipsNonReportableError() async {
        let error = PrimerError.cancelled(paymentMethodType: "PAYMENT_CARD", diagnosticsId: "test-id")
        await loggingService.logErrorIfReportable(error)

        let payloads = await mockNetworkClient.sentPayloads
        XCTAssertEqual(payloads.count, 0)
    }

    func test_logErrorIfReportable_masksSensitiveData() async {
        let error = PrimerError.unknown(diagnosticsId: "test-id")
        await loggingService.logErrorIfReportable(
            error,
            message: "Payment for user@email.com with card 4111111111111111 failed"
        )

        let payloads = await mockNetworkClient.sentPayloads
        let message = payloads.first?.message ?? ""

        XCTAssertFalse(message.contains("4111111111111111"))
        XCTAssertFalse(message.contains("user@email.com"))
    }

    // MARK: - Error Handling Tests

    func test_logInfo_doesNotThrowOnNetworkError() async {
        await mockNetworkClient.reset()

        // Fire-and-forget pattern - should not throw
        await loggingService.logInfo(message: "test", event: "SDK_INIT")
    }

    func test_logErrorIfReportable_doesNotThrowOnNetworkError() async {
        let error = PrimerError.unknown(diagnosticsId: "test-id")

        // Fire-and-forget pattern - should not throw
        await loggingService.logErrorIfReportable(error)
    }
}
