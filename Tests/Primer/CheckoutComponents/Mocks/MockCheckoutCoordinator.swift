//
//  MockCheckoutCoordinator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@testable import PrimerSDK

/// Mock implementation of CheckoutCoordinator for testing navigation.
/// Provides configurable behavior, call tracking, and captured parameters.
@available(iOS 15.0, *)
@MainActor
final class MockCheckoutCoordinator: ObservableObject {

    // MARK: - Published Properties (matches real implementation)

    @Published var navigationStack: [CheckoutRoute] = []

    // MARK: - Call Tracking

    private(set) var navigateCallCount = 0
    private(set) var goBackCallCount = 0
    private(set) var dismissCallCount = 0
    private(set) var handlePaymentFailureCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastNavigatedRoute: CheckoutRoute?
    private(set) var lastPaymentMethodRoute: CheckoutRoute?
    private(set) var lastError: PrimerError?
    private(set) var allNavigatedRoutes: [CheckoutRoute] = []

    // MARK: - Configurable Behavior

    /// When true, applies the same navigation behavior as the real coordinator
    var applyNavigationBehavior = true

    /// When set, prevents navigation and captures the blocked route
    var blockNavigation = false
    private(set) var blockedRoutes: [CheckoutRoute] = []

    // MARK: - Computed Properties (matches real implementation)

    var currentRoute: CheckoutRoute {
        navigationStack.last ?? .splash
    }

    // MARK: - Initialization

    init() {}

    // MARK: - Navigation Methods

    func navigate(to route: CheckoutRoute) {
        navigateCallCount += 1
        lastNavigatedRoute = route
        allNavigatedRoutes.append(route)

        // Track last payment method for retry functionality
        if case .paymentMethod = currentRoute {
            lastPaymentMethodRoute = currentRoute
        }

        if blockNavigation {
            blockedRoutes.append(route)
            return
        }

        if applyNavigationBehavior {
            // Apply route's navigation behavior (matches real implementation)
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
        } else {
            // Simple append for basic testing
            navigationStack.append(route)
        }
    }

    func goBack() {
        goBackCallCount += 1

        guard !navigationStack.isEmpty else { return }
        navigationStack.removeLast()
    }

    func dismiss() {
        dismissCallCount += 1
        navigationStack = []
    }

    func handlePaymentFailure(_ error: PrimerError) {
        handlePaymentFailureCallCount += 1
        lastError = error
        navigate(to: .failure(error))
    }

    // MARK: - Test Helpers

    /// Resets all call counts and captured parameters
    func reset() {
        navigateCallCount = 0
        goBackCallCount = 0
        dismissCallCount = 0
        handlePaymentFailureCallCount = 0

        lastNavigatedRoute = nil
        lastPaymentMethodRoute = nil
        lastError = nil
        allNavigatedRoutes = []
        blockedRoutes = []

        navigationStack = []
        blockNavigation = false
        applyNavigationBehavior = true
    }

    func setupNavigationStack(_ routes: [CheckoutRoute]) {
        navigationStack = routes
    }

    func didNavigate(to route: CheckoutRoute) -> Bool {
        allNavigatedRoutes.contains(route)
    }

    func verifyNavigationSequence(_ expectedRoutes: [CheckoutRoute]) -> Bool {
        allNavigatedRoutes == expectedRoutes
    }
}

// MARK: - Factory Methods

@available(iOS 15.0, *)
extension MockCheckoutCoordinator {

    static func atPaymentSelection() -> MockCheckoutCoordinator {
        let coordinator = MockCheckoutCoordinator()
        coordinator.navigationStack = [.paymentMethodSelection]
        return coordinator
    }

    static func atCardPayment() -> MockCheckoutCoordinator {
        let coordinator = MockCheckoutCoordinator()
        coordinator.navigationStack = [.paymentMethodSelection, .paymentMethod(TestData.PaymentMethodTypes.card, .fromPaymentSelection)]
        return coordinator
    }

    static func withNavigationBlocked() -> MockCheckoutCoordinator {
        let coordinator = MockCheckoutCoordinator()
        coordinator.blockNavigation = true
        return coordinator
    }
}
