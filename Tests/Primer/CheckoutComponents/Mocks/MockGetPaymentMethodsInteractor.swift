//
//  MockGetPaymentMethodsInteractor.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of GetPaymentMethodsInteractor for testing
@available(iOS 15.0, *)
final class MockGetPaymentMethodsInteractor: GetPaymentMethodsInteractor {

    // MARK: - Configurable Return Values

    var paymentMethodsToReturn: [InternalPaymentMethod] = []
    var errorToThrow: Error?
    var delay: TimeInterval = 0

    // MARK: - Call Tracking

    private(set) var executeCallCount = 0

    // MARK: - Protocol Implementation

    func execute() async throws -> [InternalPaymentMethod] {
        executeCallCount += 1

        if delay > 0 {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
        }

        if let error = errorToThrow {
            throw error
        }

        return paymentMethodsToReturn
    }

    // MARK: - Test Helpers

    func reset() {
        paymentMethodsToReturn = []
        errorToThrow = nil
        delay = 0
        executeCallCount = 0
    }

    /// Creates a mock with default payment methods
    static func withDefaultPaymentMethods() -> MockGetPaymentMethodsInteractor {
        let mock = MockGetPaymentMethodsInteractor()
        mock.paymentMethodsToReturn = [
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
            ),
            InternalPaymentMethod(
                id: "apple-pay-1",
                type: "APPLE_PAY",
                name: "Apple Pay",
                isEnabled: true
            )
        ]
        return mock
    }
}
