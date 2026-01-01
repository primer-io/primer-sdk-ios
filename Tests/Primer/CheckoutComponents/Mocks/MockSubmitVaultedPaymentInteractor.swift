//
//  MockSubmitVaultedPaymentInteractor.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of SubmitVaultedPaymentInteractor for testing.
/// Provides configurable return values and call tracking.
@available(iOS 15.0, *)
final class MockSubmitVaultedPaymentInteractor: SubmitVaultedPaymentInteractor {
    var executeCallCount = 0
    var lastVaultedPaymentMethodId: String?
    var lastPaymentMethodType: String?
    var lastAdditionalData: PrimerVaultedPaymentMethodAdditionalData?
    var resultToReturn: PaymentResult = PaymentResult(paymentId: "test-vault-payment-id", status: .success)
    var errorToThrow: Error?

    func execute(
        vaultedPaymentMethodId: String,
        paymentMethodType: String,
        additionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) async throws -> PaymentResult {
        executeCallCount += 1
        lastVaultedPaymentMethodId = vaultedPaymentMethodId
        lastPaymentMethodType = paymentMethodType
        lastAdditionalData = additionalData

        if let error = errorToThrow {
            throw error
        }
        return resultToReturn
    }

    func reset() {
        executeCallCount = 0
        lastVaultedPaymentMethodId = nil
        lastPaymentMethodType = nil
        lastAdditionalData = nil
        resultToReturn = PaymentResult(paymentId: "test-vault-payment-id", status: .success)
        errorToThrow = nil
    }
}
