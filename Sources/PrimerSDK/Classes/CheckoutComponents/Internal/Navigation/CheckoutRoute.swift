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
    case direct // Presented directly (e.g., single payment method)
    case fromPaymentSelection // Reached from payment method selection

    /// Whether the back button should be shown
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
    case push // Add to stack
    case reset // Replace entire stack
    case replace // Replace current route
}

// MARK: - Checkout Route Implementation

@available(iOS 15.0, *)
enum CheckoutRoute: Hashable, Identifiable {
    case splash
    case loading
    case paymentMethodSelection
    case selectCountry
    case success(CheckoutPaymentResult)
    case failure(PrimerError)
    case paymentMethod(String, PresentationContext) // Payment method type with presentation context

    var id: String {
        switch self {
        case .splash: return "splash"
        case .loading: return "loading"
        case .paymentMethodSelection: return "payment-method-selection"
        case .selectCountry: return "select-country"
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

    /// Human-readable name for debugging and analytics
    var routeName: String {
        switch self {
        case .splash: return "Splash Screen"
        case .loading: return "Loading Screen"
        case .paymentMethodSelection: return "Payment Method Selection"
        case .selectCountry: return "Select Country"
        case let .paymentMethod(type, context):
            return "Payment Method: \(type) (\(context == .direct ? "Direct" : "From Selection"))"
        case .success: return "Payment Success"
        case .failure: return "Payment Error"
        }
    }

    /// Defines how this route should be navigated to
    var navigationBehavior: NavigationBehavior {
        switch self {
        case .splash:
            return .reset
        case .loading:
            return .replace // Replace splash with loading
        case .paymentMethodSelection:
            return .reset // Always reset to payment methods as root
        case .selectCountry, .paymentMethod:
            return .push // Standard forward navigation
        case .success, .failure:
            return .replace // Replace current screen with result
        }
    }

    /// Analytics parameters for tracking navigation events
    var analyticsParameters: [String: Any] {
        var params = ["route_id": id, "route_name": routeName]

        switch self {
        case let .paymentMethod(type, context):
            params["payment_method_type"] = type
            params["presentation_context"] = context == .direct ? "direct" : "from_selection"
        case let .success(result):
            params["payment_id"] = result.paymentId
            params["amount"] = result.amount
        case let .failure(error):
            params["error_code"] = error.errorId
            params["error_message"] = error.errorDescription
        default:
            break
        }

        return params
    }
}

// MARK: - Navigation Result Type

/// Represents a successful payment result for navigation purposes.
/// Contains minimal information needed for routing; full payment details
/// are available through the SDK's PaymentResult type.
@available(iOS 15.0, *)
struct CheckoutPaymentResult {
    let paymentId: String
    let amount: String
}
