//
//  ProcessFormRedirectPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Interactor Protocol

@available(iOS 15.0, *)
protocol ProcessFormRedirectPaymentInteractor {

    /// - Parameter onPollingStarted: Invoked when polling begins, signaling the user needs to complete payment in an external app
    func execute(
        paymentMethodType: String,
        sessionInfo: any OffSessionPaymentSessionInfo,
        onPollingStarted: (() -> Void)?
    ) async throws -> PaymentResult

    func cancelPolling(paymentMethodType: String)
}

// MARK: - Interactor Implementation

@available(iOS 15.0, *)
final class ProcessFormRedirectPaymentInteractorImpl: ProcessFormRedirectPaymentInteractor, LogReporter {

    // MARK: - Dependencies

    private let formRedirectRepository: FormRedirectRepository

    // MARK: - Initialization

    init(formRedirectRepository: FormRedirectRepository) {
        self.formRedirectRepository = formRedirectRepository
    }

    // MARK: - ProcessFormRedirectPaymentInteractor

    func execute(
        paymentMethodType: String,
        sessionInfo: any OffSessionPaymentSessionInfo,
        onPollingStarted: (() -> Void)? = nil
    ) async throws -> PaymentResult {
        logger.debug(message: "Executing form redirect payment for \(paymentMethodType)")

        let tokenizationResponse = try await formRedirectRepository.tokenize(
            paymentMethodType: paymentMethodType,
            sessionInfo: sessionInfo
        )

        guard let token = tokenizationResponse.tokenData.token else {
            let error = PrimerError.invalidValue(key: "token", reason: "Missing token from tokenization")
            ErrorHandler.handle(error: error)
            throw error
        }

        logger.debug(message: "Tokenization completed for \(paymentMethodType)")

        var paymentResponse = try await formRedirectRepository.createPayment(
            token: token,
            paymentMethodType: paymentMethodType
        )

        logger.debug(message: "Payment created with status: \(paymentResponse.status.rawValue)")

        switch paymentResponse.status {
        case .failed:
            let error = PrimerError.paymentFailed(
                paymentMethodType: paymentMethodType,
                paymentId: paymentResponse.paymentId,
                orderId: nil,
                status: paymentResponse.status.rawValue
            )
            ErrorHandler.handle(error: error)
            throw error

        case .pending:
            if let statusUrl = paymentResponse.statusUrl {
                onPollingStarted?()

                logger.debug(message: "Polling for payment completion at \(statusUrl.absoluteString)")
                let resumeToken = try await formRedirectRepository.pollForCompletion(statusUrl: statusUrl)
                logger.debug(message: "Polling completed for \(paymentMethodType)")

                paymentResponse = try await formRedirectRepository.resumePayment(
                    paymentId: paymentResponse.paymentId,
                    resumeToken: resumeToken,
                    paymentMethodType: paymentMethodType
                )

                logger.debug(message: "Payment resumed with status: \(paymentResponse.status.rawValue)")

                if paymentResponse.status == .failed {
                    let error = PrimerError.paymentFailed(
                        paymentMethodType: paymentMethodType,
                        paymentId: paymentResponse.paymentId,
                        orderId: nil,
                        status: paymentResponse.status.rawValue
                    )
                    ErrorHandler.handle(error: error)
                    throw error
                }
            } else {
                let error = PrimerError.invalidValue(key: "statusUrl", reason: "Missing status URL for pending payment - cannot start polling")
                ErrorHandler.handle(error: error)
                throw error
            }

        case .success:
            break
        }

        return PaymentResult(
            paymentId: paymentResponse.paymentId,
            status: .success,
            token: token,
            amount: nil,
            paymentMethodType: paymentMethodType
        )
    }

    func cancelPolling(paymentMethodType: String) {
        let error = PrimerError.cancelled(paymentMethodType: paymentMethodType)
        formRedirectRepository.cancelPolling(error: error)
    }
}
