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
