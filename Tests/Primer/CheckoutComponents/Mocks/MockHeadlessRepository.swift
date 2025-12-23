//
//  MockHeadlessRepository.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of HeadlessRepository for testing.
/// Provides configurable return values and call tracking.
@available(iOS 15.0, *)
final class MockHeadlessRepository: HeadlessRepository {

    // MARK: - Configurable Return Values

    var paymentMethodsToReturn: [InternalPaymentMethod] = []
    var paymentResultToReturn: PaymentResult?
    var networkDetectionToReturn: [CardNetwork] = []

    // MARK: - Error Configuration

    var getPaymentMethodsError: Error?
    var processCardPaymentError: Error?
    var setBillingAddressError: Error?

    // MARK: - Call Tracking

    private(set) var getPaymentMethodsCallCount = 0
    private(set) var processCardPaymentCallCount = 0
    private(set) var setBillingAddressCallCount = 0
    private(set) var updateCardNumberCallCount = 0
    private(set) var selectCardNetworkCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastCardNumber: String?
    private(set) var lastCVV: String?
    private(set) var lastExpiryMonth: String?
    private(set) var lastExpiryYear: String?
    private(set) var lastCardholderName: String?
    private(set) var lastSelectedNetwork: CardNetwork?
    private(set) var lastBillingAddress: BillingAddress?

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

    // MARK: - Test Helpers

    /// Emits a new set of detected networks through the stream
    func emitNetworkDetection(_ networks: [CardNetwork]) {
        networkDetectionContinuation?.yield(networks)
    }

    /// Resets all call counts and captured parameters
    func reset() {
        getPaymentMethodsCallCount = 0
        processCardPaymentCallCount = 0
        setBillingAddressCallCount = 0
        updateCardNumberCallCount = 0
        selectCardNetworkCallCount = 0

        lastCardNumber = nil
        lastCVV = nil
        lastExpiryMonth = nil
        lastExpiryYear = nil
        lastCardholderName = nil
        lastSelectedNetwork = nil
        lastBillingAddress = nil

        getPaymentMethodsError = nil
        processCardPaymentError = nil
        setBillingAddressError = nil
    }
}

// MARK: - Test Data Factory Methods

@available(iOS 15.0, *)
extension MockHeadlessRepository {

    /// Creates a repository pre-configured with common payment methods
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

    /// Creates a repository configured to return a successful payment result
    static func withSuccessfulPayment() -> MockHeadlessRepository {
        let repository = MockHeadlessRepository()
        repository.paymentResultToReturn = PaymentResult(
            paymentId: "test-payment-id",
            status: .success
        )
        return repository
    }
}
