//
//  CheckoutState.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// State model for the overall checkout process
public enum CheckoutState: Equatable {
    case notInitialized
    case initializing
    case ready
    case error(Error)
    
    /// Equatable implementation
    public static func == (lhs: CheckoutState, rhs: CheckoutState) -> Bool {
        switch (lhs, rhs) {
        case (.notInitialized, .notInitialized):
            return true
        case (.initializing, .initializing):
            return true
        case (.ready, .ready):
            return true
        case (.error(let lhsError), .error(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }
}