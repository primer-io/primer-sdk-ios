//
//  PayPalRepositoryImplTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import AuthenticationServices
import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class PayPalRepositoryImplTests: XCTestCase {

    private var mockPayPalService: MockPayPalService!
    private var mockWebAuthService: MockWebAuthenticationService!
    private var mockTokenizationService: MockTokenizationService!
    private var sut: PayPalRepositoryImpl!

    override func setUp() async throws {
        try await super.setUp()
        mockPayPalService = MockPayPalService()
        mockWebAuthService = MockWebAuthenticationService()
        mockTokenizationService = MockTokenizationService()
        sut = PayPalRepositoryImpl(
            payPalService: mockPayPalService,
            webAuthService: mockWebAuthService,
            tokenizationService: mockTokenizationService
        )

        // Set up PrimerSettings with valid URL scheme for tests
        let settings = PrimerSettings(
            paymentMethodOptions: PrimerPaymentMethodOptions(urlScheme: TestData.PaymentMethodOptions.testAppUrl)
        )
        DependencyContainer.register(settings as PrimerSettingsProtocol)
    }

    override func tearDown() async throws {
        sut = nil
        mockPayPalService = nil
        mockWebAuthService = nil
        mockTokenizationService = nil
        try await super.tearDown()
    }

    // MARK: - Mock Types

    private final class MockPayPalService: PayPalServiceProtocol {
        var startOrderSessionResult: Result<Response.Body.PayPal.CreateOrder, Error> = .success(
            Response.Body.PayPal.CreateOrder(orderId: TestData.PayPal.orderId, approvalUrl: TestData.PayPal.approvalUrl)
        )
        var startBillingAgreementSessionResult: Result<String, Error> = .success(TestData.PayPal.billingUrl)
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
        var connectResult: Result<URL, Error> = .success(URL(string: TestData.PayPal.callbackUrl)!)

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

    func test_startOrderSession_callsPayPalService() async throws {
        // When
        let result = try await sut.startOrderSession()

        // Then
        XCTAssertTrue(mockPayPalService.startOrderSessionCalled)
        XCTAssertEqual(result.orderId, TestData.PayPal.orderId)
        XCTAssertEqual(result.approvalUrl, TestData.PayPal.approvalUrl)
    }

    func test_startOrderSession_returnsOrderIdAndApprovalUrl() async throws {
        // Given
        mockPayPalService.startOrderSessionResult = .success(
            Response.Body.PayPal.CreateOrder(orderId: TestData.PayPal.customOrderId, approvalUrl: TestData.PayPal.customUrl)
        )

        // When
        let result = try await sut.startOrderSession()

        // Then
        XCTAssertEqual(result.orderId, TestData.PayPal.customOrderId)
        XCTAssertEqual(result.approvalUrl, TestData.PayPal.customUrl)
    }

    func test_startOrderSession_propagatesError() async {
        // Given
        let expectedError = NSError(domain: TestData.ErrorDomains.test, code: TestData.ErrorCodes.code100, userInfo: nil)
        mockPayPalService.startOrderSessionResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.startOrderSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, TestData.ErrorCodes.code100)
        }
    }

    // MARK: - startBillingAgreementSession Tests

    func test_startBillingAgreementSession_callsPayPalService() async throws {
        // When
        let result = try await sut.startBillingAgreementSession()

        // Then
        XCTAssertTrue(mockPayPalService.startBillingAgreementSessionCalled)
        XCTAssertEqual(result, TestData.PayPal.billingUrl)
    }

    func test_startBillingAgreementSession_returnsApprovalUrl() async throws {
        // Given
        mockPayPalService.startBillingAgreementSessionResult = .success(TestData.PayPal.customBillingUrl)

        // When
        let result = try await sut.startBillingAgreementSession()

        // Then
        XCTAssertEqual(result, TestData.PayPal.customBillingUrl)
    }

    func test_startBillingAgreementSession_propagatesError() async {
        // Given
        let expectedError = NSError(domain: TestData.ErrorDomains.test, code: TestData.ErrorCodes.code200, userInfo: nil)
        mockPayPalService.startBillingAgreementSessionResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.startBillingAgreementSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, TestData.ErrorCodes.code200)
        }
    }

    // MARK: - openWebAuthentication Tests

    func test_openWebAuthentication_callsWebAuthService() async throws {
        // Given
        let testURL = URL(string: TestData.PayPal.approvalUrl)!

        // When
        let result = try await sut.openWebAuthentication(url: testURL)

        // Then
        XCTAssertTrue(mockWebAuthService.connectCalled)
        XCTAssertEqual(mockWebAuthService.connectURL, testURL)
        XCTAssertEqual(mockWebAuthService.connectPaymentMethodType, PrimerPaymentMethodType.payPal.rawValue)
        XCTAssertEqual(mockWebAuthService.connectScheme, TestData.PaymentMethodOptions.testAppScheme)
        XCTAssertEqual(result, URL(string: TestData.PayPal.callbackUrl)!)
    }

    func test_openWebAuthentication_returnsCallbackUrl() async throws {
        // Given
        let testURL = URL(string: TestData.PayPal.testUrl)!
        mockWebAuthService.connectResult = .success(URL(string: TestData.PayPal.customSuccessUrl)!)

        // When
        let result = try await sut.openWebAuthentication(url: testURL)

        // Then
        XCTAssertEqual(result, URL(string: TestData.PayPal.customSuccessUrl)!)
    }

    func test_openWebAuthentication_propagatesError() async {
        // Given
        let testURL = URL(string: TestData.PayPal.testUrl)!
        let expectedError = NSError(domain: TestData.ErrorDomains.test, code: TestData.ErrorCodes.code300, userInfo: nil)
        mockWebAuthService.connectResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.openWebAuthentication(url: testURL)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, TestData.ErrorCodes.code300)
        }
    }

    // MARK: - confirmBillingAgreement Tests

    func test_confirmBillingAgreement_callsPayPalService() async throws {
        // Given
        let externalPayerInfo = Response.Body.Tokenization.PayPal.ExternalPayerInfo(
            externalPayerId: TestData.PayPal.payerId,
            email: TestData.EmailAddresses.valid,
            firstName: TestData.PersonNames.firstName,
            lastName: TestData.PersonNames.lastName
        )
        mockPayPalService.confirmBillingAgreementResult = .success(
            Response.Body.PayPal.ConfirmBillingAgreement(
                billingAgreementId: TestData.PayPal.billingAgreementId,
                externalPayerInfo: externalPayerInfo,
                shippingAddress: nil
            )
        )

        // When
        let result = try await sut.confirmBillingAgreement()

        // Then
        XCTAssertTrue(mockPayPalService.confirmBillingAgreementCalled)
        XCTAssertEqual(result.billingAgreementId, TestData.PayPal.billingAgreementId)
        XCTAssertEqual(result.externalPayerInfo?.email, TestData.EmailAddresses.valid)
        XCTAssertEqual(result.externalPayerInfo?.firstName, TestData.PersonNames.firstName)
        XCTAssertEqual(result.externalPayerInfo?.lastName, TestData.PersonNames.lastName)
    }

    func test_confirmBillingAgreement_mapsShippingAddress() async throws {
        // Given
        let externalPayerInfo = Response.Body.Tokenization.PayPal.ExternalPayerInfo(
            externalPayerId: TestData.PayPal.payerId,
            email: TestData.EmailAddresses.valid,
            firstName: nil,
            lastName: TestData.PersonNames.singleLastName
        )
        let shippingAddress = Response.Body.Tokenization.PayPal.ShippingAddress(
            firstName: TestData.PersonNames.firstName,
            lastName: TestData.PersonNames.lastName,
            addressLine1: TestData.Addresses.line1,
            addressLine2: TestData.Addresses.line2,
            city: TestData.Addresses.city,
            state: TestData.Addresses.state,
            countryCode: TestData.Addresses.countryCode,
            postalCode: TestData.Addresses.postalCode
        )
        mockPayPalService.confirmBillingAgreementResult = .success(
            Response.Body.PayPal.ConfirmBillingAgreement(
                billingAgreementId: TestData.PayPal.billingAgreementId456,
                externalPayerInfo: externalPayerInfo,
                shippingAddress: shippingAddress
            )
        )

        // When
        let result = try await sut.confirmBillingAgreement()

        // Then
        XCTAssertEqual(result.shippingAddress?.firstName, TestData.PersonNames.firstName)
        XCTAssertEqual(result.shippingAddress?.lastName, TestData.PersonNames.lastName)
        XCTAssertEqual(result.shippingAddress?.addressLine1, TestData.Addresses.line1)
        XCTAssertEqual(result.shippingAddress?.city, TestData.Addresses.city)
        XCTAssertEqual(result.shippingAddress?.state, TestData.Addresses.state)
        XCTAssertEqual(result.shippingAddress?.countryCode, TestData.Addresses.countryCode)
        XCTAssertEqual(result.shippingAddress?.postalCode, TestData.Addresses.postalCode)
    }

    func test_confirmBillingAgreement_propagatesError() async {
        // Given
        let expectedError = NSError(domain: TestData.ErrorDomains.test, code: TestData.ErrorCodes.code400, userInfo: nil)
        mockPayPalService.confirmBillingAgreementResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.confirmBillingAgreement()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, TestData.ErrorCodes.code400)
        }
    }

    // MARK: - fetchPayerInfo Tests

    func test_fetchPayerInfo_callsPayPalServiceWithOrderId() async throws {
        // Given
        let externalPayerInfo = Response.Body.Tokenization.PayPal.ExternalPayerInfo(
            externalPayerId: TestData.PayPal.payerIdXyz,
            email: TestData.EmailAddresses.validWithSubdomain,
            firstName: TestData.PersonNames.firstNameAlt,
            lastName: TestData.PersonNames.lastNameAlt
        )
        mockPayPalService.fetchPayerInfoResult = .success(
            Response.Body.PayPal.PayerInfo(orderId: TestData.PayPal.orderIdAbc, externalPayerInfo: externalPayerInfo)
        )

        // When
        let result = try await sut.fetchPayerInfo(orderId: TestData.PayPal.orderIdAbc)

        // Then
        XCTAssertTrue(mockPayPalService.fetchPayerInfoCalled)
        XCTAssertEqual(mockPayPalService.fetchPayerInfoOrderId, TestData.PayPal.orderIdAbc)
        XCTAssertEqual(result.email, TestData.EmailAddresses.validWithSubdomain)
        XCTAssertEqual(result.firstName, TestData.PersonNames.firstNameAlt)
        XCTAssertEqual(result.lastName, TestData.PersonNames.lastNameAlt)
        XCTAssertEqual(result.externalPayerId, TestData.PayPal.payerIdXyz)
    }

    func test_fetchPayerInfo_propagatesError() async {
        // Given
        let expectedError = NSError(domain: TestData.ErrorDomains.test, code: TestData.ErrorCodes.code500, userInfo: nil)
        mockPayPalService.fetchPayerInfoResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.fetchPayerInfo(orderId: TestData.PayPal.orderId)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, TestData.ErrorCodes.code500)
        }
    }

    // MARK: - tokenize Tests

    func test_tokenize_withOrderPaymentInstrument_callsTokenizationService() async throws {
        // Given
        let payerInfo = PayPalPayerInfo(
            externalPayerId: TestData.PayPal.payerId,
            email: TestData.EmailAddresses.valid,
            firstName: TestData.PersonNames.firstName,
            lastName: TestData.PersonNames.lastName
        )
        let paymentInstrument = PayPalPaymentInstrumentData.order(orderId: TestData.PayPal.billingAgreementId456, payerInfo: payerInfo)

        mockTokenizationService.tokenizeResult = .success(createMockTokenData(id: TestData.PayPal.tokenId))

        // When
        let result = try await sut.tokenize(paymentInstrument: paymentInstrument)

        // Then
        XCTAssertTrue(mockTokenizationService.tokenizeCalled)
        XCTAssertEqual(result.paymentId, TestData.PayPal.tokenId)
        XCTAssertEqual(result.status, PaymentStatus.success)
        XCTAssertEqual(result.paymentMethodType, PrimerPaymentMethodType.payPal.rawValue)
    }

    func test_tokenize_withBillingAgreementPaymentInstrument_callsTokenizationService() async throws {
        // Given
        let billingResult = PayPalBillingAgreementResult(
            billingAgreementId: TestData.PayPal.billingAgreementId789,
            externalPayerInfo: PayPalPayerInfo(
                externalPayerId: TestData.PayPal.payerIdAbc,
                email: TestData.EmailAddresses.validWithPlus,
                firstName: TestData.PersonNames.billingFirstName,
                lastName: TestData.PersonNames.billingLastName
            ),
            shippingAddress: nil
        )
        let paymentInstrument = PayPalPaymentInstrumentData.billingAgreement(result: billingResult)

        mockTokenizationService.tokenizeResult = .success(createMockTokenData(id: TestData.PayPal.tokenBilling))

        // When
        let result = try await sut.tokenize(paymentInstrument: paymentInstrument)

        // Then
        XCTAssertTrue(mockTokenizationService.tokenizeCalled)
        XCTAssertEqual(result.paymentId, TestData.PayPal.tokenBilling)
        XCTAssertEqual(result.status, PaymentStatus.success)
    }

    func test_tokenize_returnsTokenFromResponse() async throws {
        // Given
        let paymentInstrument = PayPalPaymentInstrumentData.order(orderId: TestData.PayPal.orderId, payerInfo: nil)
        mockTokenizationService.tokenizeResult = .success(createMockTokenData(id: TestData.PayPal.tokenIdAbc, token: TestData.PayPal.tokenXyz))

        // When
        let result = try await sut.tokenize(paymentInstrument: paymentInstrument)

        // Then
        XCTAssertEqual(result.token, TestData.PayPal.tokenXyz)
    }

    func test_tokenize_propagatesError() async {
        // Given
        let paymentInstrument = PayPalPaymentInstrumentData.order(orderId: TestData.PayPal.orderId, payerInfo: nil)
        let expectedError = NSError(domain: TestData.ErrorDomains.test, code: TestData.ErrorCodes.code600, userInfo: nil)
        mockTokenizationService.tokenizeResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.tokenize(paymentInstrument: paymentInstrument)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, TestData.ErrorCodes.code600)
        }
    }

    func test_tokenize_generatesUUIDWhenIdIsNil() async throws {
        // Given
        let paymentInstrument = PayPalPaymentInstrumentData.order(orderId: TestData.PayPal.orderId, payerInfo: nil)
        mockTokenizationService.tokenizeResult = .success(createMockTokenData(id: nil))

        // When
        let result = try await sut.tokenize(paymentInstrument: paymentInstrument)

        // Then
        XCTAssertNotNil(result.paymentId)
        XCTAssertFalse(result.paymentId.isEmpty)
    }

    // MARK: - Helpers

    private func createMockTokenData(id: String?, token: String? = nil) -> PrimerPaymentMethodTokenData {
        Response.Body.Tokenization(
            analyticsId: TestData.Analytics.analyticsId,
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
