//
//  PaymentResult.swift
//
//
//  Created by Boris on 6.2.25..
//

/// Payment result model
public struct PaymentResult {
    let transactionId: String
    let amount: Decimal
    let currency: String
}

/// Error types for the Primer SDK
enum ComponentsPrimerError: Error, LocalizedError {
    case clientTokenError(Error)
    case designTokensError(Error)
    case invalidCardDetails
    case paymentProcessingError(Error)
    case networkError(Error)
    case unknownError(Error)

    var errorDescription: String? {
        switch self {
        case .clientTokenError(let error):
            return "Failed to process client token: \(error.localizedDescription)"
        case .designTokensError(let error):
            return "Failed to load design tokens: \(error.localizedDescription)"
        case .invalidCardDetails:
            return "Invalid card details. Please check your information and try again."
        case .paymentProcessingError(let error):
            return "Payment processing failed: \(error.localizedDescription)"
        case .networkError(let error):
            return "Network error: \(error.localizedDescription)"
        case .unknownError(let error):
            return "An unexpected error occurred: \(error.localizedDescription)"
        }
    }
}
