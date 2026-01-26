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

    var sut: ProcessApplePayPaymentInteractorImpl!
    var mockTokenizationService: MockTokenizationService!
    var mockCreatePaymentService: MockCreateResumePaymentService!

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

        let mockPayment = createMockPKPayment()

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

        let mockPayment = createMockPKPayment()

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

        let mockPayment = createMockPKPayment()

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
        registerApplePaySettings()

        let mockPayment = createMockPKPayment()

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
        // Register settings without apple pay options
        let settings = PrimerSettings()
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        let mockPayment = createMockPKPayment()

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
        registerApplePaySettings()

        let mockPayment = createMockPKPayment()

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

        let mockPayment = createMockPKPayment()

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

        let mockPayment = createMockPKPayment()

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

        let mockPayment = createMockPKPayment()

        // When/Then
        do {
            _ = try await sut.execute(payment: mockPayment)
            XCTFail("Expected error to be thrown")
        } catch {
            // Expected - error propagated
        }
    }

    // MARK: - Payment Instrument Building Tests

    func test_execute_withEmptyPaymentData_usesMockDataInDebugMode() async throws {
        // Given
        setupValidConfiguration()

        mockTokenizationService.onTokenize = { _ in
            .success(ApplePayTestData.tokenizationResponse)
        }

        mockCreatePaymentService.onCreatePayment = { _ in
            ApplePayTestData.paymentResponse(status: .success)
        }

        // Empty payment data triggers mock mode
        let mockPayment = MockPKPaymentWithEmptyData()

        // When
        let result = try await sut.execute(payment: mockPayment)

        // Then - should succeed using mock data
        XCTAssertEqual(result.status, .success)
    }

    func test_execute_withDifferentPaymentMethodTypes_setsCorrectType() async throws {
        // Given
        setupValidConfiguration()

        mockTokenizationService.onTokenize = { _ in
            .success(ApplePayTestData.tokenizationResponse)
        }

        mockCreatePaymentService.onCreatePayment = { _ in
            ApplePayTestData.paymentResponse(status: .success)
        }

        let mockPayment = MockPKPaymentWithCreditCard()

        // When
        let result = try await sut.execute(payment: mockPayment)

        // Then
        XCTAssertEqual(result.paymentMethodType, "APPLE_PAY")
    }

    // MARK: - Helpers

    private func setupValidConfiguration() {
        SDKSessionHelper.setUp(
            withPaymentMethods: [ApplePayTestData.applePayPaymentMethod],
            order: ApplePayTestData.defaultOrder,
            showTestId: true
        )
        registerApplePaySettings()
    }

    private func registerApplePaySettings() {
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(
                applePayOptions: PrimerApplePayOptions(
                    merchantIdentifier: ApplePayTestData.Constants.merchantIdentifier,
                    merchantName: ApplePayTestData.Constants.merchantName
                )
            )
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    private func createMockPKPayment() -> PKPayment {
        // PKPayment cannot be directly instantiated, but the interactor
        // handles this in DEBUG mode by using mock payment data when testId is present
        // or when payment data is empty. We'll use a minimal approach here.
        MockPKPayment()
    }
}

// MARK: - Mock PKPayment

/// Mock PKPayment for testing purposes
/// Since PKPayment cannot be directly instantiated, we use a subclass
@available(iOS 15.0, *)
private final class MockPKPayment: PKPayment {

    private let mockToken = MockPKPaymentToken()

    override var token: PKPaymentToken {
        mockToken
    }
}

@available(iOS 15.0, *)
private final class MockPKPaymentToken: PKPaymentToken {

    private let mockPaymentMethod = MockPKPaymentMethod()

    override var paymentMethod: PKPaymentMethod {
        mockPaymentMethod
    }

    override var transactionIdentifier: String {
        "mock_transaction_id"
    }

    override var paymentData: Data {
        // Return empty data to trigger mock mode in the interactor
        Data()
    }
}

@available(iOS 15.0, *)
private final class MockPKPaymentMethod: PKPaymentMethod {

    override var displayName: String? {
        "Mock Card"
    }

    override var network: PKPaymentNetwork? {
        .visa
    }

    override var type: PKPaymentMethodType {
        .debit
    }
}

// MARK: - Additional Mock Payments

@available(iOS 15.0, *)
private final class MockPKPaymentWithEmptyData: PKPayment {

    private let mockToken = MockPKPaymentTokenWithEmptyData()

    override var token: PKPaymentToken {
        mockToken
    }
}

@available(iOS 15.0, *)
private final class MockPKPaymentTokenWithEmptyData: PKPaymentToken {

    private let mockPaymentMethod = MockPKPaymentMethod()

    override var paymentMethod: PKPaymentMethod {
        mockPaymentMethod
    }

    override var transactionIdentifier: String {
        "empty_data_transaction"
    }

    override var paymentData: Data {
        Data() // Empty data
    }
}

@available(iOS 15.0, *)
private final class MockPKPaymentWithCreditCard: PKPayment {

    private let mockToken = MockPKPaymentTokenCreditCard()

    override var token: PKPaymentToken {
        mockToken
    }
}

@available(iOS 15.0, *)
private final class MockPKPaymentTokenCreditCard: PKPaymentToken {

    private let mockPaymentMethod = MockPKPaymentMethodCreditCard()

    override var paymentMethod: PKPaymentMethod {
        mockPaymentMethod
    }

    override var transactionIdentifier: String {
        "credit_card_transaction"
    }

    override var paymentData: Data {
        Data()
    }
}

@available(iOS 15.0, *)
private final class MockPKPaymentMethodCreditCard: PKPaymentMethod {

    override var displayName: String? {
        "Credit Card"
    }

    override var network: PKPaymentNetwork? {
        .masterCard
    }

    override var type: PKPaymentMethodType {
        .credit
    }
}
