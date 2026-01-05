//
//  MockHeadlessRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockHeadlessRepository: HeadlessRepository {

    // MARK: - Configurable Return Values

    var paymentMethodsToReturn: [InternalPaymentMethod] = []
    var paymentResultToReturn: PaymentResult?
    var networkDetectionToReturn: [CardNetwork] = []
    var vaultedPaymentMethodsToReturn: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []

    // MARK: - Error Configuration

    var getPaymentMethodsError: Error?
    var processCardPaymentError: Error?
    var setBillingAddressError: Error?
    var fetchVaultedPaymentMethodsError: Error?
    var processVaultedPaymentError: Error?
    var deleteVaultedPaymentMethodError: Error?

    // MARK: - Call Tracking

    private(set) var getPaymentMethodsCallCount = 0
    private(set) var processCardPaymentCallCount = 0
    private(set) var setBillingAddressCallCount = 0
    private(set) var updateCardNumberCallCount = 0
    private(set) var selectCardNetworkCallCount = 0
    private(set) var fetchVaultedPaymentMethodsCallCount = 0
    private(set) var processVaultedPaymentCallCount = 0
    private(set) var deleteVaultedPaymentMethodCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastCardNumber: String?
    private(set) var lastCVV: String?
    private(set) var lastExpiryMonth: String?
    private(set) var lastExpiryYear: String?
    private(set) var lastCardholderName: String?
    private(set) var lastSelectedNetwork: CardNetwork?
    private(set) var lastBillingAddress: BillingAddress?
    private(set) var lastVaultedPaymentMethodId: String?
    private(set) var lastVaultedPaymentMethodType: String?
    private(set) var lastVaultedPaymentAdditionalData: PrimerVaultedPaymentMethodAdditionalData?
    private(set) var lastDeletedVaultedPaymentMethodId: String?

    // MARK: - Network Detection Stream Support

    private var networkDetectionContinuation: AsyncStream<[CardNetwork]>.Continuation?

    // MARK: - HeadlessRepository Protocol

    func getPaymentMethods() async throws -> [InternalPaymentMethod] {
        getPaymentMethodsCallCount += 1
        if let error = getPaymentMethodsError {
            throw error
        }
        return paymentMethodsToReturn
    }

    func processCardPayment(
        cardNumber: String,
        cvv: String,
        expiryMonth: String,
        expiryYear: String,
        cardholderName: String,
        selectedNetwork: CardNetwork?
    ) async throws -> PaymentResult {
        processCardPaymentCallCount += 1

        // Capture parameters
        lastCardNumber = cardNumber
        lastCVV = cvv
        lastExpiryMonth = expiryMonth
        lastExpiryYear = expiryYear
        lastCardholderName = cardholderName
        lastSelectedNetwork = selectedNetwork

        if let error = processCardPaymentError {
            throw error
        }

        guard let result = paymentResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    func setBillingAddress(_ billingAddress: BillingAddress) async throws {
        setBillingAddressCallCount += 1
        lastBillingAddress = billingAddress

        if let error = setBillingAddressError {
            throw error
        }
    }

    func getNetworkDetectionStream() -> AsyncStream<[CardNetwork]> {
        AsyncStream { continuation in
            self.networkDetectionContinuation = continuation
            // Emit initial value
            continuation.yield(self.networkDetectionToReturn)
        }
    }

    func updateCardNumberInRawDataManager(_ cardNumber: String) async {
        updateCardNumberCallCount += 1
        lastCardNumber = cardNumber
    }

    func selectCardNetwork(_ cardNetwork: CardNetwork) async {
        selectCardNetworkCallCount += 1
        lastSelectedNetwork = cardNetwork
    }

    func fetchVaultedPaymentMethods() async throws -> [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] {
        fetchVaultedPaymentMethodsCallCount += 1
        if let error = fetchVaultedPaymentMethodsError {
            throw error
        }
        return vaultedPaymentMethodsToReturn
    }

    func processVaultedPayment(
        vaultedPaymentMethodId: String,
        paymentMethodType: String,
        additionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) async throws -> PaymentResult {
        processVaultedPaymentCallCount += 1

        // Capture parameters
        lastVaultedPaymentMethodId = vaultedPaymentMethodId
        lastVaultedPaymentMethodType = paymentMethodType
        lastVaultedPaymentAdditionalData = additionalData

        if let error = processVaultedPaymentError {
            throw error
        }

        guard let result = paymentResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    func deleteVaultedPaymentMethod(_ id: String) async throws {
        deleteVaultedPaymentMethodCallCount += 1
        lastDeletedVaultedPaymentMethodId = id

        if let error = deleteVaultedPaymentMethodError {
            throw error
        }
    }

    // MARK: - Test Helpers

    func emitNetworkDetection(_ networks: [CardNetwork]) {
        networkDetectionContinuation?.yield(networks)
    }

    func reset() {
        getPaymentMethodsCallCount = 0
        processCardPaymentCallCount = 0
        setBillingAddressCallCount = 0
        updateCardNumberCallCount = 0
        selectCardNetworkCallCount = 0
        fetchVaultedPaymentMethodsCallCount = 0
        processVaultedPaymentCallCount = 0
        deleteVaultedPaymentMethodCallCount = 0

        lastCardNumber = nil
        lastCVV = nil
        lastExpiryMonth = nil
        lastExpiryYear = nil
        lastCardholderName = nil
        lastSelectedNetwork = nil
        lastBillingAddress = nil
        lastVaultedPaymentMethodId = nil
        lastVaultedPaymentMethodType = nil
        lastVaultedPaymentAdditionalData = nil
        lastDeletedVaultedPaymentMethodId = nil

        getPaymentMethodsError = nil
        processCardPaymentError = nil
        setBillingAddressError = nil
        fetchVaultedPaymentMethodsError = nil
        processVaultedPaymentError = nil
        deleteVaultedPaymentMethodError = nil
    }
}

// MARK: - Test Data Factory Methods

@available(iOS 15.0, *)
extension MockHeadlessRepository {

    static func withDefaultPaymentMethods() -> MockHeadlessRepository {
        let repository = MockHeadlessRepository()
        repository.paymentMethodsToReturn = [
            InternalPaymentMethod(
                id: "card-1",
                type: "PAYMENT_CARD",
                name: "Credit Card",
                isEnabled: true
            ),
            InternalPaymentMethod(
                id: "paypal-1",
                type: "PAYPAL",
                name: "PayPal",
                isEnabled: true
            )
        ]
        return repository
    }

    static func withSuccessfulPayment() -> MockHeadlessRepository {
        let repository = MockHeadlessRepository()
        repository.paymentResultToReturn = PaymentResult(
            paymentId: "test-payment-id",
            status: .success
        )
        return repository
    }
}
