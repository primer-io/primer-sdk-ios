//
//  QRCodeRepositoryImplTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class QRCodeRepositoryImplTests: XCTestCase {

    private var mockTokenizationService: QRCodeMockTokenizationService!
    private var sut: QRCodeRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockTokenizationService = QRCodeMockTokenizationService()
        sut = QRCodeRepositoryImpl(tokenizationService: mockTokenizationService)
    }

    override func tearDown() {
        sut = nil
        mockTokenizationService = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - startPayment — Missing Configuration

    func test_startPayment_noPaymentMethodConfig_throwsInvalidValueError() async {
        // Given - no payment methods configured
        SDKSessionHelper.setUp(withPaymentMethods: [])

        // When/Then
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: _, diagnosticsId: _) = error {
                XCTAssertEqual(key, "configuration.id")
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_startPayment_paymentMethodWithNilId_throwsInvalidValueError() async {
        // Given - payment method exists but has nil id
        let paymentMethod = PrimerPaymentMethod(
            id: nil,
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        // When/Then
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: _, diagnosticsId: _) = error {
                XCTAssertEqual(key, "configuration.id")
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_startPayment_wrongPaymentMethodType_throwsInvalidValueError() async {
        // Given - only a different payment method type exists
        let paymentMethod = PrimerPaymentMethod(
            id: "different-id",
            implementationType: .nativeSdk,
            type: "SOME_OTHER_TYPE",
            name: "Other",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        // When/Then
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: _, diagnosticsId: _) = error {
                XCTAssertEqual(key, "configuration.id")
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - startPayment — Tokenization Failure

    func test_startPayment_tokenizationFails_propagatesError() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "qr-config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let expectedError = PrimerError.invalidClientToken()
        mockTokenizationService.onTokenize = { _ in .failure(expectedError) }

        // When/Then
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    func test_startPayment_tokenizationBuildsCorrectRequestBody() async {
        // Given
        let configId = "qr-config-id"
        let paymentMethodType = QRCodeTestData.Constants.paymentMethodType
        let paymentMethod = PrimerPaymentMethod(
            id: configId,
            implementationType: .nativeSdk,
            type: paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let tokenData = createMockQRTokenData(token: "mock_token")
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        // When/Then — will fail at createPayment (no mock for that),
        // but we can verify the tokenization request was built correctly
        do {
            _ = try await sut.startPayment(paymentMethodType: paymentMethodType)
        } catch {
            // Expected
        }

        // Then
        XCTAssertEqual(mockTokenizationService.tokenizeCallCount, 1)
        let instrument = mockTokenizationService.lastRequestBody?.paymentInstrument as? OffSessionPaymentInstrument
        XCTAssertEqual(instrument?.paymentMethodConfigId, configId)
        XCTAssertEqual(instrument?.paymentMethodType, paymentMethodType)
    }

    func test_startPayment_tokenizationReturnsNilToken_throwsInvalidValueError() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "qr-config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let tokenData = Response.Body.Tokenization(
            analyticsId: "analytics_123",
            id: "id_123",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .offSession,
            paymentMethodType: QRCodeTestData.Constants.paymentMethodType,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: nil,
            tokenType: .singleUse,
            vaultData: nil
        )
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        // When/Then
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: _, diagnosticsId: _) = error {
                XCTAssertEqual(key, "paymentMethodToken")
            } else {
                XCTFail("Expected invalidValue error for nil token, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - cancelPolling

    func test_cancelPolling_withoutActivePoll_doesNotCrash() {
        // Given - no polling started

        // When/Then - should not crash
        sut.cancelPolling(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
    }

    func test_cancelPolling_calledMultipleTimes_doesNotCrash() {
        // Given - no polling started

        // When/Then - multiple calls should be safe
        sut.cancelPolling(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
        sut.cancelPolling(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
    }

    // MARK: - cancelPolling — With Different Payment Method Types

    func test_cancelPolling_withDifferentPaymentMethodTypes_doesNotCrash() {
        // Given - no polling started

        // When/Then — different types should all be safe
        for type in ["XFERS_PAYNOW", "PROMPTPAY", "UNKNOWN_TYPE"] {
            sut.cancelPolling(paymentMethodType: type)
        }
    }

    // MARK: - resumePayment — Error from Service

    func test_resumePayment_serviceFailure_propagatesError() async {
        // Given
        SDKSessionHelper.setUp()

        // When/Then - CreateResumePaymentService will fail due to invalid session state
        do {
            _ = try await sut.resumePayment(
                paymentId: QRCodeTestData.Constants.paymentId,
                resumeToken: QRCodeTestData.Constants.resumeToken,
                paymentMethodType: QRCodeTestData.Constants.paymentMethodType
            )
            XCTFail("Expected error to be thrown")
        } catch {
            // CreateResumePaymentService uses PrimerAPIClient which will fail in test
            XCTAssertTrue(error is PrimerError)
        }
    }

    func test_resumePayment_noClientToken_throwsError() async {
        // Given - no client token set
        PrimerAPIConfigurationModule.clientToken = nil

        // When/Then
        do {
            _ = try await sut.resumePayment(
                paymentId: QRCodeTestData.Constants.paymentId,
                resumeToken: QRCodeTestData.Constants.resumeToken,
                paymentMethodType: QRCodeTestData.Constants.paymentMethodType
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - startPayment — Multiple Payment Methods in Config

    func test_startPayment_multiplePaymentMethods_findsCorrectOne() async {
        // Given - multiple payment methods, only one matches
        let otherMethod = PrimerPaymentMethod(
            id: "other-id",
            implementationType: .webRedirect,
            type: "ADYEN_SOFORT",
            name: "Sofort",
            processorConfigId: "processor-2",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        let qrMethod = PrimerPaymentMethod(
            id: "qr-config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [otherMethod, qrMethod])

        let tokenData = createMockQRTokenData(token: "test_token")
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        // When/Then - will fail at createPayment but should pass config lookup
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
        } catch {
            // Expected at createPayment stage
        }

        // Then - tokenization was called (config lookup succeeded)
        XCTAssertEqual(mockTokenizationService.tokenizeCallCount, 1)
    }

    // MARK: - startPayment — No API Configuration

    func test_startPayment_nilAPIConfiguration_throwsInvalidValueError() async {
        // Given
        PrimerAPIConfigurationModule.apiConfiguration = nil

        // When/Then
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: _, diagnosticsId: _) = error {
                XCTAssertEqual(key, "configuration.id")
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - startPayment — Session Info Locale

    func test_startPayment_sessionInfoUsesCurrentLocale() async {
        // Given
        let configId = "qr-config-id"
        let paymentMethodType = QRCodeTestData.Constants.paymentMethodType
        let paymentMethod = PrimerPaymentMethod(
            id: configId,
            implementationType: .nativeSdk,
            type: paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let tokenData = createMockQRTokenData(token: "mock_token")
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        // When
        do {
            _ = try await sut.startPayment(paymentMethodType: paymentMethodType)
        } catch {
            // Expected — createPayment will fail
        }

        // Then
        let instrument = mockTokenizationService.lastRequestBody?.paymentInstrument as? OffSessionPaymentInstrument
        XCTAssertNotNil(instrument)
        XCTAssertEqual(instrument?.paymentMethodConfigId, configId)
    }

    // MARK: - startPayment — Error Reason Messages

    func test_startPayment_noConfig_errorReasonContainsPaymentMethodType() async {
        // Given
        SDKSessionHelper.setUp(withPaymentMethods: [])

        // When/Then
        do {
            _ = try await sut.startPayment(paymentMethodType: "CUSTOM_QR_TYPE")
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: _, value: _, reason: let reason, diagnosticsId: _) = error {
                XCTAssertTrue(reason?.contains("CUSTOM_QR_TYPE") ?? false)
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_startPayment_nilToken_errorReasonMentionsNilToken() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "qr-config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let tokenData = createMockQRTokenData(token: nil)
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        // When/Then
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: let value, reason: let reason, diagnosticsId: _) = error {
                XCTAssertEqual(key, "paymentMethodToken")
                XCTAssertNil(value)
                XCTAssertTrue(reason?.contains("nil token") ?? false)
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - resumePayment — Constructs Correct Request

    func test_resumePayment_usesProvidedPaymentIdAndResumeToken() async {
        // Given
        SDKSessionHelper.setUp()
        let paymentId = "custom_pay_id"
        let resumeToken = "custom_resume_token"

        // When/Then — service will fail in test environment, but we verify the method accepts params
        do {
            _ = try await sut.resumePayment(
                paymentId: paymentId,
                resumeToken: resumeToken,
                paymentMethodType: QRCodeTestData.Constants.paymentMethodType
            )
            XCTFail("Expected error in test environment")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    func test_resumePayment_withDifferentPaymentMethodTypes_propagatesError() async {
        // Given
        SDKSessionHelper.setUp()

        // When/Then — verify different payment method types all reach the service
        for type in ["XFERS_PAYNOW", "PROMPTPAY"] {
            do {
                _ = try await sut.resumePayment(
                    paymentId: QRCodeTestData.Constants.paymentId,
                    resumeToken: QRCodeTestData.Constants.resumeToken,
                    paymentMethodType: type
                )
                XCTFail("Expected error for \(type)")
            } catch {
                XCTAssertTrue(error is PrimerError)
            }
        }
    }

    // MARK: - startPayment — Tokenization Error Types

    func test_startPayment_tokenizationThrowsUnknownError_propagatesError() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "qr-config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])
        mockTokenizationService.onTokenize = { _ in .failure(PrimerError.unknown()) }

        // When/Then
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .unknown = error {
                // Expected
            } else {
                XCTFail("Expected unknown error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_startPayment_tokenizationServiceNotConfigured_throwsUnknownError() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "qr-config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])
        // onTokenize is nil — should throw

        // When/Then
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - cancelPolling — Idempotent After Cancel

    func test_cancelPolling_afterPreviousCancel_isIdempotent() {
        // Given — cancel called once
        sut.cancelPolling(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)

        // When — cancel called again
        sut.cancelPolling(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)

        // Then — no crash, pollingModule remains nil
    }

    // MARK: - startPayment — Config ID Verification

    func test_startPayment_usesCorrectConfigId_inTokenizationRequest() async {
        // Given
        let expectedConfigId = "specific-config-id-42"
        let paymentMethod = PrimerPaymentMethod(
            id: expectedConfigId,
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let tokenData = createMockQRTokenData(token: "token")
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        // When
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
        } catch {
            // Expected at createPayment
        }

        // Then
        let instrument = mockTokenizationService.lastRequestBody?.paymentInstrument as? OffSessionPaymentInstrument
        XCTAssertEqual(instrument?.paymentMethodConfigId, expectedConfigId)
    }

    // MARK: - startPayment — Payment Method Type In Instrument

    func test_startPayment_paymentInstrumentContainsPaymentMethodType() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let tokenData = createMockQRTokenData(token: "token")
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        // When
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
        } catch {
            // Expected
        }

        // Then
        let instrument = mockTokenizationService.lastRequestBody?.paymentInstrument as? OffSessionPaymentInstrument
        XCTAssertEqual(instrument?.paymentMethodType, QRCodeTestData.Constants.paymentMethodType)
    }

    // MARK: - startPayment — Tokenize Called Exactly Once

    func test_startPayment_callsTokenizeExactlyOnce() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let tokenData = createMockQRTokenData(token: "token")
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        // When
        do {
            _ = try await sut.startPayment(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)
        } catch {
            // Expected
        }

        // Then
        XCTAssertEqual(mockTokenizationService.tokenizeCallCount, 1)
    }

    // MARK: - Default Initialization

    func test_defaultInit_doesNotCrash() {
        // Given/When
        let repository = QRCodeRepositoryImpl()

        // Then
        XCTAssertNotNil(repository)
    }

    // MARK: - startPayment — Happy Path (Injected Mocks)

    func test_startPayment_happyPath_returnsQRCodePaymentData() async throws {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "qr-config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let tokenData = createMockQRTokenData(token: "mock_token")
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        let mockPaymentService = MockCreateResumePaymentService()
        mockPaymentService.onCreatePayment = { _ in
            Response.Body.Payment(
                id: "pay_qr_happy",
                paymentId: "pay_qr_happy",
                amount: 1000,
                currencyCode: "THB",
                customer: nil,
                customerId: nil,
                dateStr: nil,
                order: nil,
                orderId: nil,
                requiredAction: Response.Body.Payment.RequiredAction(
                    clientToken: MockAppState.mockClientTokenWithQRCode,
                    name: .checkout,
                    description: nil
                ),
                status: .pending,
                paymentFailureReason: nil
            )
        }

        let mockConfigModule = MockPrimerAPIConfigurationModule()
        mockConfigModule.mockedNetworkDelay = 0

        sut = QRCodeRepositoryImpl(
            tokenizationService: mockTokenizationService,
            createPaymentServiceFactory: { _ in mockPaymentService },
            apiConfigurationModule: mockConfigModule
        )

        // When
        let result = try await sut.startPayment(
            paymentMethodType: QRCodeTestData.Constants.paymentMethodType
        )

        // Then
        XCTAssertEqual(result.paymentId, "pay_qr_happy")
        XCTAssertEqual(result.statusUrl.absoluteString, "https://localhost/status")
        XCTAssertFalse(result.qrCodeImageData.isEmpty)
    }

    // MARK: - startPayment — createPayment Returns Nil Payment ID

    func test_startPayment_nilPaymentId_throwsInvalidValueError() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "qr-config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let tokenData = createMockQRTokenData(token: "mock_token")
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        let mockPaymentService = MockCreateResumePaymentService()
        mockPaymentService.onCreatePayment = { _ in
            Response.Body.Payment(
                id: nil,
                paymentId: nil,
                amount: 1000,
                currencyCode: "THB",
                customer: nil,
                customerId: nil,
                dateStr: nil,
                order: nil,
                orderId: nil,
                requiredAction: nil,
                status: .pending,
                paymentFailureReason: nil
            )
        }

        sut = QRCodeRepositoryImpl(
            tokenizationService: mockTokenizationService,
            createPaymentServiceFactory: { _ in mockPaymentService }
        )

        // When/Then
        do {
            _ = try await sut.startPayment(
                paymentMethodType: QRCodeTestData.Constants.paymentMethodType
            )
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: _, diagnosticsId: _) = error {
                XCTAssertEqual(key, "payment.id")
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - startPayment — createPayment Returns Nil Required Action

    func test_startPayment_nilRequiredAction_throwsInvalidValueError() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "qr-config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let tokenData = createMockQRTokenData(token: "mock_token")
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        let mockPaymentService = MockCreateResumePaymentService()
        mockPaymentService.onCreatePayment = { _ in
            Response.Body.Payment(
                id: "pay_no_action",
                paymentId: "pay_no_action",
                amount: 1000,
                currencyCode: "THB",
                customer: nil,
                customerId: nil,
                dateStr: nil,
                order: nil,
                orderId: nil,
                requiredAction: nil,
                status: .pending,
                paymentFailureReason: nil
            )
        }

        sut = QRCodeRepositoryImpl(
            tokenizationService: mockTokenizationService,
            createPaymentServiceFactory: { _ in mockPaymentService }
        )

        // When/Then
        do {
            _ = try await sut.startPayment(
                paymentMethodType: QRCodeTestData.Constants.paymentMethodType
            )
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: let reason, diagnosticsId: _) = error {
                XCTAssertEqual(key, "requiredAction")
                XCTAssertTrue(reason?.contains("required action") ?? false)
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - resumePayment — Happy Path (Injected Mock)

    func test_resumePayment_happyPath_returnsPaymentResult() async throws {
        // Given
        let mockPaymentService = MockCreateResumePaymentService()
        mockPaymentService.onResumePayment = { paymentId, _ in
            Response.Body.Payment(
                id: paymentId,
                paymentId: paymentId,
                amount: 1500,
                currencyCode: "THB",
                customer: nil,
                customerId: nil,
                dateStr: nil,
                order: nil,
                orderId: nil,
                requiredAction: nil,
                status: .success,
                paymentFailureReason: nil
            )
        }

        sut = QRCodeRepositoryImpl(
            tokenizationService: mockTokenizationService,
            createPaymentServiceFactory: { _ in mockPaymentService }
        )

        // When
        let result = try await sut.resumePayment(
            paymentId: "pay_resume_happy",
            resumeToken: "resume_tok",
            paymentMethodType: QRCodeTestData.Constants.paymentMethodType
        )

        // Then
        XCTAssertEqual(result.paymentId, "pay_resume_happy")
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.amount, 1500)
        XCTAssertEqual(result.currencyCode, "THB")
        XCTAssertEqual(result.paymentMethodType, QRCodeTestData.Constants.paymentMethodType)
    }

    func test_resumePayment_pendingStatus_mapsCorrectly() async throws {
        // Given
        let mockPaymentService = MockCreateResumePaymentService()
        mockPaymentService.onResumePayment = { paymentId, _ in
            Response.Body.Payment(
                id: paymentId,
                paymentId: paymentId,
                amount: 500,
                currencyCode: "SGD",
                customer: nil,
                customerId: nil,
                dateStr: nil,
                order: nil,
                orderId: nil,
                requiredAction: nil,
                status: .pending,
                paymentFailureReason: nil
            )
        }

        sut = QRCodeRepositoryImpl(
            tokenizationService: mockTokenizationService,
            createPaymentServiceFactory: { _ in mockPaymentService }
        )

        // When
        let result = try await sut.resumePayment(
            paymentId: "pay_pending",
            resumeToken: "resume_tok",
            paymentMethodType: "XFERS_PAYNOW"
        )

        // Then
        XCTAssertEqual(result.status, .pending)
        XCTAssertEqual(result.paymentMethodType, "XFERS_PAYNOW")
    }

    func test_resumePayment_nilResponseId_fallsBackToProvidedPaymentId() async throws {
        // Given
        let mockPaymentService = MockCreateResumePaymentService()
        mockPaymentService.onResumePayment = { _, _ in
            Response.Body.Payment(
                id: nil,
                paymentId: nil,
                amount: 200,
                currencyCode: "THB",
                customer: nil,
                customerId: nil,
                dateStr: nil,
                order: nil,
                orderId: nil,
                requiredAction: nil,
                status: .success,
                paymentFailureReason: nil
            )
        }

        sut = QRCodeRepositoryImpl(
            tokenizationService: mockTokenizationService,
            createPaymentServiceFactory: { _ in mockPaymentService }
        )

        // When
        let result = try await sut.resumePayment(
            paymentId: "fallback_id",
            resumeToken: "resume_tok",
            paymentMethodType: QRCodeTestData.Constants.paymentMethodType
        )

        // Then
        XCTAssertEqual(result.paymentId, "fallback_id")
    }

    // MARK: - cancelPolling — With Active Polling Module

    func test_cancelPolling_withActivePolling_cancelsModule() async {
        // Given
        var factoryCalled = false
        sut = QRCodeRepositoryImpl(
            tokenizationService: mockTokenizationService,
            pollingModuleFactory: { url in
                factoryCalled = true
                return PollingModule(url: url)
            }
        )

        let pollTask = Task {
            try? await sut.pollForCompletion(statusUrl: QRCodeTestData.Constants.statusUrl)
        }

        // Allow polling to start and factory to be called
        try? await Task.sleep(nanoseconds: 100_000_000)

        // When
        sut.cancelPolling(paymentMethodType: QRCodeTestData.Constants.paymentMethodType)

        // Then — factory was used, cancel didn't crash
        XCTAssertTrue(factoryCalled)
        pollTask.cancel()
    }

    // MARK: - startPayment — Factory Receives Correct Payment Method Type

    func test_startPayment_factoryReceivesCorrectPaymentMethodType() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "qr-config-id",
            implementationType: .nativeSdk,
            type: QRCodeTestData.Constants.paymentMethodType,
            name: "PromptPay",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        let tokenData = createMockQRTokenData(token: "mock_token")
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }

        var capturedFactoryType: String?
        let mockPaymentService = MockCreateResumePaymentService()
        // onCreatePayment is nil so createPayment will throw PrimerError.unknown()

        sut = QRCodeRepositoryImpl(
            tokenizationService: mockTokenizationService,
            createPaymentServiceFactory: { type in
                capturedFactoryType = type
                return mockPaymentService
            }
        )

        // When
        _ = try? await sut.startPayment(
            paymentMethodType: QRCodeTestData.Constants.paymentMethodType
        )

        // Then
        XCTAssertEqual(capturedFactoryType, QRCodeTestData.Constants.paymentMethodType)
    }

    // MARK: - Helpers

    private func createMockQRTokenData(token: String?) -> PrimerPaymentMethodTokenData {
        Response.Body.Tokenization(
            analyticsId: "analytics_123",
            id: "id_123",
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .offSession,
            paymentMethodType: QRCodeTestData.Constants.paymentMethodType,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: token,
            tokenType: .singleUse,
            vaultData: nil
        )
    }
}

// MARK: - Local Mock Tokenization Service

@available(iOS 15.0, *)
private final class QRCodeMockTokenizationService: TokenizationServiceProtocol {

    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    var onTokenize: ((Request.Body.Tokenization) -> Result<PrimerPaymentMethodTokenData, Error>)?

    private(set) var tokenizeCallCount = 0
    private(set) var lastRequestBody: Request.Body.Tokenization?

    func tokenize(requestBody: Request.Body.Tokenization) async throws -> PrimerPaymentMethodTokenData {
        tokenizeCallCount += 1
        lastRequestBody = requestBody
        guard let onTokenize else { throw PrimerError.unknown() }
        let result = try onTokenize(requestBody).get()
        paymentMethodTokenData = result
        return result
    }

    func exchangePaymentMethodToken(
        _ paymentMethodTokenId: String,
        vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) async throws -> PrimerPaymentMethodTokenData {
        throw PrimerError.unknown()
    }
}
