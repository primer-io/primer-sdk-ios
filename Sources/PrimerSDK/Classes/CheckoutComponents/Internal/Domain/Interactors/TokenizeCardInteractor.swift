//
//  TokenizeCardInteractor.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Protocol for tokenizing card data without processing payment.
internal protocol TokenizeCardInteractor {
    /// Tokenizes card data for future use.
    /// - Parameter cardData: The card data to tokenize.
    /// - Returns: The tokenization result containing the token.
    func execute(cardData: CardPaymentData) async throws -> TokenizationResult
}

/// Result of card tokenization.
internal struct TokenizationResult {
    let token: String
    let tokenId: String
    let expiresAt: Date?
    let cardDetails: CardDetails?

    struct CardDetails {
        let last4: String
        let network: String
        let expiryMonth: Int
        let expiryYear: Int
    }
}

/// Default implementation of TokenizeCardInteractor.
internal final class TokenizeCardInteractorImpl: TokenizeCardInteractor, LogReporter {

    private let repository: HeadlessRepository

    init(repository: HeadlessRepository) {
        self.repository = repository
    }

    func execute(cardData: CardPaymentData) async throws -> TokenizationResult {
        logger.info(message: "Tokenizing card data")

        do {
            let result = try await repository.tokenizeCard(
                cardNumber: cardData.cardNumber,
                cvv: cardData.cvv,
                expiryMonth: cardData.expiryMonth,
                expiryYear: cardData.expiryYear,
                cardholderName: cardData.cardholderName,
                selectedNetwork: cardData.selectedNetwork
            )

            logger.info(message: "Card tokenized successfully: \(result.tokenId)")
            return result

        } catch {
            logger.error(message: "Card tokenization failed: \(error)")
            throw error
        }
    }
}
