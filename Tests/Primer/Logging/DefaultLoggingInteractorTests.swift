//
//  DefaultLoggingInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - Mock LoggingInteractor

final class MockLoggingInteractor: LoggingInteractor {
    var logInfoCalls: [(event: String, initDurationMs: Int?)] = []
    var logErrorCalls: [(message: String, error: Error)] = []

    func logInfo(event: String, initDurationMs: Int?) {
        logInfoCalls.append((event: event, initDurationMs: initDurationMs))
    }

    func logError(message: String, error: Error) {
        logErrorCalls.append((message: message, error: error))
    }

    func reset() {
        logInfoCalls = []
        logErrorCalls = []
    }
}

// MARK: - Tests

final class DefaultLoggingInteractorTests: XCTestCase {

    // MARK: - Protocol Mockability Tests

    func test_loggingInteractorProtocol_canBeMocked() {
        // Given
        let mock = MockLoggingInteractor()

        // When
        mock.logInfo(event: "SDK_INIT", initDurationMs: 100)
        mock.logError(message: "Test error", error: NSError(domain: "test", code: 1))

        // Then
        XCTAssertEqual(mock.logInfoCalls.count, 1)
        XCTAssertEqual(mock.logInfoCalls.first?.event, "SDK_INIT")
        XCTAssertEqual(mock.logInfoCalls.first?.initDurationMs, 100)

        XCTAssertEqual(mock.logErrorCalls.count, 1)
        XCTAssertEqual(mock.logErrorCalls.first?.message, "Test error")
    }

    func test_loggingInteractorProtocol_mockCanBeUsedAsProtocolType() {
        // Given
        let mock = MockLoggingInteractor()
        let interactor: LoggingInteractor = mock

        // When
        interactor.logInfo(event: "PAYMENT_SUCCESS", initDurationMs: nil)

        // Then
        XCTAssertEqual(mock.logInfoCalls.count, 1)
        XCTAssertEqual(mock.logInfoCalls.first?.event, "PAYMENT_SUCCESS")
    }

    // MARK: - Initialization Tests

    func test_init_createsInteractor() {
        // Given
        let loggingService = LoggingService(
            networkClient: LogNetworkClient(),
            payloadBuilder: LogPayloadBuilder(),
            masker: SensitiveDataMasker()
        )

        // When
        let interactor = DefaultLoggingInteractor(loggingService: loggingService)

        // Then
        XCTAssertNotNil(interactor)
    }

    // MARK: - logInfo Tests

    func test_logInfo_doesNotCrash() {
        // Given
        let loggingService = LoggingService(
            networkClient: LogNetworkClient(),
            payloadBuilder: LogPayloadBuilder(),
            masker: SensitiveDataMasker()
        )
        let interactor = DefaultLoggingInteractor(loggingService: loggingService)

        // When/Then - should not crash
        interactor.logInfo(event: "SDK_INIT")
        interactor.logInfo(event: "SDK_INIT", initDurationMs: 150)
    }

    // MARK: - logError Tests

    func test_logError_doesNotCrash() {
        // Given
        let loggingService = LoggingService(
            networkClient: LogNetworkClient(),
            payloadBuilder: LogPayloadBuilder(),
            masker: SensitiveDataMasker()
        )
        let interactor = DefaultLoggingInteractor(loggingService: loggingService)
        let testError = NSError(domain: "test", code: 1, userInfo: [NSLocalizedDescriptionKey: "Test error"])

        // When/Then - should not crash
        interactor.logError(message: "Payment failed", error: testError)
    }
}
