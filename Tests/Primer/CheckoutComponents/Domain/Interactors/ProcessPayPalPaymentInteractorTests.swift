//
//  ProcessPayPalPaymentInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

/// Tests for ProcessPayPalPaymentInteractor.
@available(iOS 15.0, *)
final class ProcessPayPalPaymentInteractorTests: XCTestCase {

    private var mockRepository: MockPayPalRepository!
    private var sut: ProcessPayPalPaymentInteractorImpl!

    override func setUp() async throws {
        try await super.setUp()
        mockRepository = MockPayPalRepository()
        sut = ProcessPayPalPaymentInteractorImpl(repository: mockRepository)
    }

    override func tearDown() async throws {
        PrimerInternal.shared.intent = nil
        mockRepository = nil
        sut = nil
        try await super.tearDown()
    }

    // MARK: - Mock Repository

    private final class MockPayPalRepository: PayPalRepository {
        var startOrderSessionResult: Result<(orderId: String, approvalUrl: String), Error> = .success(("order-123", "https://paypal.com/approve"))
        var startBillingAgreementSessionResult: Result<String, Error> = .success("https://paypal.com/billing")
        var openWebAuthenticationResult: Result<URL, Error> = .success(URL(string: "https://callback.com")!)
        var confirmBillingAgreementResult: Result<PayPalBillingAgreementResult, Error> = .success(
            PayPalBillingAgreementResult(
                billingAgreementId: "ba-123",
                externalPayerInfo: nil,
                shippingAddress: nil
            )
        )
        var fetchPayerInfoResult: Result<PayPalPayerInfo, Error> = .success(
            PayPalPayerInfo(
                externalPayerId: "payer-123",
                email: "test@example.com",
                firstName: "John",
                lastName: "Doe"
            )
        )
        var tokenizeResult: Result<PaymentResult, Error> = .success(
            PaymentResult(paymentId: "payment-123", status: .success)
        )

        var startOrderSessionCalled = false
        var startBillingAgreementSessionCalled = false
        var openWebAuthenticationCalled = false
        var openWebAuthenticationURL: URL?
        var confirmBillingAgreementCalled = false
        var fetchPayerInfoCalled = false
        var fetchPayerInfoOrderId: String?
        var tokenizeCalled = false
        var tokenizePaymentInstrument: PayPalPaymentInstrumentData?

        func startOrderSession() async throws -> (orderId: String, approvalUrl: String) {
            startOrderSessionCalled = true
            return try startOrderSessionResult.get()
        }

        func startBillingAgreementSession() async throws -> String {
            startBillingAgreementSessionCalled = true
            return try startBillingAgreementSessionResult.get()
        }

        func openWebAuthentication(url: URL) async throws -> URL {
            openWebAuthenticationCalled = true
            openWebAuthenticationURL = url
            return try openWebAuthenticationResult.get()
        }

        func confirmBillingAgreement() async throws -> PayPalBillingAgreementResult {
            confirmBillingAgreementCalled = true
            return try confirmBillingAgreementResult.get()
        }

        func fetchPayerInfo(orderId: String) async throws -> PayPalPayerInfo {
            fetchPayerInfoCalled = true
            fetchPayerInfoOrderId = orderId
            return try fetchPayerInfoResult.get()
        }

        func tokenize(paymentInstrument: PayPalPaymentInstrumentData) async throws -> PaymentResult {
            tokenizeCalled = true
            tokenizePaymentInstrument = paymentInstrument
            return try tokenizeResult.get()
        }
    }

    // MARK: - Checkout Flow Tests

    func test_execute_withCheckoutIntent_executesCheckoutFlow() async throws {
        // Given
        PrimerInternal.shared.intent = .checkout

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(mockRepository.startOrderSessionCalled)
        XCTAssertTrue(mockRepository.openWebAuthenticationCalled)
        XCTAssertTrue(mockRepository.fetchPayerInfoCalled)
        XCTAssertTrue(mockRepository.tokenizeCalled)
        XCTAssertFalse(mockRepository.startBillingAgreementSessionCalled)
        XCTAssertFalse(mockRepository.confirmBillingAgreementCalled)
        XCTAssertEqual(result.paymentId, "payment-123")
        XCTAssertEqual(result.status, .success)
    }

    func test_execute_withNilIntent_executesCheckoutFlow() async throws {
        // Given
        PrimerInternal.shared.intent = nil

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(mockRepository.startOrderSessionCalled)
        XCTAssertTrue(mockRepository.openWebAuthenticationCalled)
        XCTAssertTrue(mockRepository.fetchPayerInfoCalled)
        XCTAssertTrue(mockRepository.tokenizeCalled)
        XCTAssertEqual(result.paymentId, "payment-123")
    }

    func test_execute_checkoutFlow_passesCorrectOrderIdToFetchPayerInfo() async throws {
        // Given
        PrimerInternal.shared.intent = .checkout
        mockRepository.startOrderSessionResult = .success(("custom-order-id", "https://paypal.com/approve"))

        // When
        _ = try await sut.execute()

        // Then
        XCTAssertEqual(mockRepository.fetchPayerInfoOrderId, "custom-order-id")
    }

    func test_execute_checkoutFlow_passesCorrectURLToWebAuthentication() async throws {
        // Given
        PrimerInternal.shared.intent = .checkout
        mockRepository.startOrderSessionResult = .success(("order-123", "https://paypal.com/custom-approve"))

        // When
        _ = try await sut.execute()

        // Then
        XCTAssertEqual(mockRepository.openWebAuthenticationURL?.absoluteString, "https://paypal.com/custom-approve")
    }

    func test_execute_checkoutFlow_tokenizesWithOrderPaymentInstrument() async throws {
        // Given
        PrimerInternal.shared.intent = .checkout
        mockRepository.startOrderSessionResult = .success(("order-456", "https://paypal.com/approve"))
        let expectedPayerInfo = PayPalPayerInfo(
            externalPayerId: "payer-xyz",
            email: "user@test.com",
            firstName: "Jane",
            lastName: "Smith"
        )
        mockRepository.fetchPayerInfoResult = .success(expectedPayerInfo)

        // When
        _ = try await sut.execute()

        // Then
        guard case let .order(orderId, payerInfo) = mockRepository.tokenizePaymentInstrument else {
            XCTFail("Expected order payment instrument")
            return
        }
        XCTAssertEqual(orderId, "order-456")
        XCTAssertEqual(payerInfo?.email, "user@test.com")
        XCTAssertEqual(payerInfo?.firstName, "Jane")
    }

    // MARK: - Vault Flow Tests

    func test_execute_withVaultIntent_executesVaultFlow() async throws {
        // Given
        PrimerInternal.shared.intent = .vault

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(mockRepository.startBillingAgreementSessionCalled)
        XCTAssertTrue(mockRepository.openWebAuthenticationCalled)
        XCTAssertTrue(mockRepository.confirmBillingAgreementCalled)
        XCTAssertTrue(mockRepository.tokenizeCalled)
        XCTAssertFalse(mockRepository.startOrderSessionCalled)
        XCTAssertFalse(mockRepository.fetchPayerInfoCalled)
        XCTAssertEqual(result.paymentId, "payment-123")
        XCTAssertEqual(result.status, .success)
    }

    func test_execute_vaultFlow_passesCorrectURLToWebAuthentication() async throws {
        // Given
        PrimerInternal.shared.intent = .vault
        mockRepository.startBillingAgreementSessionResult = .success("https://paypal.com/vault-approval")

        // When
        _ = try await sut.execute()

        // Then
        XCTAssertEqual(mockRepository.openWebAuthenticationURL?.absoluteString, "https://paypal.com/vault-approval")
    }

    func test_execute_vaultFlow_tokenizesWithBillingAgreementPaymentInstrument() async throws {
        // Given
        PrimerInternal.shared.intent = .vault
        let expectedResult = PayPalBillingAgreementResult(
            billingAgreementId: "ba-789",
            externalPayerInfo: PayPalPayerInfo(
                externalPayerId: "vault-payer",
                email: "vault@test.com",
                firstName: "Vault",
                lastName: "User"
            ),
            shippingAddress: nil
        )
        mockRepository.confirmBillingAgreementResult = .success(expectedResult)

        // When
        _ = try await sut.execute()

        // Then
        guard case let .billingAgreement(result) = mockRepository.tokenizePaymentInstrument else {
            XCTFail("Expected billing agreement payment instrument")
            return
        }
        XCTAssertEqual(result.billingAgreementId, "ba-789")
        XCTAssertEqual(result.externalPayerInfo?.email, "vault@test.com")
    }

    // MARK: - Error Handling Tests

    func test_execute_checkoutFlow_throwsErrorForInvalidApprovalURL() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        // Empty string produces nil from URL(string:)
        mockRepository.startOrderSessionResult = .success(("order-123", ""))

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "approvalUrl")
            default:
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Expected PrimerError, got: \(error)")
        }
    }

    func test_execute_vaultFlow_throwsErrorForInvalidApprovalURL() async {
        // Given
        PrimerInternal.shared.intent = .vault
        mockRepository.startBillingAgreementSessionResult = .success("")

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch let error as PrimerError {
            switch error {
            case let .invalidValue(key, _, _, _):
                XCTAssertEqual(key, "approvalUrl")
            default:
                XCTFail("Expected invalidValue error, got: \(error)")
            }
        } catch {
            XCTFail("Expected PrimerError, got: \(error)")
        }
    }

    func test_execute_checkoutFlow_propagatesStartOrderSessionError() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        let expectedError = NSError(domain: "test", code: 100, userInfo: nil)
        mockRepository.startOrderSessionResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 100)
        }
    }

    func test_execute_checkoutFlow_propagatesWebAuthenticationError() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        let expectedError = NSError(domain: "test", code: 200, userInfo: nil)
        mockRepository.openWebAuthenticationResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 200)
        }
    }

    func test_execute_checkoutFlow_propagatesFetchPayerInfoError() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        let expectedError = NSError(domain: "test", code: 300, userInfo: nil)
        mockRepository.fetchPayerInfoResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 300)
        }
    }

    func test_execute_checkoutFlow_propagatesTokenizeError() async {
        // Given
        PrimerInternal.shared.intent = .checkout
        let expectedError = NSError(domain: "test", code: 400, userInfo: nil)
        mockRepository.tokenizeResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 400)
        }
    }

    func test_execute_vaultFlow_propagatesStartBillingAgreementError() async {
        // Given
        PrimerInternal.shared.intent = .vault
        let expectedError = NSError(domain: "test", code: 500, userInfo: nil)
        mockRepository.startBillingAgreementSessionResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 500)
        }
    }

    func test_execute_vaultFlow_propagatesConfirmBillingAgreementError() async {
        // Given
        PrimerInternal.shared.intent = .vault
        let expectedError = NSError(domain: "test", code: 600, userInfo: nil)
        mockRepository.confirmBillingAgreementResult = .failure(expectedError)

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 600)
        }
    }

    // MARK: - Payment Status Tests

    func test_execute_returnsCorrectPaymentStatus_pending() async throws {
        // Given
        PrimerInternal.shared.intent = .checkout
        mockRepository.tokenizeResult = .success(PaymentResult(paymentId: "pending-payment", status: .pending))

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.status, .pending)
    }

    func test_execute_returnsCorrectPaymentStatus_requires3DS() async throws {
        // Given
        PrimerInternal.shared.intent = .checkout
        mockRepository.tokenizeResult = .success(PaymentResult(paymentId: "3ds-payment", status: .requires3DS))

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.status, .requires3DS)
    }

    func test_execute_returnsFullPaymentResult() async throws {
        // Given
        PrimerInternal.shared.intent = .checkout
        let testMetadata: [String: Any] = ["key": "value"]
        mockRepository.tokenizeResult = .success(PaymentResult(
            paymentId: "full-payment",
            status: .success,
            token: "token-abc",
            redirectUrl: "https://redirect.com",
            errorMessage: nil,
            metadata: testMetadata,
            amount: 1000,
            currencyCode: "USD",
            paymentMethodType: "PAYPAL"
        ))

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.paymentId, "full-payment")
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.token, "token-abc")
        XCTAssertEqual(result.redirectUrl, "https://redirect.com")
        XCTAssertEqual(result.amount, 1000)
        XCTAssertEqual(result.currencyCode, "USD")
        XCTAssertEqual(result.paymentMethodType, "PAYPAL")
    }
}
