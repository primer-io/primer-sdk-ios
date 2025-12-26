//
//  MockProcessCardPaymentInteractor.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of ProcessCardPaymentInteractor for testing.
/// Provides configurable return values and call tracking.
@available(iOS 15.0, *)
final class MockProcessCardPaymentInteractor: ProcessCardPaymentInteractor {
    var executeCallCount = 0
    var lastCardData: CardPaymentData?
    var resultToReturn: PaymentResult = PaymentResult(paymentId: "test-payment-id", status: .success)
    var errorToThrow: Error?

    func execute(cardData: CardPaymentData) async throws -> PaymentResult {
        executeCallCount += 1
        lastCardData = cardData
        if let error = errorToThrow {
            throw error
        }
        return resultToReturn
    }

    func reset() {
        executeCallCount = 0
        lastCardData = nil
        resultToReturn = PaymentResult(paymentId: "test-payment-id", status: .success)
        errorToThrow = nil
    }
}
