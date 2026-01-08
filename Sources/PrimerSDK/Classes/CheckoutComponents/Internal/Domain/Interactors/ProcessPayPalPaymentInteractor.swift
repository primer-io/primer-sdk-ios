//
//  ProcessPayPalPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Interactor protocol for processing PayPal payments.
@available(iOS 15.0, *)
protocol ProcessPayPalPaymentInteractor {
    /// Executes the PayPal payment flow (checkout or vault based on intent).
    /// - Returns: The payment result upon successful completion.
    /// - Throws: Error if any step of the flow fails.
    func execute() async throws -> PaymentResult
}

/// Implementation of ProcessPayPalPaymentInteractor that handles both checkout and vault flows.
@available(iOS 15.0, *)
final class ProcessPayPalPaymentInteractorImpl: ProcessPayPalPaymentInteractor, LogReporter {

    private let repository: PayPalRepository

    init(repository: PayPalRepository) {
        self.repository = repository
    }

    func execute() async throws -> PaymentResult {
        let intent = PrimerInternal.shared.intent

        logger.debug(message: "Starting PayPal payment flow with intent: \(String(describing: intent))")

        switch intent {
        case .vault:
            return try await executeVaultFlow()
        case .checkout, .none:
            return try await executeCheckoutFlow()
        }
    }

    // MARK: - Private Flow Methods

    private func executeCheckoutFlow() async throws -> PaymentResult {
        logger.debug(message: "Executing PayPal checkout (order) flow")

        // 1. Start order session
        let (orderId, approvalUrl) = try await repository.startOrderSession()
        logger.debug(message: "PayPal order session started with orderId: \(orderId)")

        guard let url = URL(string: approvalUrl) else {
            throw PrimerError.invalidValue(
                key: "approvalUrl",
                value: approvalUrl,
                reason: "Invalid PayPal approval URL"
            )
        }

        // 2. Open web authentication
        _ = try await repository.openWebAuthentication(url: url)
        logger.debug(message: "PayPal web authentication completed")

        // 3. Fetch payer info
        let payerInfo = try await repository.fetchPayerInfo(orderId: orderId)
        logger.debug(message: "PayPal payer info fetched")

        // 4. Tokenize and process payment
        let result = try await repository.tokenize(
            paymentInstrument: .order(orderId: orderId, payerInfo: payerInfo)
        )
        logger.debug(message: "PayPal checkout payment completed successfully")

        return result
    }

    private func executeVaultFlow() async throws -> PaymentResult {
        logger.debug(message: "Executing PayPal vault (billing agreement) flow")

        // 1. Start billing agreement session
        let approvalUrl = try await repository.startBillingAgreementSession()
        logger.debug(message: "PayPal billing agreement session started")

        guard let url = URL(string: approvalUrl) else {
            throw PrimerError.invalidValue(
                key: "approvalUrl",
                value: approvalUrl,
                reason: "Invalid PayPal approval URL"
            )
        }

        // 2. Open web authentication
        _ = try await repository.openWebAuthentication(url: url)
        logger.debug(message: "PayPal web authentication completed")

        // 3. Confirm billing agreement
        let billingAgreementResult = try await repository.confirmBillingAgreement()
        logger.debug(message: "PayPal billing agreement confirmed: \(billingAgreementResult.billingAgreementId)")

        // 4. Tokenize and process payment
        let result = try await repository.tokenize(
            paymentInstrument: .billingAgreement(result: billingAgreementResult)
        )
        logger.debug(message: "PayPal vault payment completed successfully")

        return result
    }
}
