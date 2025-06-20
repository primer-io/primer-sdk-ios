//
//  PaymentMethodSelectionState.swift
//
//
//  Created on 17.06.2025.
//

import Foundation

/// State model for payment method selection that matches Android exactly
public enum PaymentMethodSelectionState: Equatable, Hashable {
    case loading
    case ready(paymentMethods: [PrimerComposablePaymentMethod], currency: ComposableCurrency?)
    case error(String) // Use string instead of Error for better matching

    /// Equatable implementation
    public static func == (lhs: PaymentMethodSelectionState, rhs: PaymentMethodSelectionState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.ready(let lhsMethods, let lhsCurrency), .ready(let rhsMethods, let rhsCurrency)):
            return lhsMethods == rhsMethods && lhsCurrency == rhsCurrency
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }

    /// Hashable implementation
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .loading:
            hasher.combine("loading")
        case .ready(let methods, let currency):
            hasher.combine("ready")
            hasher.combine(methods)
            hasher.combine(currency)
        case .error(let message):
            hasher.combine("error")
            hasher.combine(message)
        }
    }
}
