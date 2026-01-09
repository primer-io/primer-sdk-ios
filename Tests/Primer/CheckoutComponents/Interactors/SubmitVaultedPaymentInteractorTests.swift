//
//  SubmitVaultedPaymentInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class SubmitVaultedPaymentInteractorTests: XCTestCase {

    // MARK: - Success Tests

    func testExecute_Success_ReturnsPaymentResult() async throws {
        // Given
        let expectedResult = PaymentResult(
            paymentId: "pay_123",
            status: .success,
            token: "token_abc",
            paymentMethodType: "PAYMENT_CARD"
        )
        let repository = SpyHeadlessRepository()
        await repository.setProcessVaultedPaymentResult(.success(expectedResult))
        let interactor = SubmitVaultedPaymentInteractorImpl(repository: repository)

        // When
        let result = try await interactor.execute(
            vaultedPaymentMethodId: "vault_456",
            paymentMethodType: "PAYMENT_CARD",
            additionalData: nil
        )

        // Then
        XCTAssertEqual(result.paymentId, expectedResult.paymentId)
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.paymentMethodType, "PAYMENT_CARD")
    }

    func testExecute_WithAdditionalData_PassesDataToRepository() async throws {
        // Given
        let repository = SpyHeadlessRepository()
        await repository.setProcessVaultedPaymentResult(.success(PaymentResult(
            paymentId: "pay_123",
            status: .success
        )))
        let interactor = SubmitVaultedPaymentInteractorImpl(repository: repository)
        let cvvData = PrimerVaultedCardAdditionalData(cvv: "123")

        // When
        _ = try await interactor.execute(
            vaultedPaymentMethodId: "vault_789",
            paymentMethodType: "PAYMENT_CARD",
            additionalData: cvvData
        )

        // Then
        let call = try await repository.nextProcessVaultedPaymentCall()
        XCTAssertEqual(call.vaultedPaymentMethodId, "vault_789")
        XCTAssertEqual(call.paymentMethodType, "PAYMENT_CARD")
        XCTAssertNotNil(call.additionalData)
    }

    func testExecute_PassesCorrectParametersToRepository() async throws {
        // Given
        let repository = SpyHeadlessRepository()
        await repository.setProcessVaultedPaymentResult(.success(PaymentResult(
            paymentId: "pay_123",
            status: .success
        )))
        let interactor = SubmitVaultedPaymentInteractorImpl(repository: repository)

        // When
        _ = try await interactor.execute(
            vaultedPaymentMethodId: "vault_abc",
            paymentMethodType: "PAYPAL",
            additionalData: nil
        )

        // Then
        let call = try await repository.nextProcessVaultedPaymentCall()
        XCTAssertEqual(call.vaultedPaymentMethodId, "vault_abc")
        XCTAssertEqual(call.paymentMethodType, "PAYPAL")
        XCTAssertNil(call.additionalData)
    }

    // MARK: - Error Tests

    func testExecute_RepositoryThrows_PropagatesError() async throws {
        // Given
        let expectedError = NSError(domain: "TestError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Payment failed"])
        let repository = SpyHeadlessRepository()
        await repository.setProcessVaultedPaymentResult(.failure(expectedError))
        let interactor = SubmitVaultedPaymentInteractorImpl(repository: repository)

        // When/Then
        do {
            _ = try await interactor.execute(
                vaultedPaymentMethodId: "vault_error",
                paymentMethodType: "PAYMENT_CARD",
                additionalData: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "TestError")
            XCTAssertEqual((error as NSError).code, 500)
        }
    }

    // MARK: - Multiple Calls Tests

    func testExecute_MultipleCalls_EachCallsRepository() async throws {
        // Given
        let repository = SpyHeadlessRepository()
        await repository.setProcessVaultedPaymentResult(.success(PaymentResult(
            paymentId: "pay_123",
            status: .success
        )))
        let interactor = SubmitVaultedPaymentInteractorImpl(repository: repository)

        // When
        _ = try await interactor.execute(
            vaultedPaymentMethodId: "vault_1",
            paymentMethodType: "PAYMENT_CARD",
            additionalData: nil
        )
        _ = try await interactor.execute(
            vaultedPaymentMethodId: "vault_2",
            paymentMethodType: "PAYPAL",
            additionalData: nil
        )

        // Then
        let call1 = try await repository.nextProcessVaultedPaymentCall()
        let call2 = try await repository.nextProcessVaultedPaymentCall()

        XCTAssertEqual(call1.vaultedPaymentMethodId, "vault_1")
        XCTAssertEqual(call2.vaultedPaymentMethodId, "vault_2")
    }
}

// MARK: - Spy HeadlessRepository

@available(iOS 15.0, *)
private actor SpyHeadlessRepository: HeadlessRepository {

    struct ProcessVaultedPaymentCall {
        let vaultedPaymentMethodId: String
        let paymentMethodType: String
        let additionalData: PrimerVaultedPaymentMethodAdditionalData?
    }

    private var processVaultedPaymentResult: Result<PaymentResult, Error> = .success(PaymentResult(paymentId: "", status: .success))
    private var processVaultedPaymentCalls: [ProcessVaultedPaymentCall] = []

    private enum WaitError: Error {
        case timeout
    }

    func setProcessVaultedPaymentResult(_ result: Result<PaymentResult, Error>) {
        processVaultedPaymentResult = result
    }

    func nextProcessVaultedPaymentCall(timeout: TimeInterval = 1) async throws -> ProcessVaultedPaymentCall {
        let deadline = Date().addingTimeInterval(timeout)
        while processVaultedPaymentCalls.isEmpty {
            if Date() > deadline {
                throw WaitError.timeout
            }
            try? await Task.sleep(nanoseconds: 5_000_000)
        }
        return processVaultedPaymentCalls.removeFirst()
    }

    // MARK: - HeadlessRepository Protocol - Vault Methods

    func processVaultedPayment(
        vaultedPaymentMethodId: String,
        paymentMethodType: String,
        additionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) async throws -> PaymentResult {
        processVaultedPaymentCalls.append(ProcessVaultedPaymentCall(
            vaultedPaymentMethodId: vaultedPaymentMethodId,
            paymentMethodType: paymentMethodType,
            additionalData: additionalData
        ))

        switch processVaultedPaymentResult {
        case let .success(result):
            return result
        case let .failure(error):
            throw error
        }
    }

    func fetchVaultedPaymentMethods() async throws -> [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] {
        []
    }

    func deleteVaultedPaymentMethod(_ id: String) async throws {}

    // MARK: - HeadlessRepository Protocol - Other Methods (stubs)

    func getPaymentMethods() async throws -> [InternalPaymentMethod] { [] }

    func processCardPayment(
        cardNumber: String,
        cvv: String,
        expiryMonth: String,
        expiryYear: String,
        cardholderName: String,
        selectedNetwork: CardNetwork?
    ) async throws -> PaymentResult {
        PaymentResult(paymentId: "", status: .success)
    }

    func setBillingAddress(_ billingAddress: BillingAddress) async throws {}

    nonisolated func getNetworkDetectionStream() -> AsyncStream<[CardNetwork]> {
        AsyncStream { _ in }
    }

    func updateCardNumberInRawDataManager(_ cardNumber: String) async {}

    func selectCardNetwork(_ cardNetwork: CardNetwork) async {}
}
