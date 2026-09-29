//
//  PayPalRepositoryImplTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import AuthenticationServices
@testable import PrimerSDK
import XCTest
@_spi(PrimerInternal) @testable import PrimerNetworking
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
final class PayPalRepositoryImplTests: XCTestCase {

    private var mockPayPalService: MockPayPalService!
    private var mockWebAuthService: MockWebAuthenticationService!
    private var mockTokenizationService: MockTokenizationService!
    private var mockCreatePaymentService: MockCreateResumePaymentService!
    private var sut: PayPalRepositoryImpl!

    override func setUp() async throws {
        try await super.setUp()
        mockPayPalService = MockPayPalService()
        mockWebAuthService = MockWebAuthenticationService()
        mockTokenizationService = MockTokenizationService()
        mockCreatePaymentService = MockCreateResumePaymentService()

        // Registered before building sut, which reads PrimerSettings.current at init
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: "testapp://payment")
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)

        sut = PayPalRepositoryImpl(
            payPalService: mockPayPalService,
            webAuthService: mockWebAuthService,
            tokenizationService: mockTokenizationService,
            createPaymentService: mockCreatePaymentService
        )
    }

    override func tearDown() async throws {
        PrimerInternal.shared.intent = nil
        sut = nil
        mockPayPalService = nil
        mockWebAuthService = nil
        mockTokenizationService = nil
        mockCreatePaymentService = nil
        try await super.tearDown()
    }

    // MARK: - Mock Types

    private final class MockPayPalService: PayPalServiceProtocol {
        var startOrderSessionResult: Result<Response.Body.PayPal.CreateOrder, Error> = .success(
            Response.Body.PayPal.CreateOrder(orderId: "order-123", approvalUrl: "https://paypal.com/approve")
        )
        var startBillingAgreementSessionResult: Result<String, Error> = .success("https://paypal.com/billing")
        var confirmBillingAgreementResult: Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>!
        var fetchPayerInfoResult: Result<Response.Body.PayPal.PayerInfo, Error>!

        var startOrderSessionCalled = false
        var startBillingAgreementSessionCalled = false
        var confirmBillingAgreementCalled = false
        var fetchPayerInfoCalled = false
        var fetchPayerInfoOrderId: String?

        func startOrderSession(_ completion: @escaping (Result<Response.Body.PayPal.CreateOrder, Error>) -> Void) {
            startOrderSessionCalled = true
            completion(startOrderSessionResult)
        }

        func startOrderSession() async throws -> Response.Body.PayPal.CreateOrder {
            startOrderSessionCalled = true
            return try startOrderSessionResult.get()
        }

        func startBillingAgreementSession(_ completion: @escaping (Result<String, Error>) -> Void) {
            startBillingAgreementSessionCalled = true
            completion(startBillingAgreementSessionResult)
        }

        func startBillingAgreementSession() async throws -> String {
            startBillingAgreementSessionCalled = true
            return try startBillingAgreementSessionResult.get()
        }

        func confirmBillingAgreement(_ completion: @escaping (Result<Response.Body.PayPal.ConfirmBillingAgreement, Error>) -> Void) {
            confirmBillingAgreementCalled = true
            completion(confirmBillingAgreementResult)
        }

        func confirmBillingAgreement() async throws -> Response.Body.PayPal.ConfirmBillingAgreement {
            confirmBillingAgreementCalled = true
            return try confirmBillingAgreementResult.get()
        }

        func fetchPayPalExternalPayerInfo(orderId: String, completion: @escaping (Result<Response.Body.PayPal.PayerInfo, Error>) -> Void) {
            fetchPayerInfoCalled = true
            fetchPayerInfoOrderId = orderId
            completion(fetchPayerInfoResult)
        }

        func fetchPayPalExternalPayerInfo(orderId: String) async throws -> Response.Body.PayPal.PayerInfo {
            fetchPayerInfoCalled = true
            fetchPayerInfoOrderId = orderId
            return try fetchPayerInfoResult.get()
        }
    }

    private final class MockWebAuthenticationService: WebAuthenticationService {
        var session: ASWebAuthenticationSession? { nil }
        var connectResult: Result<URL, Error> = .success(URL(string: "testapp://callback")!)

        var connectCalled = false
        var connectURL: URL?
        var connectScheme: String?
        var connectPaymentMethodType: String?

        func connect(paymentMethodType: String, url: URL, scheme: String, _ completion: @escaping (Result<URL, Error>) -> Void) {
            connectCalled = true
            connectPaymentMethodType = paymentMethodType
            connectURL = url
            connectScheme = scheme
            completion(connectResult)
        }

        func connect(paymentMethodType: String, url: URL, scheme: String) async throws -> URL {
            connectCalled = true
            connectPaymentMethodType = paymentMethodType
            connectURL = url
            connectScheme = scheme
            return try connectResult.get()
        }
    }

    private final class MockTokenizationService: TokenizationServiceProtocol {
        var paymentMethodTokenData: PrimerPaymentMethodTokenData?

        var tokenizeResult: Result<PrimerPaymentMethodTokenData, Error>!
        var exchangeTokenResult: Result<PrimerPaymentMethodTokenData, Error>!

        var tokenizeCalled = false
        var tokenizeRequestBody: Request.Body.Tokenization?
        var exchangeTokenCalled = false

        func tokenize(requestBody: Request.Body.Tokenization) async throws -> PrimerPaymentMethodTokenData {
            tokenizeCalled = true
            tokenizeRequestBody = requestBody
            let result = try tokenizeResult.get()
            paymentMethodTokenData = result
            return result
        }

        func exchangePaymentMethodToken(_ paymentMethodTokenId: String, vaultedPaymentMethodAdditionalData: PrimerVaultedPaymentMethodAdditionalData?) async throws -> PrimerPaymentMethodTokenData {
            exchangeTokenCalled = true
            return try exchangeTokenResult.get()
        }
    }

    // MARK: - startOrderSession Tests

    func test_startOrderSession_returnsOrderIdAndApprovalUrl() async throws {
        // Given
        mockPayPalService.startOrderSessionResult = .success(
            Response.Body.PayPal.CreateOrder(orderId: "custom-order", approvalUrl: "https://custom.url")
        )

        // When
        let result = try await sut.startOrderSession()

        // Then
        XCTAssertEqual(result.orderId, "custom-order")
        XCTAssertEqual(result.approvalUrl, "https://custom.url")
    }

    func test_startOrderSession_propagatesError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 100, userInfo: nil)
        mockPayPalService.startOrderSessionResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.startOrderSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 100)
        }
    }

    // MARK: - startBillingAgreementSession Tests

    func test_startBillingAgreementSession_returnsApprovalUrl() async throws {
        // Given
        mockPayPalService.startBillingAgreementSessionResult = .success("https://custom-billing.url")

        // When
        let result = try await sut.startBillingAgreementSession()

        // Then
        XCTAssertEqual(result, "https://custom-billing.url")
    }

    func test_startBillingAgreementSession_propagatesError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 200, userInfo: nil)
        mockPayPalService.startBillingAgreementSessionResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.startBillingAgreementSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 200)
        }
    }

    // MARK: - openWebAuthentication Tests

    func test_openWebAuthentication_callsWebAuthService() async throws {
        // Given
        let testURL = URL(string: "https://paypal.com/approve")!

        // When
        let result = try await sut.openWebAuthentication(url: testURL)

        // Then
        XCTAssertTrue(mockWebAuthService.connectCalled)
        XCTAssertEqual(mockWebAuthService.connectURL, testURL)
        XCTAssertEqual(mockWebAuthService.connectPaymentMethodType, PrimerPaymentMethodType.payPal.rawValue)
        XCTAssertEqual(mockWebAuthService.connectScheme, "testapp")
        XCTAssertEqual(result, URL(string: "testapp://callback")!)
    }

    func test_openWebAuthentication_returnsCallbackUrl() async throws {
        // Given
        let testURL = URL(string: "https://paypal.com/test")!
        mockWebAuthService.connectResult = .success(URL(string: "customapp://success")!)

        // When
        let result = try await sut.openWebAuthentication(url: testURL)

        // Then
        XCTAssertEqual(result, URL(string: "customapp://success")!)
    }

    func test_openWebAuthentication_propagatesError() async {
        // Given
        let testURL = URL(string: "https://paypal.com/test")!
        let expectedError = NSError(domain: "test", code: 300, userInfo: nil)
        mockWebAuthService.connectResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.openWebAuthentication(url: testURL)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 300)
        }
    }

    func test_openWebAuthentication_mapsUserCancellationToCancelledError() async {
        // Given
        let testURL = URL(string: "https://paypal.com/test")!
        mockWebAuthService.connectResult = .failure(ASWebAuthenticationSessionError(.canceledLogin))

        // When/Then - dismissing the browser sheet must surface as PrimerError.cancelled
        do {
            _ = try await sut.openWebAuthentication(url: testURL)
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            guard case .cancelled = error else {
                return XCTFail("Expected PrimerError.cancelled, got \(error)")
            }
        } catch {
            XCTFail("Expected PrimerError.cancelled, got \(error)")
        }
    }

    func test_openWebAuthentication_payPalCancelCallback_throwsCancelled() async {
        // Given - PayPal's "Cancel and return" link completes the session with the cancel URL
        mockWebAuthService.connectResult = .success(URL(string: "testapp://paypal-cancel")!)

        // When/Then
        await assertThrowsCancelled { try await sut.openWebAuthentication(url: URL(string: "https://paypal.com/approve")!) }
    }

    func test_openWebAuthentication_payPalCancelCallbackWithQuery_throwsCancelled() async {
        // Given
        mockWebAuthService.connectResult = .success(URL(string: "testapp://paypal-cancel?token=EC-123")!)

        // When/Then
        await assertThrowsCancelled { try await sut.openWebAuthentication(url: URL(string: "https://paypal.com/approve")!) }
    }

    func test_openWebAuthentication_payPalSuccessCallback_returnsUrl() async throws {
        // Given
        let callbackURL = URL(string: "testapp://paypal-success?token=EC-123")!
        mockWebAuthService.connectResult = .success(callbackURL)

        // When
        let result = try await sut.openWebAuthentication(url: URL(string: "https://paypal.com/approve")!)

        // Then
        XCTAssertEqual(result, callbackURL)
    }

    // MARK: - Cancel callback through the interactor

    func test_cancelCallback_checkoutFlow_stopsBeforeFetchingPayerInfo() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        mockWebAuthService.connectResult = .success(URL(string: "testapp://paypal-cancel")!)
        mockPayPalService.fetchPayerInfoResult = .failure(NSError(domain: "test", code: 400))
        var createPaymentCalled = false
        mockCreatePaymentService.onCreatePayment = { _ in
            createPaymentCalled = true
            return nil
        }
        let interactor = ProcessPayPalPaymentInteractorImpl(repository: sut)

        // When/Then
        await assertThrowsCancelled { try await interactor.execute() }
        XCTAssertFalse(mockPayPalService.fetchPayerInfoCalled)
        XCTAssertFalse(mockTokenizationService.tokenizeCalled)
        XCTAssertFalse(createPaymentCalled)
    }

    func test_cancelCallback_vaultFlow_stopsBeforeConfirmingBillingAgreement() async {
        // Given
        PrimerInternal.shared.intent = .vault
        mockWebAuthService.connectResult = .success(URL(string: "testapp://paypal-cancel")!)
        mockPayPalService.confirmBillingAgreementResult = .failure(NSError(domain: "test", code: 400))
        let interactor = ProcessPayPalPaymentInteractorImpl(repository: sut)

        // When/Then
        await assertThrowsCancelled { try await interactor.execute() }
        XCTAssertFalse(mockPayPalService.confirmBillingAgreementCalled)
        XCTAssertFalse(mockTokenizationService.tokenizeCalled)
    }

    // MARK: - confirmBillingAgreement Tests

    func test_confirmBillingAgreement_mapsShippingAddress() async throws {
        // Given
        let externalPayerInfo = Response.Body.Tokenization.PayPal.ExternalPayerInfo(
            externalPayerId: "payer-123",
            email: "test@example.com",
            firstName: nil,
            lastName: "User"
        )
        let shippingAddress = Response.Body.Tokenization.PayPal.ShippingAddress(
            firstName: "John",
            lastName: "Doe",
            addressLine1: "123 Main St",
            addressLine2: "Apt 4",
            city: "San Francisco",
            state: "CA",
            countryCode: "US",
            postalCode: "94102"
        )
        mockPayPalService.confirmBillingAgreementResult = .success(
            Response.Body.PayPal.ConfirmBillingAgreement(
                billingAgreementId: "ba-456",
                externalPayerInfo: externalPayerInfo,
                shippingAddress: shippingAddress
            )
        )

        // When
        let result = try await sut.confirmBillingAgreement()

        // Then
        XCTAssertEqual(result.shippingAddress?.firstName, "John")
        XCTAssertEqual(result.shippingAddress?.lastName, "Doe")
        XCTAssertEqual(result.shippingAddress?.addressLine1, "123 Main St")
        XCTAssertEqual(result.shippingAddress?.city, "San Francisco")
        XCTAssertEqual(result.shippingAddress?.state, "CA")
        XCTAssertEqual(result.shippingAddress?.countryCode, "US")
        XCTAssertEqual(result.shippingAddress?.postalCode, "94102")
    }

    func test_confirmBillingAgreement_propagatesError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 400, userInfo: nil)
        mockPayPalService.confirmBillingAgreementResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.confirmBillingAgreement()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 400)
        }
    }

    func test_fetchPayerInfo_propagatesError() async {
        // Given
        let expectedError = NSError(domain: "test", code: 500, userInfo: nil)
        mockPayPalService.fetchPayerInfoResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.fetchPayerInfo(orderId: "order-123")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 500)
        }
    }

    // MARK: - tokenize Tests

    func test_tokenize_withBillingAgreementPaymentInstrument_callsTokenizationService() async throws {
        // Given
        let billingResult = PayPalBillingAgreementResult(
            billingAgreementId: "ba-789",
            externalPayerInfo: PayPalPayerInfo(
                externalPayerId: "payer-abc",
                email: "billing@example.com",
                firstName: "Billing",
                lastName: "User"
            ),
            shippingAddress: nil
        )
        let paymentInstrument = PayPalPaymentInstrumentData.billingAgreement(result: billingResult)

        mockTokenizationService.tokenizeResult = .success(createMockTokenData(id: "token-billing"))

        // When
        let result = try await sut.tokenize(paymentInstrument: paymentInstrument)

        // Then
        XCTAssertTrue(mockTokenizationService.tokenizeCalled)
        XCTAssertEqual(result.paymentId, "token-billing")
        XCTAssertEqual(result.status, PaymentStatus.success)
    }

    func test_tokenize_returnsTokenFromResponse() async throws {
        // Given
        let paymentInstrument = PayPalPaymentInstrumentData.order(orderId: "order-123", payerInfo: nil)
        mockTokenizationService.tokenizeResult = .success(createMockTokenData(id: "id-abc", token: "token-xyz"))

        // When
        let result = try await sut.tokenize(paymentInstrument: paymentInstrument)

        // Then
        XCTAssertEqual(result.token, "token-xyz")
    }

    func test_tokenize_propagatesError() async {
        // Given
        let paymentInstrument = PayPalPaymentInstrumentData.order(orderId: "order-123", payerInfo: nil)
        let expectedError = NSError(domain: "test", code: 600, userInfo: nil)
        mockTokenizationService.tokenizeResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.tokenize(paymentInstrument: paymentInstrument)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 600)
        }
    }

    func test_tokenize_withOrderPaymentInstrumentAndPayerInfo_callsTokenizationService() async throws {
        // Given
        let payerInfo = PayPalPayerInfo(
            externalPayerId: "payer-xyz",
            email: "order@example.com",
            firstName: "Order",
            lastName: "Payer"
        )
        let paymentInstrument = PayPalPaymentInstrumentData.order(orderId: "order-456", payerInfo: payerInfo)
        mockTokenizationService.tokenizeResult = .success(createMockTokenData(id: "token-order", token: "tok-order"))

        // When
        let result = try await sut.tokenize(paymentInstrument: paymentInstrument)

        // Then
        XCTAssertTrue(mockTokenizationService.tokenizeCalled)
        XCTAssertEqual(result.paymentId, "token-order")
        XCTAssertEqual(result.paymentMethodType, PrimerPaymentMethodType.payPal.rawValue)
    }

    func test_tokenize_withBillingAgreementAndShippingAddress_mapsAllFields() async throws {
        // Given
        let billingResult = PayPalBillingAgreementResult(
            billingAgreementId: "ba-full",
            externalPayerInfo: PayPalPayerInfo(
                externalPayerId: "payer-full",
                email: "full@example.com",
                firstName: "Full",
                lastName: "Payer"
            ),
            shippingAddress: PayPalShippingAddress(
                firstName: "Ship",
                lastName: "To",
                addressLine1: "456 Oak Ave",
                addressLine2: nil,
                city: "Portland",
                state: "OR",
                countryCode: "US",
                postalCode: "97201"
            )
        )
        let paymentInstrument = PayPalPaymentInstrumentData.billingAgreement(result: billingResult)
        mockTokenizationService.tokenizeResult = .success(createMockTokenData(id: "token-full"))

        // When
        let result = try await sut.tokenize(paymentInstrument: paymentInstrument)

        // Then
        XCTAssertTrue(mockTokenizationService.tokenizeCalled)
        XCTAssertEqual(result.paymentId, "token-full")
        let instrument = mockTokenizationService.tokenizeRequestBody?.paymentInstrument as? PayPalPaymentInstrument
        XCTAssertEqual(instrument?.paypalBillingAgreementId, "ba-full")
        XCTAssertNotNil(instrument?.shippingAddress)
        XCTAssertNotNil(instrument?.externalPayerInfo)
    }

    func test_tokenize_generatesUUIDWhenIdIsNil() async throws {
        // Given
        let paymentInstrument = PayPalPaymentInstrumentData.order(orderId: "order-123", payerInfo: nil)
        mockTokenizationService.tokenizeResult = .success(createMockTokenData(id: nil))

        // When
        let result = try await sut.tokenize(paymentInstrument: paymentInstrument)

        // Then
        XCTAssertNotNil(result.paymentId)
        XCTAssertFalse(result.paymentId.isEmpty)
    }

    // MARK: - createPayment Tests

    func test_createPayment_sendsTokenAndMapsPayment() async throws {
        // Given
        var sentToken: String?
        mockCreatePaymentService.onCreatePayment = { request in
            sentToken = request.paymentMethodToken
            return Response.Body.Payment(
                id: "pay_paypal",
                paymentId: "pay_paypal",
                amount: 50,
                currencyCode: "GBP",
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

        // When
        let result = try await sut.createPayment(token: "tok_paypal")

        // Then
        XCTAssertEqual(sentToken, "tok_paypal")
        XCTAssertEqual(result.paymentId, "pay_paypal")
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.token, "tok_paypal")
        XCTAssertEqual(result.amount, 50)
        XCTAssertEqual(result.paymentMethodType, PrimerPaymentMethodType.payPal.rawValue)
    }

    func test_createPayment_propagatesError() async {
        // Given: the mock throws when `onCreatePayment` is unset

        // When/Then
        do {
            _ = try await sut.createPayment(token: "tok_paypal")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
        }
    }

    // MARK: - Helpers

    private func assertThrowsCancelled<T>(
        _ operation: () async throws -> T,
        file: StaticString = #filePath,
        line: UInt = #line
    ) async {
        do {
            _ = try await operation()
            XCTFail("Expected PrimerError.cancelled", file: file, line: line)
        } catch let PrimerError.cancelled(paymentMethodType, _) {
            XCTAssertEqual(paymentMethodType, PrimerPaymentMethodType.payPal.rawValue, file: file, line: line)
        } catch {
            XCTFail("Expected PrimerError.cancelled, got \(error)", file: file, line: line)
        }
    }

    private func createMockTokenData(id: String?, token: String? = nil) -> PrimerPaymentMethodTokenData {
        Response.Body.Tokenization(
            analyticsId: "analytics-123",
            id: id,
            isVaulted: false,
            isAlreadyVaulted: false,
            paymentInstrumentType: .payPalOrder,
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            paymentInstrumentData: nil,
            threeDSecureAuthentication: nil,
            token: token,
            tokenType: nil,
            vaultData: nil
        )
    }
}
