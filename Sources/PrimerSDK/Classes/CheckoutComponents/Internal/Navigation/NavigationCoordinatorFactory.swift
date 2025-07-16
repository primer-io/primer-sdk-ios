//
//  NavigationCoordinatorFactory.swift
//  PrimerSDK - CheckoutComponents
//
//  Factory for creating navigation coordinators in CheckoutComponents
//  Factory pattern for CheckoutComponents navigation coordinators
//

import Foundation
import SwiftUI

// MARK: - Navigation Coordinator Factory
@available(iOS 15.0, *)
@MainActor
internal struct NavigationCoordinatorFactory {

    /// Creates a navigation coordinator for any route type conforming to NavigationRoute
    /// This demonstrates the extensibility of the protocol-based design
    static func createCoordinator<T: NavigationRoute>(for routeType: T.Type) -> any NavigationCoordinator {
        // In a real implementation, this would return different coordinators based on route type
        // For now, we return CheckoutCoordinator as the primary implementation
        return CheckoutCoordinator()
    }

    /// Creates a checkout-specific coordinator (convenience method)
    static func createCheckoutCoordinator() -> CheckoutCoordinator {
        return CheckoutCoordinator()
    }
}

// MARK: - Navigation Coordinator Extensions
@available(iOS 15.0, *)
@MainActor
extension NavigationCoordinator {

    /// Generic navigation history tracking
    var navigationDepth: Int {
        return navigationStack.count
    }

    /// Generic navigation state validation
    var canGoBack: Bool {
        return navigationStack.count > 1
    }

    /// Generic navigation state information
    var navigationInfo: [String: Any] {
        return [
            "current_route": currentRoute.id,
            "navigation_depth": navigationDepth,
            "can_go_back": canGoBack,
            "stack_size": navigationStack.count
        ]
    }
}
