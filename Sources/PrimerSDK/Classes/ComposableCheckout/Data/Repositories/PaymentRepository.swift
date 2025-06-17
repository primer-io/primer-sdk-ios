//
//  PaymentRepository.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// Repository interface for payment processing
@available(iOS 15.0, *)
internal protocol PaymentRepository: LogReporter {
    /// Processes a payment using the provided token
    /// - Parameter token: The payment token to process
    /// - Returns: PaymentResult containing the processing outcome
    /// - Throws: Error if payment processing fails
    func processPayment(token: PaymentToken) async throws -> PaymentResult
}

/// Implementation of PaymentRepository
@available(iOS 15.0, *)
internal class PaymentRepositoryImpl: PaymentRepository, LogReporter {
    
    // MARK: - Dependencies
    
    private let paymentService: PaymentService
    
    // MARK: - Initialization
    
    init(paymentService: PaymentService) {
        self.paymentService = paymentService
        logger.debug(message: "🏗️ [PaymentRepository] Initialized")
    }
    
    // MARK: - PaymentRepository
    
    func processPayment(token: PaymentToken) async throws -> PaymentResult {
        logger.debug(message: "💰 [PaymentRepository] Starting payment processing")
        logger.debug(message: "🔐 [PaymentRepository] Using token type: \(token.tokenType)")
        
        do {
            let result = try await paymentService.processPayment(token: token)
            
            if result.success {
                logger.info(message: "✅ [PaymentRepository] Payment processed successfully")
                logger.debug(message: "🎯 [PaymentRepository] Transaction ID: \(result.transactionId ?? "N/A")")
                logger.debug(message: "📊 [PaymentRepository] Payment status: \(result.paymentStatus)")
            } else {
                logger.warning(message: "⚠️ [PaymentRepository] Payment processing failed")
                if let error = result.error {
                    logger.error(message: "❌ [PaymentRepository] Payment error: \(error.localizedDescription)")
                }
            }
            
            return result
            
        } catch {
            logger.error(message: "❌ [PaymentRepository] Payment processing threw error: \(error.localizedDescription)")
            throw PaymentRepositoryError.processingFailed(underlying: error)
        }
    }
}

// MARK: - Payment Repository Errors

@available(iOS 15.0, *)
internal enum PaymentRepositoryError: Error, LocalizedError {
    case processingFailed(underlying: Error)
    case invalidToken
    case paymentDeclined
    case networkError
    case unknownError
    
    var errorDescription: String? {
        switch self {
        case .processingFailed(let underlying):
            return "Payment processing failed: \(underlying.localizedDescription)"
        case .invalidToken:
            return "Invalid payment token provided"
        case .paymentDeclined:
            return "Payment was declined"
        case .networkError:
            return "Network error during payment processing"
        case .unknownError:
            return "Unknown error occurred during payment processing"
        }
    }
}