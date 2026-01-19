//
//  DefaultLoggingInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class DefaultLoggingInteractorTests: XCTestCase {

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
