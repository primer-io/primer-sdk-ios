//
//  CheckoutState.swift
//
//
//  Created on 17.06.2025.
//

import Foundation

/// State model for the overall checkout process (matches Android exactly)
public enum CheckoutState: Equatable, Hashable {
    case notInitialized
    case initializing
    case ready
    case error(String) // Use string instead of Error for better matching

    /// Equatable implementation
    public static func == (lhs: CheckoutState, rhs: CheckoutState) -> Bool {
        switch (lhs, rhs) {
        case (.notInitialized, .notInitialized):
            return true
        case (.initializing, .initializing):
            return true
        case (.ready, .ready):
            return true
        case (.error(let lhsMessage), .error(let rhsMessage)):
            return lhsMessage == rhsMessage
        default:
            return false
        }
    }

    /// Hashable implementation
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .notInitialized:
            hasher.combine("notInitialized")
        case .initializing:
            hasher.combine("initializing")
        case .ready:
            hasher.combine("ready")
        case .error(let message):
            hasher.combine("error")
            hasher.combine(message)
        }
    }
}
