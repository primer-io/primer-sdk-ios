//
//  CheckoutRoute.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import SwiftUI

// MARK: - Presentation Context
@available(iOS 15.0, *)
public enum PresentationContext {
    case direct                    // Presented directly (e.g., single payment method)
    case fromPaymentSelection     // Reached from payment method selection

    var shouldShowBackButton: Bool {
        switch self {
        case .direct:
            return false
        case .fromPaymentSelection:
            return true
        }
    }
}

// MARK: - Navigation Behavior
@available(iOS 15.0, *)
enum NavigationBehavior {
    case push       // Add to stack
    case reset      // Replace entire stack
    case replace    // Replace current route
}

// MARK: - Checkout Route Implementation
@available(iOS 15.0, *)
enum CheckoutRoute: Hashable, Identifiable {
    case splash
    case loading
    case paymentMethodSelection
    case selectCountry
    case processing  // Payment processing in progress
    case success(CheckoutPaymentResult)
    case failure(PrimerError)
    case paymentMethod(String, PresentationContext) // Payment method type with presentation context

    var id: String {
        switch self {
        case .splash: return "splash"
        case .loading: return "loading"
        case .paymentMethodSelection: return "payment-method-selection"
        case .selectCountry: return "select-country"
        case .processing: return "processing"
        case let .paymentMethod(type, context):
            return "payment-method-\(type)-\(context == .direct ? "direct" : "selection")"
        case .success: return "success"
        case .failure: return "failure"
        }
    }

    // Implement Hashable for NavigationPath compatibility
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }

    static func == (lhs: CheckoutRoute, rhs: CheckoutRoute) -> Bool {
        lhs.id == rhs.id
    }

    // MARK: - Route Properties

    var navigationBehavior: NavigationBehavior {
        switch self {
        case .splash:
            return .reset
        case .loading:
            return .replace // Replace splash with loading
        case .paymentMethodSelection:
            return .reset  // Always reset to payment methods as root
        case .selectCountry, .paymentMethod:
            return .push   // Standard forward navigation
        case .processing:
            return .replace // Replace current screen with processing overlay
        case .success, .failure:
            return .replace // Replace current screen with result
        }
    }
}

// MARK: - Navigation Result Type

/// Represents a successful payment result for navigation purposes.
/// Contains minimal information needed for routing; full payment details
/// are available through the SDK's PaymentResult type.
@available(iOS 15.0, *)
public struct CheckoutPaymentResult {
    public let paymentId: String
    public let amount: String
}
