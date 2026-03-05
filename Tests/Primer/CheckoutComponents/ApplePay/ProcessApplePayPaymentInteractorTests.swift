//
//  ProcessApplePayPaymentInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class ProcessApplePayPaymentInteractorTests: XCTestCase {

    // MARK: - Properties

    private var sut: ProcessApplePayPaymentInteractorImpl!
    private var mockTokenizationService: MockTokenizationService!
    private var mockCreatePaymentService: MockCreateResumePaymentService!

    // MARK: - Setup & Teardown

    override func setUp() async throws {
        try await super.setUp()
        mockTokenizationService = MockTokenizationService()
        mockCreatePaymentService = MockCreateResumePaymentService()

        sut = ProcessApplePayPaymentInteractorImpl(
            tokenizationService: mockTokenizationService,
            createPaymentService: mockCreatePaymentService
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockTokenizationService = nil
        mockCreatePaymentService = nil
        SDKSessionHelper.tearDown()
        try await super.tearDown()
    }

    // MARK: - Success Tests

    func test_execute_success_returnsPaymentResult() async throws {
        // Given
        setupValidConfiguration()

        mockTokenizationService.onTokenize = { _ in
            .success(ApplePayTestData.tokenizationResponse)
        }

        mockCreatePaymentService.onCreatePayment = { _ in
            ApplePayTestData.paymentResponse(status: .success)
        }

        let mockPayment = SharedMockPKPayment()

        // When
        let result = try await sut.execute(payment: mockPayment)

        // Then
        XCTAssertEqual(result.paymentId, ApplePayTestData.Constants.paymentId)
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.paymentMethodType, "APPLE_PAY")
    }

    func test_execute_mapsPaymentStatus_pending() async throws {
        // Given
        setupValidConfiguration()

        mockTokenizationService.onTokenize = { _ in
            .success(ApplePayTestData.tokenizationResponse)
        }

        mockCreatePaymentService.onCreatePayment = { _ in
            ApplePayTestData.paymentResponse(status: .pending)
        }

        let mockPayment = SharedMockPKPayment()

        // When
        let result = try await sut.execute(payment: mockPayment)

        // Then
        XCTAssertEqual(result.status, .pending)
    }

    func test_execute_mapsPaymentStatus_failed() async throws {
        // Given
        setupValidConfiguration()

        mockTokenizationService.onTokenize = { _ in
            .success(ApplePayTestData.tokenizationResponse)
        }

        mockCreatePaymentService.onCreatePayment = { _ in
            ApplePayTestData.paymentResponse(status: .failed)
        }

        let mockPayment = SharedMockPKPayment()

        // When
        let result = try await sut.execute(payment: mockPayment)

        // Then
        XCTAssertEqual(result.status, .failed)
    }

    // MARK: - Failure Tests

    func test_execute_failure_whenApplePayConfigMissing_throwsError() async throws {
        // Given - setup with no Apple Pay payment method
        SDKSessionHelper.setUp(
            withPaymentMethods: [Mocks.PaymentMethods.paymentCardPaymentMethod],
            order: ApplePayTestData.defaultOrder,
            showTestId: true
        )
        ApplePayTestData.registerApplePaySettings()

        let mockPayment = SharedMockPKPayment()

        // When/Then
        do {
            _ = try await sut.execute(payment: mockPayment)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .unsupportedPaymentMethod = error {
                // Expected
            } else {
                XCTFail("Expected unsupportedPaymentMethod error, got \(error)")
            }
        }
    }

    func test_execute_failure_whenMerchantIdentifierMissing_throwsError() async throws {
        // Given
        SDKSessionHelper.setUp(
            withPaymentMethods: [ApplePayTestData.applePayPaymentMethod],
            order: ApplePayTestData.defaultOrder,
            showTestId: true
        )
        let settings = PrimerSettings()
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let mockPayment = SharedMockPKPayment()

        // When/Then
        do {
            _ = try await sut.execute(payment: mockPayment)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidMerchantIdentifier = error {
                // Expected
            } else {
                XCTFail("Expected invalidMerchantIdentifier error, got \(error)")
            }
        }
    }

    func test_execute_failure_whenApplePayConfigIdMissing_throwsError() async throws {
        // Given - Apple Pay payment method without id
        let applePayWithoutId = PrimerPaymentMethod(
            id: nil,
            implementationType: .nativeSdk,
            type: "APPLE_PAY",
            name: "Apple Pay",
            processorConfigId: "apple_pay_processor",
            surcharge: nil,
            options: ApplePayOptions(
                merchantName: ApplePayTestData.Constants.merchantName,
                recurringPaymentRequest: nil,
                deferredPaymentRequest: nil,
                automaticReloadRequest: nil
            ),
            displayMetadata: nil
        )

        SDKSessionHelper.setUp(
            withPaymentMethods: [applePayWithoutId],
            order: ApplePayTestData.defaultOrder,
            showTestId: true
        )
        ApplePayTestData.registerApplePaySettings()

        let mockPayment = SharedMockPKPayment()

        // When/Then
        do {
            _ = try await sut.execute(payment: mockPayment)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case let .invalidValue(key, _, _, _) = error {
                XCTAssertEqual(key, "applePayConfig.id")
            } else {
                XCTFail("Expected invalidValue error for config id, got \(error)")
            }
        }
    }

    func test_execute_failure_whenTokenizationFails_throwsError() async throws {
        // Given
        setupValidConfiguration()

        let tokenizationError = PrimerError.unknown(message: "Tokenization failed")
        mockTokenizationService.onTokenize = { _ in
            .failure(tokenizationError)
        }

        let mockPayment = SharedMockPKPayment()

        // When/Then
        do {
            _ = try await sut.execute(payment: mockPayment)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected - error propagated
        }
    }

    func test_execute_failure_whenTokenIsNil_throwsError() async throws {
        // Given
        setupValidConfiguration()

        let tokenResponse = Response.Body.Tokenization(
            analyticsId: "analytics_id",
            id: "token_id",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .applePay,
            paymentMethodType: "APPLE_PAY",
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: nil, // Nil token
            tokenType: .singleUse,
            vaultData: nil
        )
        mockTokenizationService.onTokenize = { _ in
            .success(tokenResponse)
        }

        let mockPayment = SharedMockPKPayment()

        // When/Then
        do {
            _ = try await sut.execute(payment: mockPayment)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case let .invalidValue(key, _, _, _) = error {
                XCTAssertEqual(key, "paymentMethodTokenData.token")
            } else {
                XCTFail("Expected invalidValue error, got \(error)")
            }
        }
    }

    func test_execute_failure_whenPaymentCreationFails_throwsError() async throws {
        // Given
        setupValidConfiguration()

        mockTokenizationService.onTokenize = { _ in
            .success(ApplePayTestData.tokenizationResponse)
        }

        mockCreatePaymentService.onCreatePayment = { _ in
            nil // Will cause unknown error
        }

        let mockPayment = SharedMockPKPayment()

        // When/Then
        do {
            _ = try await sut.execute(payment: mockPayment)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected - error propagated
        }
    }

    // MARK: - Helpers

    private func setupValidConfiguration() {
        SDKSessionHelper.setUp(
            withPaymentMethods: [ApplePayTestData.applePayPaymentMethod],
            order: ApplePayTestData.defaultOrder,
            showTestId: true
        )
        ApplePayTestData.registerApplePaySettings()
    }

}
