//
//  HeadlessRepositoryTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

// MARK: - Mock HeadlessRepository for Testing

/// A mock implementation of HeadlessRepository for testing vault operations.
/// This allows testing components that depend on HeadlessRepository without
/// requiring actual network calls or SDK initialization.
@available(iOS 15.0, *)
actor VaultMockHeadlessRepository: HeadlessRepository {

    // MARK: - Vault Method Stubs

    private var fetchVaultedPaymentMethodsResult: Result<[PrimerHeadlessUniversalCheckout.VaultedPaymentMethod], Error> = .success([])
    private var processVaultedPaymentResult: Result<PaymentResult, Error> = .success(PaymentResult(paymentId: "", status: .success))
    private var deleteVaultedPaymentMethodResult: Result<Void, Error> = .success(())

    // MARK: - Call Tracking

    private(set) var fetchVaultedPaymentMethodsCalls: Int = 0
    private(set) var processVaultedPaymentCalls: [(id: String, type: String, additionalData: PrimerVaultedPaymentMethodAdditionalData?)] = []
    private(set) var deleteVaultedPaymentMethodCalls: [String] = []

    // MARK: - Configuration Methods

    func setFetchVaultedPaymentMethodsResult(_ result: Result<[PrimerHeadlessUniversalCheckout.VaultedPaymentMethod], Error>) {
        fetchVaultedPaymentMethodsResult = result
    }

    func setProcessVaultedPaymentResult(_ result: Result<PaymentResult, Error>) {
        processVaultedPaymentResult = result
    }

    func setDeleteVaultedPaymentMethodResult(_ result: Result<Void, Error>) {
        deleteVaultedPaymentMethodResult = result
    }

    // MARK: - Vault Protocol Methods

    func fetchVaultedPaymentMethods() async throws -> [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] {
        fetchVaultedPaymentMethodsCalls += 1
        switch fetchVaultedPaymentMethodsResult {
        case let .success(methods):
            return methods
        case let .failure(error):
            throw error
        }
    }

    func processVaultedPayment(
        vaultedPaymentMethodId: String,
        paymentMethodType: String,
        additionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) async throws -> PaymentResult {
        processVaultedPaymentCalls.append((vaultedPaymentMethodId, paymentMethodType, additionalData))
        switch processVaultedPaymentResult {
        case let .success(result):
            return result
        case let .failure(error):
            throw error
        }
    }

    func deleteVaultedPaymentMethod(_ id: String) async throws {
        deleteVaultedPaymentMethodCalls.append(id)
        switch deleteVaultedPaymentMethodResult {
        case .success:
            return
        case let .failure(error):
            throw error
        }
    }

    // MARK: - Other Protocol Methods (stubs)

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

// MARK: - Fetch Vaulted Payment Methods Tests

@available(iOS 15.0, *)
final class FetchVaultedPaymentMethodsTests: XCTestCase {

    func testFetchVaultedPaymentMethods_Success_ReturnsVaultedMethods() async throws {
        // Given
        let repository = VaultMockHeadlessRepository()
        let expectedMethods = createMockVaultedMethods()
        await repository.setFetchVaultedPaymentMethodsResult(.success(expectedMethods))

        // When
        let result = try await repository.fetchVaultedPaymentMethods()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "vault_card_1")
        XCTAssertEqual(result[1].id, "vault_paypal_1")
    }

    func testFetchVaultedPaymentMethods_EmptyList_ReturnsEmptyArray() async throws {
        // Given
        let repository = VaultMockHeadlessRepository()
        await repository.setFetchVaultedPaymentMethodsResult(.success([]))

        // When
        let result = try await repository.fetchVaultedPaymentMethods()

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func testFetchVaultedPaymentMethods_Error_ThrowsError() async {
        // Given
        let repository = VaultMockHeadlessRepository()
        let expectedError = NSError(domain: "TestError", code: 404, userInfo: [NSLocalizedDescriptionKey: "Not found"])
        await repository.setFetchVaultedPaymentMethodsResult(.failure(expectedError))

        // When/Then
        do {
            _ = try await repository.fetchVaultedPaymentMethods()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 404)
        }
    }

    func testFetchVaultedPaymentMethods_TracksCalls() async throws {
        // Given
        let repository = VaultMockHeadlessRepository()

        // When
        _ = try await repository.fetchVaultedPaymentMethods()
        _ = try await repository.fetchVaultedPaymentMethods()

        // Then
        let callCount = await repository.fetchVaultedPaymentMethodsCalls
        XCTAssertEqual(callCount, 2)
    }

    // MARK: - Helper Methods

    private func createMockVaultedMethods() -> [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] {
        let cardInstrumentData = createPaymentInstrumentData(
            last4Digits: "4242",
            expirationMonth: "12",
            expirationYear: "2026",
            network: "Visa"
        )

        let paypalInstrumentData = createPaymentInstrumentData(
            externalPayerInfo: ["email": "test@example.com"]
        )

        return [
            PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
                id: "vault_card_1",
                paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
                paymentInstrumentType: .paymentCard,
                paymentInstrumentData: cardInstrumentData,
                analyticsId: "analytics_1"
            ),
            PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
                id: "vault_paypal_1",
                paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
                paymentInstrumentType: .payPalBillingAgreement,
                paymentInstrumentData: paypalInstrumentData,
                analyticsId: "analytics_2"
            )
        ]
    }

    private func createPaymentInstrumentData(
        last4Digits: String? = nil,
        expirationMonth: String? = nil,
        expirationYear: String? = nil,
        network: String? = nil,
        externalPayerInfo: [String: Any]? = nil
    ) -> Response.Body.Tokenization.PaymentInstrumentData {
        var json: [String: Any] = [:]
        if let last4Digits { json["last4Digits"] = last4Digits }
        if let expirationMonth { json["expirationMonth"] = expirationMonth }
        if let expirationYear { json["expirationYear"] = expirationYear }
        if let network { json["network"] = network }
        if let externalPayerInfo { json["externalPayerInfo"] = externalPayerInfo }

        let data = try! JSONSerialization.data(withJSONObject: json) // swiftlint:disable:this force_try
        return try! JSONDecoder().decode(Response.Body.Tokenization.PaymentInstrumentData.self, from: data) // swiftlint:disable:this force_try
    }
}

// MARK: - Process Vaulted Payment Tests

@available(iOS 15.0, *)
final class ProcessVaultedPaymentTests: XCTestCase {

    func testProcessVaultedPayment_Success_ReturnsPaymentResult() async throws {
        // Given
        let repository = VaultMockHeadlessRepository()
        let expectedResult = PaymentResult(
            paymentId: "pay_123",
            status: .success,
            token: "token_abc",
            paymentMethodType: "PAYMENT_CARD"
        )
        await repository.setProcessVaultedPaymentResult(.success(expectedResult))

        // When
        let result = try await repository.processVaultedPayment(
            vaultedPaymentMethodId: "vault_1",
            paymentMethodType: "PAYMENT_CARD",
            additionalData: nil
        )

        // Then
        XCTAssertEqual(result.paymentId, "pay_123")
        XCTAssertEqual(result.status, .success)
    }

    func testProcessVaultedPayment_WithCvvData_PassesAdditionalData() async throws {
        // Given
        let repository = VaultMockHeadlessRepository()
        await repository.setProcessVaultedPaymentResult(.success(PaymentResult(paymentId: "pay_1", status: .success)))
        let cvvData = PrimerVaultedCardAdditionalData(cvv: "123")

        // When
        _ = try await repository.processVaultedPayment(
            vaultedPaymentMethodId: "vault_card",
            paymentMethodType: "PAYMENT_CARD",
            additionalData: cvvData
        )

        // Then
        let calls = await repository.processVaultedPaymentCalls
        XCTAssertEqual(calls.count, 1)
        XCTAssertEqual(calls[0].id, "vault_card")
        XCTAssertNotNil(calls[0].additionalData)
    }

    func testProcessVaultedPayment_PayPal_NoAdditionalData() async throws {
        // Given
        let repository = VaultMockHeadlessRepository()
        await repository.setProcessVaultedPaymentResult(.success(PaymentResult(paymentId: "pay_1", status: .success)))

        // When
        _ = try await repository.processVaultedPayment(
            vaultedPaymentMethodId: "vault_paypal",
            paymentMethodType: "PAYPAL",
            additionalData: nil
        )

        // Then
        let calls = await repository.processVaultedPaymentCalls
        XCTAssertEqual(calls[0].type, "PAYPAL")
        XCTAssertNil(calls[0].additionalData)
    }

    func testProcessVaultedPayment_Error_ThrowsError() async {
        // Given
        let repository = VaultMockHeadlessRepository()
        let expectedError = NSError(domain: "PaymentError", code: 500, userInfo: [NSLocalizedDescriptionKey: "Payment declined"])
        await repository.setProcessVaultedPaymentResult(.failure(expectedError))

        // When/Then
        do {
            _ = try await repository.processVaultedPayment(
                vaultedPaymentMethodId: "vault_1",
                paymentMethodType: "PAYMENT_CARD",
                additionalData: nil
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).domain, "PaymentError")
        }
    }

    func testProcessVaultedPayment_MultipleCalls_TracksAllCalls() async throws {
        // Given
        let repository = VaultMockHeadlessRepository()
        await repository.setProcessVaultedPaymentResult(.success(PaymentResult(paymentId: "pay_1", status: .success)))

        // When
        _ = try await repository.processVaultedPayment(
            vaultedPaymentMethodId: "vault_1",
            paymentMethodType: "PAYMENT_CARD",
            additionalData: nil
        )
        _ = try await repository.processVaultedPayment(
            vaultedPaymentMethodId: "vault_2",
            paymentMethodType: "PAYPAL",
            additionalData: nil
        )

        // Then
        let calls = await repository.processVaultedPaymentCalls
        XCTAssertEqual(calls.count, 2)
        XCTAssertEqual(calls[0].id, "vault_1")
        XCTAssertEqual(calls[1].id, "vault_2")
    }
}

// MARK: - Delete Vaulted Payment Method Tests

@available(iOS 15.0, *)
final class DeleteVaultedPaymentMethodTests: XCTestCase {

    func testDeleteVaultedPaymentMethod_Success_CompletesWithoutError() async throws {
        // Given
        let repository = VaultMockHeadlessRepository()
        await repository.setDeleteVaultedPaymentMethodResult(.success(()))

        // When/Then - Should not throw
        try await repository.deleteVaultedPaymentMethod("vault_123")
    }

    func testDeleteVaultedPaymentMethod_Error_ThrowsError() async {
        // Given
        let repository = VaultMockHeadlessRepository()
        let expectedError = NSError(domain: "DeleteError", code: 403, userInfo: [NSLocalizedDescriptionKey: "Forbidden"])
        await repository.setDeleteVaultedPaymentMethodResult(.failure(expectedError))

        // When/Then
        do {
            try await repository.deleteVaultedPaymentMethod("vault_123")
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual((error as NSError).code, 403)
        }
    }

    func testDeleteVaultedPaymentMethod_TracksDeletedIds() async throws {
        // Given
        let repository = VaultMockHeadlessRepository()
        await repository.setDeleteVaultedPaymentMethodResult(.success(()))

        // When
        try await repository.deleteVaultedPaymentMethod("vault_1")
        try await repository.deleteVaultedPaymentMethod("vault_2")
        try await repository.deleteVaultedPaymentMethod("vault_3")

        // Then
        let deletedIds = await repository.deleteVaultedPaymentMethodCalls
        XCTAssertEqual(deletedIds, ["vault_1", "vault_2", "vault_3"])
    }

    func testDeleteVaultedPaymentMethod_MultipleDeletes_EachCallsRepository() async throws {
        // Given
        let repository = VaultMockHeadlessRepository()
        await repository.setDeleteVaultedPaymentMethodResult(.success(()))

        // When
        try await repository.deleteVaultedPaymentMethod("vault_a")
        try await repository.deleteVaultedPaymentMethod("vault_b")

        // Then
        let calls = await repository.deleteVaultedPaymentMethodCalls
        XCTAssertEqual(calls.count, 2)
    }
}

// MARK: - Payment Result Tests

@available(iOS 15.0, *)
final class VaultPaymentResultTests: XCTestCase {

    func testPaymentResult_SuccessStatus() {
        // Given/When
        let result = PaymentResult(
            paymentId: "pay_123",
            status: .success,
            token: "tok_abc",
            amount: TestData.Amounts.standard,
            paymentMethodType: "PAYMENT_CARD"
        )

        // Then
        XCTAssertEqual(result.paymentId, "pay_123")
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.token, "tok_abc")
        XCTAssertEqual(result.amount, 1000)
        XCTAssertEqual(result.paymentMethodType, "PAYMENT_CARD")
    }

    func testPaymentResult_PendingStatus() {
        // Given/When
        let result = PaymentResult(
            paymentId: "pay_456",
            status: .pending
        )

        // Then
        XCTAssertEqual(result.status, .pending)
    }

    func testPaymentResult_FailedStatus() {
        // Given/When
        let result = PaymentResult(
            paymentId: "pay_789",
            status: .failed
        )

        // Then
        XCTAssertEqual(result.status, .failed)
    }

    func testPaymentResult_OptionalFieldsAreNil() {
        // Given/When
        let result = PaymentResult(
            paymentId: "pay_1",
            status: .success
        )

        // Then
        XCTAssertNil(result.token)
        XCTAssertNil(result.amount)
        XCTAssertNil(result.paymentMethodType)
    }
}

// MARK: - Vaulted Card Additional Data Tests

@available(iOS 15.0, *)
final class VaultedCardAdditionalDataTests: XCTestCase {

    func testVaultedCardAdditionalData_InitializesWithCvv() {
        // Given/When
        let additionalData = PrimerVaultedCardAdditionalData(cvv: "123")

        // Then
        XCTAssertEqual(additionalData.cvv, "123")
    }

    func testVaultedCardAdditionalData_ThreeDigitCvv() {
        // Given/When
        let additionalData = PrimerVaultedCardAdditionalData(cvv: "456")

        // Then
        XCTAssertEqual(additionalData.cvv, "456")
    }

    func testVaultedCardAdditionalData_FourDigitCvv() {
        // Given - Amex uses 4-digit CVV
        let additionalData = PrimerVaultedCardAdditionalData(cvv: "1234")

        // Then
        XCTAssertEqual(additionalData.cvv, "1234")
    }
}
