//
//  MockSubmitVaultedPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

/// Mock implementation of SubmitVaultedPaymentInteractor for testing.
/// Provides configurable return values and call tracking.
@available(iOS 15.0, *)
final class MockSubmitVaultedPaymentInteractor: SubmitVaultedPaymentInteractor {

    // MARK: - Configurable Return Values

    var resultToReturn: PaymentResult = PaymentResult(paymentId: "test-vault-payment-id", status: .success)
    var errorToThrow: Error?

    // MARK: - Call Tracking

    private(set) var executeCallCount = 0
    private(set) var lastVaultedPaymentMethodId: String?
    private(set) var lastPaymentMethodType: String?
    private(set) var lastAdditionalData: PrimerVaultedPaymentMethodAdditionalData?

    // MARK: - Protocol Implementation

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

    // MARK: - Test Helpers

    func reset() {
        executeCallCount = 0
        lastVaultedPaymentMethodId = nil
        lastPaymentMethodType = nil
        lastAdditionalData = nil
        resultToReturn = PaymentResult(paymentId: "test-vault-payment-id", status: .success)
        errorToThrow = nil
    }
}
