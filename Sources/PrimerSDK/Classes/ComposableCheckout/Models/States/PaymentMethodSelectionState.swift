//
//  PaymentMethodSelectionState.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// State model for payment method selection that matches Android
public enum PaymentMethodSelectionState: Equatable {
    case loading
    case ready(paymentMethods: [PrimerComposablePaymentMethod], currency: Currency?)
    case error(Error)
    
    /// Equatable implementation
    public static func == (lhs: PaymentMethodSelectionState, rhs: PaymentMethodSelectionState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading):
            return true
        case (.ready(let lhsMethods, let lhsCurrency), .ready(let rhsMethods, let rhsCurrency)):
            return lhsMethods == rhsMethods && lhsCurrency == rhsCurrency
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}