//
//  CheckoutCoordinator.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Checkout Navigation Coordinator
@available(iOS 15.0, *)
@MainActor
final class CheckoutCoordinator: ObservableObject, LogReporter {

    // MARK: - Published Properties
    @Published var navigationStack: [CheckoutRoute] = []

    // MARK: - Private Properties
    private(set) var lastPaymentMethodRoute: CheckoutRoute?

    // MARK: - Computed Properties
    var currentRoute: CheckoutRoute {
        navigationStack.last ?? .splash
    }

    // MARK: - Initialization
    init() {
        logger.debug(message: "🧭 [CheckoutCoordinator] Initialized")
    }

    // MARK: - Navigation Methods
    func navigate(to route: CheckoutRoute) {
        // Performance optimization: avoid redundant navigation to same route
        if currentRoute == route {
            logger.debug(message: "🧭 [CheckoutCoordinator] Redundant navigation to \(route)")
            return
        }

        let previousRoute = currentRoute

        // Track last payment method for retry functionality
        if case .paymentMethod = previousRoute {
            lastPaymentMethodRoute = previousRoute
        }

        // Use route's navigation behavior for consistent, optimized navigation
        switch route.navigationBehavior {
        case .push:
            navigationStack.append(route)
        case .reset:
            navigationStack = route == .splash ? [] : [route]
        case .replace:
            if !navigationStack.isEmpty {
                navigationStack[navigationStack.count - 1] = route
            } else {
                navigationStack = [route]
            }
        }

        logger.debug(message: "🧭 [CheckoutCoordinator] \(previousRoute) → \(route)")
    }

    func goBack() {
        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }

    func dismiss() {
        // Clear navigation stack - actual dismissal is handled via onCompletion callback flow
        navigationStack = []
        logger.debug(message: "🧭 [CheckoutCoordinator] Dismissed")
    }

    /// Wraps navigate() for semantic clarity and potential future hooks.
    func handlePaymentFailure(_ error: PrimerError) {
        navigate(to: .failure(error))
    }
}
