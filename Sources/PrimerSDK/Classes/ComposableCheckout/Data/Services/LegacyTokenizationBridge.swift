//
//  LegacyTokenizationBridge.swift
//  PrimerSDK
//
//  Created to bridge ComposableCheckout tokenization with legacy PCI-compliant services
//

import Foundation

/// Bridge service that connects ComposableCheckout tokenization with legacy TokenizationService
@available(iOS 15.0, *)
class LegacyTokenizationBridge: LogReporter {

    // MARK: - Properties
    private let tokenizationService: TokenizationServiceProtocol

    // MARK: - Initialization
    init(tokenizationService: TokenizationServiceProtocol = TokenizationService()) {
        self.tokenizationService = tokenizationService
    }

    // MARK: - Public Methods

    /// Tokenize card data using the legacy PCI-compliant service
    func tokenizeCard(_ cardData: CardPaymentData) async throws -> PaymentToken {
        logger.info(message: "🔐 [LegacyTokenizationBridge] Starting card tokenization")

        // Convert CardPaymentData to legacy tokenization request
        let tokenizationRequest = try await buildTokenizationRequest(from: cardData)

        // Use the legacy tokenization service
        return try await withCheckedThrowingContinuation { continuation in
            tokenizationService.tokenize(requestBody: tokenizationRequest)
                .done { tokenData in
                    self.logger.info(message: "✅ [LegacyTokenizationBridge] Tokenization successful")

                    // Convert legacy response to new PaymentToken format
                    let paymentToken = PaymentToken(
                        token: tokenData.token ?? "",
                        expirationDate: nil, // Legacy service doesn't provide expiration
                        tokenType: "PAYMENT_INSTRUMENT"
                    )

                    continuation.resume(returning: paymentToken)
                }
                .catch { error in
                    self.logger.error(message: "❌ [LegacyTokenizationBridge] Tokenization failed: \(error)")
                    continuation.resume(throwing: error)
                }
        }
    }

    // MARK: - Private Methods

    private func buildTokenizationRequest(from cardData: CardPaymentData) async throws -> Request.Body.Tokenization {
        logger.debug(message: "🔧 [LegacyTokenizationBridge] Building tokenization request")

        // Create PrimerCardData from CardPaymentData
        let primerCardData = PrimerCardData(
            cardNumber: cardData.cardNumber,
            expiryDate: cardData.expiryDate,
            cvv: cardData.cvv,
            cardholderName: cardData.cardholderName
        )

        // Build the tokenization request using existing builder
        let builder = PrimerRawCardDataTokenizationBuilder(paymentMethodType: "PAYMENT_CARD")

        // Use Promise pattern to get the request body
        return try await withCheckedThrowingContinuation { continuation in
            builder.makeRequestBodyWithRawData(primerCardData)
                .done { requestBody in
                    continuation.resume(returning: requestBody)
                }
                .catch { error in
                    continuation.resume(throwing: error)
                }
        }
    }
}
