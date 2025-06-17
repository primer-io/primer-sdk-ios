//
//  TokenizationRepository.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// Repository interface for card tokenization
@available(iOS 15.0, *)
internal protocol TokenizationRepository: LogReporter {
    /// Tokenizes card data for secure processing
    /// - Parameter cardData: The card data to tokenize
    /// - Returns: PaymentToken containing the tokenized card information
    /// - Throws: Error if tokenization fails
    func tokenizeCard(_ cardData: CardPaymentData) async throws -> PaymentToken
}

/// Implementation of TokenizationRepository
@available(iOS 15.0, *)
internal class TokenizationRepositoryImpl: TokenizationRepository, LogReporter {
    
    // MARK: - Dependencies
    
    private let tokenizationService: TokenizationService
    
    // MARK: - Initialization
    
    init(tokenizationService: TokenizationService) {
        self.tokenizationService = tokenizationService
        logger.debug(message: "🏗️ [TokenizationRepository] Initialized")
    }
    
    // MARK: - TokenizationRepository
    
    func tokenizeCard(_ cardData: CardPaymentData) async throws -> PaymentToken {
        logger.debug(message: "🔐 [TokenizationRepository] Starting card tokenization")
        
        // Log basic info without exposing sensitive data
        logger.debug(message: "📋 [TokenizationRepository] Card data contains:")
        logger.debug(message: "  - Card number: \(cardData.cardNumber.isEmpty ? "Empty" : "***\(cardData.cardNumber.suffix(4))")")
        logger.debug(message: "  - CVV: \(cardData.cvv.isEmpty ? "Empty" : "***")")
        logger.debug(message: "  - Expiry: \(cardData.expiryDate.isEmpty ? "Empty" : cardData.expiryDate)")
        logger.debug(message: "  - Cardholder: \(cardData.cardholderName?.isEmpty != false ? "Empty" : "Provided")")
        
        do {
            let token = try await tokenizationService.tokenizeCard(cardData)
            
            logger.info(message: "✅ [TokenizationRepository] Card tokenization successful")
            logger.debug(message: "🔑 [TokenizationRepository] Token type: \(token.tokenType)")
            
            // Log token info without exposing the actual token
            if token.token.count > 8 {
                let maskedToken = "\(token.token.prefix(4))***\(token.token.suffix(4))"
                logger.debug(message: "🔑 [TokenizationRepository] Token: \(maskedToken)")
            }
            
            if let expirationDate = token.expirationDate {
                logger.debug(message: "⏰ [TokenizationRepository] Token expires: \(expirationDate)")
            }
            
            return token
            
        } catch {
            logger.error(message: "❌ [TokenizationRepository] Card tokenization failed: \(error.localizedDescription)")
            throw TokenizationRepositoryError.tokenizationFailed(underlying: error)
        }
    }
}

// MARK: - Tokenization Repository Errors

@available(iOS 15.0, *)
internal enum TokenizationRepositoryError: Error, LocalizedError {
    case tokenizationFailed(underlying: Error)
    case invalidCardData
    case networkError
    case securityError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .tokenizationFailed(let underlying):
            return "Card tokenization failed: \(underlying.localizedDescription)"
        case .invalidCardData:
            return "Invalid card data provided for tokenization"
        case .networkError:
            return "Network error during card tokenization"
        case .securityError:
            return "Security error during card tokenization"
        case .unknownError:
            return "Unknown error occurred during card tokenization"
        }
    }
}