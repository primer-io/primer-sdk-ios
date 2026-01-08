//
//  CheckoutNavigator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Simple navigation wrapper that delegates to CheckoutCoordinator
/// This provides a simpler API for basic navigation needs while the coordinator handles complex state
@available(iOS 15.0, *)
@MainActor
final class CheckoutNavigator: ObservableObject, LogReporter {

    // MARK: - Private Properties

    private let coordinator: CheckoutCoordinator

    // MARK: - Properties

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

    func navigateToLoading() {
        coordinator.navigate(to: .loading)
    }

    func navigateToPaymentSelection() {
        coordinator.navigate(to: .paymentMethodSelection)
    }

    func navigateToVaultedPaymentMethods() {
        coordinator.navigate(to: .vaultedPaymentMethods)
    }

    func navigateToDeleteVaultedPaymentMethodConfirmation(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) {
        coordinator.navigate(to: .deleteVaultedPaymentMethodConfirmation(method))
    }

    func navigateToPaymentMethod(_ paymentMethodType: String, context: PresentationContext = .fromPaymentSelection) {
        coordinator.navigate(to: .paymentMethod(paymentMethodType, context))
    }

    func navigateToProcessing() {
        coordinator.navigate(to: .processing)
    }

    func navigateToError(_ error: PrimerError) {
        coordinator.handlePaymentFailure(error)
    }

    func handleOtherPaymentMethods() {
        coordinator.navigate(to: .paymentMethodSelection)
    }

    func navigateBack() {
        coordinator.goBack()
    }

    func dismiss() {
        coordinator.dismiss()
    }

    // MARK: - Coordinator Access

    /// Access to the underlying coordinator for advanced navigation scenarios.
    /// This property provides direct access to the coordinator for cases where
    /// higher-level navigation methods are insufficient.
    var checkoutCoordinator: CheckoutCoordinator {
        coordinator
    }
}
