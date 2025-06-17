//
//  ProcessCardPaymentInteractor.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// Interactor (Use Case) for processing card payments
@available(iOS 15.0, *)
internal protocol ProcessCardPaymentInteractor: LogReporter {
    /// Executes the card payment process
    /// - Parameter cardData: The card payment data to process
    /// - Returns: PaymentResult containing the payment outcome
    /// - Throws: Error if payment processing fails
    func execute(cardData: CardPaymentData) async throws -> PaymentResult
}

/// Implementation of ProcessCardPaymentInteractor
@available(iOS 15.0, *)
internal class ProcessCardPaymentInteractorImpl: ProcessCardPaymentInteractor, LogReporter {
    
    // MARK: - Dependencies
    
    private let paymentRepository: PaymentRepository
    private let tokenizationRepository: TokenizationRepository
    
    // MARK: - Initialization
    
    init(
        paymentRepository: PaymentRepository,
        tokenizationRepository: TokenizationRepository
    ) {
        self.paymentRepository = paymentRepository
        self.tokenizationRepository = tokenizationRepository
        logger.debug(message: "🏗️ [ProcessCardPaymentInteractor] Initialized")
    }
    
    // MARK: - ProcessCardPaymentInteractor
    
    func execute(cardData: CardPaymentData) async throws -> PaymentResult {
        logger.debug(message: "💳 [ProcessCardPaymentInteractor] Starting card payment processing")
        
        do {
            // Step 1: Validate card data
            try validateCardData(cardData)
            logger.debug(message: "✅ [ProcessCardPaymentInteractor] Card data validation passed")
            
            // Step 2: Tokenize the card
            logger.debug(message: "🔐 [ProcessCardPaymentInteractor] Tokenizing card data")
            let token = try await tokenizationRepository.tokenizeCard(cardData)
            logger.debug(message: "✅ [ProcessCardPaymentInteractor] Card tokenization successful")
            
            // Step 3: Process the payment
            logger.debug(message: "💰 [ProcessCardPaymentInteractor] Processing payment with token")
            let result = try await paymentRepository.processPayment(token: token)
            
            if result.success {
                logger.info(message: "✅ [ProcessCardPaymentInteractor] Payment processed successfully")
                logger.debug(message: "🎯 [ProcessCardPaymentInteractor] Transaction ID: \(result.transactionId ?? "N/A")")
            } else {
                logger.warning(message: "⚠️ [ProcessCardPaymentInteractor] Payment failed: \(result.error?.localizedDescription ?? "Unknown error")")
            }
            
            return result
            
        } catch {
            logger.error(message: "❌ [ProcessCardPaymentInteractor] Payment processing failed: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Private Methods
    
    private func validateCardData(_ cardData: CardPaymentData) throws {
        // Basic validation before processing
        if cardData.cardNumber.isEmpty {
            throw PaymentProcessingError.invalidCardNumber
        }
        
        if cardData.cvv.isEmpty {
            throw PaymentProcessingError.invalidCVV
        }
        
        if cardData.expiryDate.isEmpty {
            throw PaymentProcessingError.invalidExpiryDate
        }
        
        // Additional validation can be added here
        // Note: Detailed validation is handled by the existing validation system
    }
}

// MARK: - Payment Processing Errors

@available(iOS 15.0, *)
internal enum PaymentProcessingError: Error, LocalizedError {
    case invalidCardNumber
    case invalidCVV
    case invalidExpiryDate
    case tokenizationFailed
    case paymentDeclined
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .invalidCardNumber:
            return "Invalid card number provided"
        case .invalidCVV:
            return "Invalid CVV provided"
        case .invalidExpiryDate:
            return "Invalid expiry date provided"
        case .tokenizationFailed:
            return "Failed to tokenize card data"
        case .paymentDeclined:
            return "Payment was declined"
        case .networkError:
            return "Network error occurred during payment processing"
        case .unknownError:
            return "An unknown error occurred during payment processing"
        }
    }
}