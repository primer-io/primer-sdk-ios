import Foundation
import SwiftUI

@available(iOS 15.0, *)
enum CheckoutRoute: Hashable, Identifiable {
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
