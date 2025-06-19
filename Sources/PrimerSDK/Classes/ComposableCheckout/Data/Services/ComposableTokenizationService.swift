//
//  TokenizationService.swift
//
//
//  Created on 17.06.2025.
//

import Foundation

/// Service interface for card tokenization that integrates with existing SDK
@available(iOS 15.0, *)
internal protocol ComposableTokenizationService: LogReporter {
    /// Tokenizes card data using the existing SDK's PCI-compliant tokenization
    /// - Parameter cardData: The card data to tokenize
    /// - Returns: PaymentToken containing the tokenized card information
    /// - Throws: Error if tokenization fails
    func tokenizeCard(_ cardData: CardPaymentData) async throws -> PaymentToken
}

/// Implementation of ComposableTokenizationService that integrates with existing SDK PCI-compliant tokenization
@available(iOS 15.0, *)
internal class ComposableTokenizationServiceImpl: ComposableTokenizationService, LogReporter {

    // MARK: - ComposableTokenizationService

    func tokenizeCard(_ cardData: CardPaymentData) async throws -> PaymentToken {
        logger.debug(message: "🔐 [TokenizationService] Starting card tokenization with existing SDK")

        // Log basic info without exposing sensitive data
        logger.debug(message: "📋 [TokenizationService] Tokenizing card data:")
        logger.debug(message: "  - Card ending: ***\(cardData.cardNumber.suffix(4))")
        logger.debug(message: "  - Expiry: \(cardData.expiryDate)")
        logger.debug(message: "  - Has cardholder name: \(cardData.cardholderName?.isEmpty == false)")

        do {
            // Integrate with existing SDK PCI-compliant tokenization through the bridge
            let token = try await tokenizeCardWithSDK(cardData)

            logger.info(message: "✅ [TokenizationService] Card tokenization successful")
            logger.debug(message: "🔑 [TokenizationService] Token type: \(token.tokenType)")

            return token

        } catch {
            logger.error(message: "❌ [TokenizationService] Card tokenization failed: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Private Methods

    private func tokenizeCardWithSDK(_ cardData: CardPaymentData) async throws -> PaymentToken {
        logger.debug(message: "🌐 [TokenizationService] Integrating with existing SDK tokenization")

        // Validate card data before tokenization
        try validateCardDataForTokenization(cardData)

        // Use the legacy tokenization bridge to connect to existing PCI-compliant services
        let bridge = LegacyTokenizationBridge()
        let token = try await bridge.tokenizeCard(cardData)

        logger.debug(message: "✅ [TokenizationService] SDK tokenization completed")

        return token
    }

    private func validateCardDataForTokenization(_ cardData: CardPaymentData) throws {
        logger.debug(message: "🔍 [TokenizationService] Validating card data for tokenization")

        // Basic validation before tokenization
        if cardData.cardNumber.isEmpty {
            throw TokenizationServiceError.missingCardNumber
        }

        if cardData.cvv.isEmpty {
            throw TokenizationServiceError.missingCVV
        }

        if cardData.expiryDate.isEmpty {
            throw TokenizationServiceError.missingExpiryDate
        }

        // Additional PCI-compliant validation would go here
        // This would use existing SDK validation components

        logger.debug(message: "✅ [TokenizationService] Card data validation passed")
    }
}

// MARK: - Tokenization Service Errors

@available(iOS 15.0, *)
internal enum TokenizationServiceError: Error, LocalizedError {
    case missingCardNumber
    case missingCVV
    case missingExpiryDate
    case invalidCardNumber
    case invalidCVV
    case invalidExpiryDate
    case tokenizationFailed
    case networkError
    case securityError
    case pciComplianceError

    var errorDescription: String? {
        switch self {
        case .missingCardNumber:
            return "Card number is required for tokenization"
        case .missingCVV:
            return "CVV is required for tokenization"
        case .missingExpiryDate:
            return "Expiry date is required for tokenization"
        case .invalidCardNumber:
            return "Invalid card number format"
        case .invalidCVV:
            return "Invalid CVV format"
        case .invalidExpiryDate:
            return "Invalid expiry date format"
        case .tokenizationFailed:
            return "Card tokenization failed"
        case .networkError:
            return "Network error during tokenization"
        case .securityError:
            return "Security error during tokenization"
        case .pciComplianceError:
            return "PCI compliance error during tokenization"
        }
    }
}
