import Foundation
import SwiftUI

// MARK: - Navigation Protocol
@available(iOS 15.0, *)
protocol NavigationRoute: Hashable, Identifiable {
    /// Unique identifier for the route
    var id: String { get }

    /// Defines how this route should be navigated to
    var navigationBehavior: NavigationBehavior { get }

    /// Human-readable name for debugging and analytics
    var routeName: String { get }

    /// Optional analytics parameters for tracking
    var analyticsParameters: [String: Any] { get }
}

// MARK: - Navigation Behavior
@available(iOS 15.0, *)
enum NavigationBehavior {
    case push       // Add to stack
    case reset      // Replace entire stack
    case replace    // Replace current route
}

// MARK: - Default Implementation
@available(iOS 15.0, *)
extension NavigationRoute {
    var analyticsParameters: [String: Any] {
        ["route_id": id, "route_name": routeName]
    }
}

// MARK: - Checkout Route Implementation
@available(iOS 15.0, *)
enum CheckoutRoute: NavigationRoute {
    case splash
    case paymentMethodsList
    case paymentMethod(PaymentMethodProtocol)
    case success(CheckoutPaymentResult)
    case failure(CheckoutPaymentError)

    var id: String {
        switch self {
        case .splash: return "splash"
        case .paymentMethodsList: return "payment-methods-list"
        case .paymentMethod(let method): return "payment-method-\(method.id)"
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

    // MARK: - NavigationRoute Protocol Implementation
    var routeName: String {
        switch self {
        case .splash: return "Splash Screen"
        case .paymentMethodsList: return "Payment Methods"
        case .paymentMethod(let method): return "Payment Method: \(method.name ?? "Unknown")"
        case .success: return "Payment Success"
        case .failure: return "Payment Failure"
        }
    }

    var navigationBehavior: NavigationBehavior {
        switch self {
        case .splash:
            return .reset
        case .paymentMethodsList:
            return .reset  // Always reset to payment methods as root
        case .paymentMethod, .success, .failure:
            return .push   // Standard forward navigation
        }
    }

    var analyticsParameters: [String: Any] {
        var params = ["route_id": id, "route_name": routeName]

        switch self {
        case .paymentMethod(let method):
            params["payment_method_type"] = String(describing: method.type)
            params["payment_method_id"] = String(describing: method.id)
        case .success(let result):
            params["payment_id"] = result.paymentId
            params["amount"] = result.amount
        case .failure(let error):
            params["error_code"] = error.code
            params["error_message"] = error.message
        default:
            break
        }

        return params
    }
}

// Navigation result types
@available(iOS 15.0, *)
struct CheckoutPaymentResult {
    let paymentId: String
    let amount: String
    let method: String
}

@available(iOS 15.0, *)
struct CheckoutPaymentError: Error {
    let code: String
    let message: String
    let details: String?
}
