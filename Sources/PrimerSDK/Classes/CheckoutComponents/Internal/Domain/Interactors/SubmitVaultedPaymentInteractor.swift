//
//  SubmitVaultedPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Interactor for processing payments with vaulted payment methods
@available(iOS 15.0, *)
protocol SubmitVaultedPaymentInteractor {
    /// Executes payment with a vaulted payment method
    /// - Parameters:
    ///   - vaultedPaymentMethodId: The ID of the vaulted payment method to use
    ///   - paymentMethodType: The type of the vaulted payment method
    ///   - additionalData: Optional additional data (e.g., CVV for cards)
    /// - Returns: The payment result
    func execute(
        vaultedPaymentMethodId: String,
        paymentMethodType: String,
        additionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) async throws -> PaymentResult
}

@available(iOS 15.0, *)
final class SubmitVaultedPaymentInteractorImpl: SubmitVaultedPaymentInteractor, LogReporter {

    private let repository: HeadlessRepository
    private let loggingInteractor: DefaultLoggingInteractor?

    init(repository: HeadlessRepository, loggingInteractor: DefaultLoggingInteractor? = nil) {
        self.repository = repository
        self.loggingInteractor = loggingInteractor
    }

    func execute(
        vaultedPaymentMethodId: String,
        paymentMethodType: String,
        additionalData: PrimerVaultedPaymentMethodAdditionalData?
    ) async throws -> PaymentResult {
        logger.info(message: "[Vault] Processing vaulted payment method: \(vaultedPaymentMethodId)")

        do {
            let startTime = CFAbsoluteTimeGetCurrent()

            let result = try await repository.processVaultedPayment(
                vaultedPaymentMethodId: vaultedPaymentMethodId,
                paymentMethodType: paymentMethodType,
                additionalData: additionalData
            )

            let duration = (CFAbsoluteTimeGetCurrent() - startTime) * 1000
            logger.info(message: "[PERF] Vaulted payment processed in \(String(format: "%.0f", duration))ms: \(result.paymentId)")

            return result
        } catch {
            logger.error(message: "[Vault] Vaulted payment processing failed: \(error)")
            loggingInteractor?.logError(message: "[Vault] Vaulted payment processing failed", error: error)
            throw error
        }
    }
}
