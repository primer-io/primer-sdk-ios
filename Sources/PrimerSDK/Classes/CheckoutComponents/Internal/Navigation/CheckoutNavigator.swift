//
//  CheckoutNavigator.swift
//  PrimerSDK - CheckoutComponents
//
//  Wrapper for CheckoutCoordinator that provides simple navigation methods
//

import SwiftUI
import PrimerUI

/// Simple navigation wrapper that delegates to CheckoutCoordinator
/// This provides a simpler API for basic navigation needs while the coordinator handles complex state
@available(iOS 15.0, *)
@MainActor
internal final class CheckoutNavigator: ObservableObject, LogReporter {

    // MARK: - Private Properties

    private let coordinator: CheckoutCoordinator

    // MARK: - Public Properties

    /// Current route from the coordinator
    var currentRoute: CheckoutRoute {
        coordinator.currentRoute
    }

    /// Navigation state as AsyncStream (NO Combine)
    var navigationEvents: AsyncStream<CheckoutRoute> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                // Observe coordinator's navigation stack changes
                for await _ in coordinator.$navigationStack.values {
                    continuation.yield(coordinator.currentRoute)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    // MARK: - Initialization

    init(coordinator: CheckoutCoordinator? = nil) {
        self.coordinator = coordinator ?? CheckoutCoordinator()
        // Initialized with state-driven navigation
    }

    // MARK: - Navigation Methods

    /// Navigate to loading screen
    func navigateToLoading() {
        coordinator.navigate(to: .loading)
    }

    /// Navigate to payment selection screen
    func navigateToPaymentSelection() {
        coordinator.navigate(to: .paymentMethodSelection)
    }

    /// Navigate to a generic payment method flow
    func navigateToPaymentMethod(_ paymentMethodType: String, context: PresentationContext = .fromPaymentSelection) {
        coordinator.navigate(to: .paymentMethod(paymentMethodType, context))
    }

    /// Navigate to country selection
    func navigateToCountrySelection() {
        coordinator.navigate(to: .selectCountry)
    }
    
    func loadServerDrivenUI(schema: String) {
        coordinator.navigate(to: .serverDrivenUI(schema: schema))
    }

    /// Navigate to error screen with message (handled by CheckoutComponentsPrimer delegate)
    func navigateToError(_ message: String) {
        let error = CheckoutPaymentError(
            code: "checkout_error",
            message: message,
            details: nil
        )
        coordinator.handlePaymentFailure(error)

        // Error handling is now managed by CheckoutComponentsPrimer delegate
        // Error navigation - handled by delegate
    }

    /// Navigate back
    func navigateBack() {
        coordinator.goBack()
    }

    /// Dismiss the entire checkout flow
    func dismiss() {
        coordinator.dismiss()
    }

    // MARK: - Coordinator Access

    /// Access to the underlying coordinator for advanced navigation
    var checkoutCoordinator: CheckoutCoordinator {
        coordinator
    }
}

/// Environment key for CheckoutNavigator
@available(iOS 15.0, *)
@preconcurrency
internal struct CheckoutNavigatorKey: EnvironmentKey {
    static let defaultValue: CheckoutNavigator = {
        // Create the navigator on MainActor
        let navigator = MainActor.assumeIsolated {
            CheckoutNavigator()
        }
        return navigator
    }()
}

@available(iOS 15.0, *)
internal extension EnvironmentValues {
    var checkoutNavigator: CheckoutNavigator {
        get { self[CheckoutNavigatorKey.self] }
        set { self[CheckoutNavigatorKey.self] = newValue }
    }
}
