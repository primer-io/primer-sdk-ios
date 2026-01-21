//
//  ProcessApplePayPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PassKit

/// Protocol for processing Apple Pay payments.
@available(iOS 15.0, *)
protocol ProcessApplePayPaymentInteractor {
    /// Processes an Apple Pay payment.
    /// - Parameter payment: The PKPayment from Apple Pay authorization
    /// - Returns: The payment result
    func execute(payment: PKPayment) async throws -> PaymentResult
}

/// Default implementation of ProcessApplePayPaymentInteractor.
/// Handles the full Apple Pay flow: tokenization and payment creation.
@available(iOS 15.0, *)
final class ProcessApplePayPaymentInteractorImpl: ProcessApplePayPaymentInteractor {

    // MARK: - Dependencies

    private let tokenizationService: TokenizationServiceProtocol
    private let createPaymentService: CreateResumePaymentServiceProtocol
    private let loggingInteractor: (any LoggingInteractor)?

    // MARK: - Initialization

    init(
        tokenizationService: TokenizationServiceProtocol,
        createPaymentService: CreateResumePaymentServiceProtocol,
        loggingInteractor: (any LoggingInteractor)? = nil
    ) {
        self.tokenizationService = tokenizationService
        self.createPaymentService = createPaymentService
        self.loggingInteractor = loggingInteractor
    }

    // MARK: - ProcessApplePayPaymentInteractor

    func execute(payment: PKPayment) async throws -> PaymentResult {
        do {
            // Get Apple Pay configuration
            let (configId, merchantIdentifier) = try getApplePayConfiguration()

            // Build payment instrument
            let paymentInstrument = try buildPaymentInstrument(
                from: payment,
                configId: configId,
                merchantIdentifier: merchantIdentifier
            )

            // Tokenize
            let tokenData = try await tokenizationService.tokenize(
                requestBody: Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            )

            guard let token = tokenData.token else {
                throw PrimerError.invalidValue(key: "paymentMethodTokenData.token")
            }

            // Create payment
            let paymentRequest = Request.Body.Payment.Create(token: token)
            let paymentResponse = try await createPaymentService.createPayment(paymentRequest: paymentRequest)

            return PaymentResult(
                paymentId: paymentResponse.id ?? "",
                status: PaymentStatus(from: paymentResponse.status),
                amount: paymentResponse.amount,
                currencyCode: paymentResponse.currencyCode,
                paymentMethodType: PrimerPaymentMethodType.applePay.rawValue
            )

        } catch {
            loggingInteractor?.logError(message: "Apple Pay payment processing failed", error: error)
            throw error
        }
    }

    // MARK: - Private Helpers

    private func getApplePayConfiguration() throws -> (configId: String, merchantIdentifier: String) {
        guard let applePayConfig = PrimerAPIConfiguration.current?.paymentMethods?
            .first(where: { $0.internalPaymentMethodType == .applePay }) else {
            throw PrimerError.unsupportedPaymentMethod(paymentMethodType: PrimerPaymentMethodType.applePay.rawValue)
        }

        guard let configId = applePayConfig.id else {
            throw PrimerError.invalidValue(key: "applePayConfig.id")
        }

        guard let merchantIdentifier = PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantIdentifier else {
            throw PrimerError.invalidMerchantIdentifier()
        }

        return (configId, merchantIdentifier)
    }

    private func buildPaymentInstrument(
        from payment: PKPayment,
        configId: String,
        merchantIdentifier: String
    ) throws -> ApplePayPaymentInstrument {
        // Check for mock/test mode
        var isMockedBE = false
        #if DEBUG
        if PrimerAPIConfiguration.current?.clientSession?.testId != nil {
            isMockedBE = true
        }
        if payment.token.paymentData.isEmpty {
            isMockedBE = true
        }
        #endif

        // Parse payment data
        let tokenPaymentData: ApplePayPaymentResponseTokenPaymentData
        if isMockedBE {
            tokenPaymentData = ApplePayPaymentResponseTokenPaymentData(
                data: "apple-pay-payment-response-mock-data",
                signature: "apple-pay-mock-signature",
                version: "apple-pay-mock-version",
                header: ApplePayTokenPaymentDataHeader(
                    ephemeralPublicKey: "apple-pay-mock-ephemeral-key",
                    publicKeyHash: "apple-pay-mock-public-key-hash",
                    transactionId: "apple-pay-mock-transaction-id"
                )
            )
        } else {
            tokenPaymentData = try JSONDecoder().decode(
                ApplePayPaymentResponseTokenPaymentData.self,
                from: payment.token.paymentData
            )
        }

        return ApplePayPaymentInstrument(
            paymentMethodConfigId: configId,
            sourceConfig: ApplePayPaymentInstrument.SourceConfig(
                source: "IN_APP",
                merchantId: merchantIdentifier
            ),
            token: ApplePayPaymentInstrument.PaymentResponseToken(
                paymentMethod: ApplePayPaymentResponsePaymentMethod(
                    displayName: payment.token.paymentMethod.displayName,
                    network: payment.token.paymentMethod.network?.rawValue,
                    type: payment.token.paymentMethod.type.primerValue
                ),
                transactionIdentifier: payment.token.transactionIdentifier,
                paymentData: tokenPaymentData
            )
        )
    }
}
