//
//  AdyenKlarnaRepositoryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import AuthenticationServices
@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class AdyenKlarnaRepositoryTests: XCTestCase {

    private var mockAPIClient: MockPrimerAPIClient!
    private var mockTokenizationService: MockTokenizationService!
    private var mockCreatePaymentService: MockCreateResumePaymentService!
    private var mockWebAuthService: StubWebAuthService!
    private var sut: AdyenKlarnaRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockAPIClient = MockPrimerAPIClient()
        mockTokenizationService = MockTokenizationService()
        mockCreatePaymentService = MockCreateResumePaymentService()
        mockWebAuthService = StubWebAuthService()

        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "testapp://payment")
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        sut = AdyenKlarnaRepositoryImpl(
            apiClient: mockAPIClient,
            tokenizationService: mockTokenizationService,
            webAuthService: mockWebAuthService,
            createPaymentServiceFactory: { [mockCreatePaymentService] _ in mockCreatePaymentService! }
        )
    }

    override func tearDown() {
        sut = nil
        mockAPIClient = nil
        mockTokenizationService = nil
        mockCreatePaymentService = nil
        mockWebAuthService = nil
        SDKSessionHelper.tearDown()
        super.tearDown()
    }

    // MARK: - fetchPaymentOptions

    func test_fetchPaymentOptions_success_returnsOptions() async throws {
        // Given
        let response = AdyenKlarnaPaymentOptionsResponse(result: [
            AdyenKlarnaPaymentOptionDTO(id: "pay_later", name: "Pay Later"),
            AdyenKlarnaPaymentOptionDTO(id: "pay_now", name: "Pay Now"),
        ])
        mockAPIClient.listAdyenKlarnaPaymentTypesResult = (response, nil)
        SDKSessionHelper.setUp(withPaymentMethods: [makeAdyenKlarnaPaymentMethod()])

        // When
        let options = try await sut.fetchPaymentOptions(configId: "test-config-id")

        // Then
        XCTAssertEqual(options.count, 2)
        XCTAssertEqual(options[0].id, "pay_later")
        XCTAssertEqual(options[0].name, "Pay Later")
        XCTAssertEqual(options[1].id, "pay_now")
    }

    func test_fetchPaymentOptions_noClientToken_throwsError() async {
        do {
            _ = try await sut.fetchPaymentOptions(configId: "test-config-id")
            XCTFail("Expected error")
        } catch let error as PrimerError {
            if case .invalidClientToken = error {} else {
                XCTFail("Expected invalidClientToken, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_fetchPaymentOptions_apiError_throws() async {
        // Given
        SDKSessionHelper.setUp(withPaymentMethods: [makeAdyenKlarnaPaymentMethod()])
        mockAPIClient.listAdyenKlarnaPaymentTypesResult = (nil, NSError(domain: "test", code: 1))

        // When/Then
        do {
            _ = try await sut.fetchPaymentOptions(configId: "test-config-id")
            XCTFail("Expected error")
        } catch {
            // Expected
        }
    }

    func test_fetchPaymentOptions_emptyResult_returnsEmptyArray() async throws {
        // Given
        let response = AdyenKlarnaPaymentOptionsResponse(result: [])
        mockAPIClient.listAdyenKlarnaPaymentTypesResult = (response, nil)
        SDKSessionHelper.setUp(withPaymentMethods: [makeAdyenKlarnaPaymentMethod()])

        // When
        let options = try await sut.fetchPaymentOptions(configId: "test-config-id")

        // Then
        XCTAssertTrue(options.isEmpty)
    }

    // MARK: - tokenize

    func test_tokenize_noPaymentMethodConfig_throwsInvalidValue() async {
        // Given
        let sessionInfo = AdyenKlarnaSessionInfo(locale: "en", paymentMethodType: "PAY_LATER")

        // When/Then
        do {
            _ = try await sut.tokenize(paymentMethodType: "ADYEN_KLARNA", sessionInfo: sessionInfo)
            XCTFail("Expected error")
        } catch let error as PrimerError {
            if case let .invalidValue(key, _, _, _) = error {
                XCTAssertEqual(key, "paymentMethodType")
            } else {
                XCTFail("Expected invalidValue, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_tokenize_nilToken_throwsError() async {
        // Given
        SDKSessionHelper.setUp(withPaymentMethods: [makeAdyenKlarnaPaymentMethod()])
        mockTokenizationService.onTokenize = { _ in .success(self.makeTokenData(token: nil)) }
        let sessionInfo = AdyenKlarnaSessionInfo(locale: "en", paymentMethodType: "PAY_LATER")

        // When/Then
        do {
            _ = try await sut.tokenize(paymentMethodType: "ADYEN_KLARNA", sessionInfo: sessionInfo)
            XCTFail("Expected error")
        } catch let error as PrimerError {
            if case let .invalidValue(key, _, _, _) = error {
                XCTAssertEqual(key, "paymentMethodTokenData.token")
            } else {
                XCTFail("Expected invalidValue, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_tokenize_noRequiredAction_throwsError() async {
        // Given
        SDKSessionHelper.setUp(withPaymentMethods: [makeAdyenKlarnaPaymentMethod()])
        mockTokenizationService.onTokenize = { _ in .success(self.makeTokenData(token: "test-token")) }
        mockCreatePaymentService.onCreatePayment = { _ in self.makePaymentResponse(requiredAction: nil) }
        let sessionInfo = AdyenKlarnaSessionInfo(locale: "en", paymentMethodType: "PAY_LATER")

        // When/Then
        do {
            _ = try await sut.tokenize(paymentMethodType: "ADYEN_KLARNA", sessionInfo: sessionInfo)
            XCTFail("Expected error")
        } catch let error as PrimerError {
            if case let .invalidValue(key, _, _, _) = error {
                XCTAssertEqual(key, "paymentResponse.requiredAction")
            } else {
                XCTFail("Expected invalidValue, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_tokenize_fullSuccess_returnsUrls() async throws {
        // Given
        SDKSessionHelper.setUp(withPaymentMethods: [makeAdyenKlarnaPaymentMethod()])
        mockTokenizationService.onTokenize = { _ in .success(self.makeTokenData(token: "test-token")) }
        mockCreatePaymentService.onCreatePayment = { _ in
            self.makePaymentResponse(requiredAction: Response.Body.Payment.RequiredAction(
                clientToken: MockAppState.mockClientTokenWithRedirect,
                name: .checkout,
                description: "redirect"
            ))
        }
        let sessionInfo = AdyenKlarnaSessionInfo(locale: "en", paymentMethodType: "PAY_LATER")

        // When
        let result = try await sut.tokenize(paymentMethodType: "ADYEN_KLARNA", sessionInfo: sessionInfo)

        // Then
        XCTAssertEqual(result.redirectUrl.absoluteString, "https://localhost/redirect")
        XCTAssertEqual(result.statusUrl.absoluteString, "https://localhost/status")
    }

    // MARK: - openWebAuthentication

    func test_openWebAuthentication_webUrl_callsWebAuthService() async throws {
        // Given
        let url = URL(string: "https://klarna.com/redirect")!

        // When
        let result = try await sut.openWebAuthentication(paymentMethodType: "ADYEN_KLARNA", url: url)

        // Then
        XCTAssertEqual(result.absoluteString, "testapp://callback")
        XCTAssertTrue(mockWebAuthService.connectCalled)
    }

    // MARK: - resumePayment

    func test_resumePayment_withoutPriorTokenization_throwsError() async {
        do {
            _ = try await sut.resumePayment(paymentMethodType: "ADYEN_KLARNA", resumeToken: "token")
            XCTFail("Expected error")
        } catch let error as PrimerError {
            if case .invalidValue(key: let key, value: _, reason: let reason, diagnosticsId: _) = error {
                XCTAssertEqual(key, "resumePaymentId")
                XCTAssertTrue(reason?.contains("Tokenization must be called first") ?? false)
            } else {
                XCTFail("Expected invalidValue, got: \(error)")
            }
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_resumePayment_afterTokenize_returnsResult() async throws {
        // Given - tokenize first to set resumePaymentId
        SDKSessionHelper.setUp(withPaymentMethods: [makeAdyenKlarnaPaymentMethod()])
        mockTokenizationService.onTokenize = { _ in .success(self.makeTokenData(token: "test-token")) }
        mockCreatePaymentService.onCreatePayment = { _ in
            self.makePaymentResponse(requiredAction: Response.Body.Payment.RequiredAction(
                clientToken: MockAppState.mockClientTokenWithRedirect,
                name: .checkout,
                description: "redirect"
            ))
        }
        _ = try await sut.tokenize(
            paymentMethodType: "ADYEN_KLARNA",
            sessionInfo: AdyenKlarnaSessionInfo(locale: "en", paymentMethodType: "PAY_LATER")
        )

        mockCreatePaymentService.onResumePayment = { paymentId, _ in
            XCTAssertEqual(paymentId, "pay-123")
            return Response.Body.Payment(
                id: "pay-123", paymentId: "pay-123", amount: 1000, currencyCode: "EUR",
                customerId: nil, orderId: nil, status: .success
            )
        }

        // When
        let result = try await sut.resumePayment(paymentMethodType: "ADYEN_KLARNA", resumeToken: "resume-token")

        // Then
        XCTAssertEqual(result.paymentId, "pay-123")
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.amount, 1000)
        XCTAssertEqual(result.currencyCode, "EUR")
    }

    // MARK: - cancelPolling

    func test_cancelPolling_doesNotCrash() {
        sut.cancelPolling(paymentMethodType: "ADYEN_KLARNA")
    }

    // MARK: - Helpers

    private func makeAdyenKlarnaPaymentMethod() -> PrimerPaymentMethod {
        PrimerPaymentMethod(
            id: "adyen-klarna-config-id", implementationType: .nativeSdk,
            type: "ADYEN_KLARNA", name: "Adyen Klarna",
            processorConfigId: "adyen-klarna-processor",
            surcharge: nil, options: nil, displayMetadata: nil
        )
    }

    private func makeTokenData(token: String?) -> PrimerPaymentMethodTokenData {
        PrimerPaymentMethodTokenData(
            analyticsId: "test", id: "test", isVaulted: false, isAlreadyVaulted: false,
            paymentInstrumentType: .unknown, paymentMethodType: "ADYEN_KLARNA",
            paymentInstrumentData: nil, threeDSecureAuthentication: nil,
            token: token, tokenType: .singleUse, vaultData: nil
        )
    }

    private func makePaymentResponse(requiredAction: Response.Body.Payment.RequiredAction?) -> Response.Body.Payment {
        Response.Body.Payment(
            id: "pay-123", paymentId: "pay-123", amount: 1000, currencyCode: "EUR",
            customerId: nil, orderId: nil, requiredAction: requiredAction, status: .pending
        )
    }
}

// MARK: - Stub

@available(iOS 15.0, *)
private final class StubWebAuthService: WebAuthenticationService {
    var session: ASWebAuthenticationSession?
    private(set) var connectCalled = false

    func connect(paymentMethodType: String, url: URL, scheme: String, _ completion: @escaping (Result<URL, Error>) -> Void) {
        connectCalled = true
        completion(.success(URL(string: "testapp://callback")!))
    }

    @MainActor
    func connect(paymentMethodType: String, url: URL, scheme: String) async throws -> URL {
        connectCalled = true
        return URL(string: "testapp://callback")!
    }
}
