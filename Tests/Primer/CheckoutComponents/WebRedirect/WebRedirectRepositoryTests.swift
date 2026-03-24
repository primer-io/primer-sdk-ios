//
//  WebRedirectRepositoryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import AuthenticationServices
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class WebRedirectRepositoryTests: XCTestCase {

    private var mockTokenizationService: MockTokenizationService!
    private var mockWebAuthService: MockWebAuthenticationService!
    private var mockCreatePaymentService: MockCreateResumePaymentService!
    private var sut: WebRedirectRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockTokenizationService = MockTokenizationService()
        mockWebAuthService = MockWebAuthenticationService()
        mockCreatePaymentService = MockCreateResumePaymentService()
        sut = WebRedirectRepositoryImpl(
            tokenizationService: mockTokenizationService,
            webAuthService: mockWebAuthService,
            createPaymentService: mockCreatePaymentService
        )

        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "testapp://payment")
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    override func tearDown() {
        sut = nil
        mockTokenizationService = nil
        mockWebAuthService = nil
        mockCreatePaymentService = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - resumePayment — No Prior Tokenization

    func test_resumePayment_withoutPriorTokenization_throwsError() async {
        // Given - no tokenize call made, so no payment ID stored

        // When/Then
        do {
            _ = try await sut.resumePayment(paymentMethodType: "ADYEN_SOFORT", resumeToken: "token")
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: let reason, diagnosticsId: _) = error {
                XCTAssertEqual(key, "resumePaymentId")
                XCTAssertTrue(reason?.contains("Tokenization must be called first") ?? false)
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - tokenize — Missing Configuration

    func test_tokenize_noPaymentMethodConfig_throwsInvalidValueError() async {
        // Given - no matching payment methods
        SDKSessionHelper.setUp(withPaymentMethods: [])
        let sessionInfo = WebRedirectSessionInfo(locale: "en")

        // When/Then
        do {
            _ = try await sut.tokenize(paymentMethodType: "ADYEN_SOFORT", sessionInfo: sessionInfo)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: _, diagnosticsId: _) = error {
                XCTAssertEqual(key, "paymentMethodType")
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_tokenize_paymentMethodWithNilId_throwsInvalidValueError() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: nil,
            implementationType: .webRedirect,
            type: "ADYEN_SOFORT",
            name: "Sofort",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])
        let sessionInfo = WebRedirectSessionInfo(locale: "en")

        // When/Then
        do {
            _ = try await sut.tokenize(paymentMethodType: "ADYEN_SOFORT", sessionInfo: sessionInfo)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: _, diagnosticsId: _) = error {
                XCTAssertEqual(key, "paymentMethodType")
            } else {
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - tokenize — Tokenization Service Failure

    func test_tokenize_tokenizationServiceFails_propagatesError() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "sofort-config-id",
            implementationType: .webRedirect,
            type: "ADYEN_SOFORT",
            name: "Sofort",
            processorConfigId: "processor-1",
            surcharge: nil,
            options: nil,
            displayMetadata: nil
        )
        SDKSessionHelper.setUp(withPaymentMethods: [paymentMethod])

        mockTokenizationService.onTokenize = { _ in .failure(PrimerError.invalidClientToken()) }
        let sessionInfo = WebRedirectSessionInfo(locale: "en")

        // When/Then
        do {
            _ = try await sut.tokenize(paymentMethodType: "ADYEN_SOFORT", sessionInfo: sessionInfo)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - tokenize — Nil Token in Response

    func test_tokenize_nilTokenInResponse_throwsInvalidValueError() async {
        // Given
        let paymentMethod = PrimerPaymentMethod(
            id: "sofort-config-id",
            implementationType: .webRedirect,
            type: "ADYEN_SOFORT",
            name: "Sofort",
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
            paymentMethodType: "ADYEN_SOFORT",
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: nil,
            tokenType: .singleUse,
            vaultData: nil
        )
        mockTokenizationService.onTokenize = { _ in .success(tokenData) }
        let sessionInfo = WebRedirectSessionInfo(locale: "en")

        // When/Then
        do {
            _ = try await sut.tokenize(paymentMethodType: "ADYEN_SOFORT", sessionInfo: sessionInfo)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: _, diagnosticsId: _) = error {
                XCTAssertEqual(key, "paymentMethodTokenData.token")
            } else {
                XCTFail("Expected invalidValue error for nil token, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - openWebAuthentication — HTTPS URLs

    func test_openWebAuthentication_httpsUrl_callsWebAuthService() async throws {
        // Given
        let testURL = URL(string: "https://redirect.example.com/pay")!
        mockWebAuthService.onConnect = { url, _ in URL(string: "testapp://callback")! }

        // When
        let result = try await sut.openWebAuthentication(paymentMethodType: "ADYEN_SOFORT", url: testURL)

        // Then
        XCTAssertEqual(result, URL(string: "testapp://callback")!)
    }

    func test_openWebAuthentication_httpsUrl_webAuthServiceFails_propagatesError() async {
        // Given
        let testURL = URL(string: "https://redirect.example.com/pay")!
        mockWebAuthService.onConnect = nil

        // When/Then
        do {
            _ = try await sut.openWebAuthentication(paymentMethodType: "ADYEN_SOFORT", url: testURL)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - cancelPolling

    func test_cancelPolling_noActivePoll_doesNotCrash() {
        // Given - no polling started

        // When/Then - should not crash
        sut.cancelPolling(paymentMethodType: "ADYEN_SOFORT")
    }

    func test_cancelPolling_calledMultipleTimes_doesNotCrash() {
        // Given - no polling started

        // When/Then
        sut.cancelPolling(paymentMethodType: "ADYEN_SOFORT")
        sut.cancelPolling(paymentMethodType: "ADYEN_SOFORT")
    }

    // MARK: - resumePayment — Multiple Calls

    func test_resumePayment_withDifferentPaymentMethodTypes_throwsWithoutTokenization() async {
        // Given - no prior tokenization

        // When/Then - different payment method types should all fail
        for paymentMethodType in ["ADYEN_SOFORT", "ADYEN_TWINT", "ADYEN_IDEAL"] {
            do {
                _ = try await sut.resumePayment(paymentMethodType: paymentMethodType, resumeToken: "token")
                XCTFail("Expected error for \(paymentMethodType)")
            } catch let error as PrimerError {
                if case .invalidValue(key: let key, value: _, reason: _, diagnosticsId: _) = error {
                    XCTAssertEqual(key, "resumePaymentId")
                } else {
                    XCTFail("Expected invalidValue error, got: \(error)")
                }
            } catch {
                XCTFail("Unexpected error type: \(error)")
            }
        }
    }
}
