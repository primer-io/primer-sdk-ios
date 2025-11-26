//
//  CheckoutNavigator.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Simple navigation wrapper that delegates to CheckoutCoordinator
/// This provides a simpler API for basic navigation needs while the coordinator handles complex state
@available(iOS 15.0, *)
@MainActor
final class CheckoutNavigator: ObservableObject, LogReporter {

    // MARK: - Private Properties

    private let coordinator: CheckoutCoordinator

    // MARK: - Navigation Callbacks

    /// Custom navigation callbacks from PrimerComponents configuration.
    /// When set, these callbacks are invoked INSTEAD of default navigation behavior.
    private(set) var navigationCallbacks: NavigationCallbacks?

    struct NavigationCallbacks {
        let checkout: PrimerComponents.Checkout.Navigation
        let paymentMethodSelection: PrimerComponents.PaymentMethodSelection.Navigation
        let cardFormNavigation: PrimerComponents.CardForm.Navigation
        let countrySelectionNavigation: PrimerComponents.CardForm.SelectCountry.Navigation
    }

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

    // MARK: - Configuration

    func configure(with components: PrimerComponents) {
        let cardFormConfig = components.configuration(for: PrimerComponents.CardForm.self) ?? PrimerComponents.CardForm()
        navigationCallbacks = NavigationCallbacks(
            checkout: components.checkout.navigation,
            paymentMethodSelection: components.paymentMethodSelection.navigation,
            cardFormNavigation: cardFormConfig.navigation,
            countrySelectionNavigation: cardFormConfig.selectCountry.navigation
        )
    }

    // MARK: - Navigation Methods

    func navigateToLoading() {
        coordinator.navigate(to: .loading)
    }

    func navigateToPaymentSelection() {
        coordinator.navigate(to: .paymentMethodSelection)
    }

    func navigateToPaymentMethod(_ paymentMethodType: String, context: PresentationContext = .fromPaymentSelection) {
        // Check for custom onPaymentMethodSelected callback
        if let callback = navigationCallbacks?.paymentMethodSelection.onPaymentMethodSelected {
            callback(paymentMethodType)
            return
        }
        coordinator.navigate(to: .paymentMethod(paymentMethodType, context))
    }

    func navigateToCountrySelection() {
        // Check for custom showCountrySelection callback
        if let callback = navigationCallbacks?.cardFormNavigation.showCountrySelection {
            callback()
            return
        }
        coordinator.navigate(to: .selectCountry)
    }

    func navigateToError(_ error: PrimerError) {
        // Check for custom onError callback
        if let callback = navigationCallbacks?.checkout.onError {
            callback(error.localizedDescription)
            return
        }
        coordinator.handlePaymentFailure(error)
        // Error handling is now managed by CheckoutComponentsPrimer delegate
    }

    func navigateBack() {
        // Check for custom onBack callback
        if let callback = navigationCallbacks?.checkout.onBack {
            callback()
            return
        }
        coordinator.goBack()
    }

    func dismiss() {
        // Check for custom onCancel callback
        if let callback = navigationCallbacks?.checkout.onCancel {
            callback()
            return
        }
        coordinator.dismiss()
    }

    // MARK: - Additional Navigation Callback Methods

    func handleRetry() {
        // Check for custom onRetry callback
        if let callback = navigationCallbacks?.checkout.onRetry {
            callback()
            return
        }
        // Default behavior: navigate back to payment method selection
        coordinator.navigate(to: .paymentMethodSelection)
    }

    func handleOtherPaymentMethods() {
        // Check for custom onOtherPaymentMethods callback
        if let callback = navigationCallbacks?.checkout.onOtherPaymentMethods {
            callback()
            return
        }
        // Default behavior: navigate to payment method selection
        coordinator.navigate(to: .paymentMethodSelection)
    }

    func handleSuccess() {
        // Check for custom onSuccess callback
        if let callback = navigationCallbacks?.checkout.onSuccess {
            callback()
            return
        }
        // Default behavior: let coordinator handle success (typically shows success screen)
        // Note: Success state is typically handled by the coordinator through handlePaymentSuccess
    }

    func handleCountrySelected(code: String, name: String) {
        // Check for custom onCountrySelected callback
        if let callback = navigationCallbacks?.countrySelectionNavigation.onCountrySelected {
            callback(code, name)
            return
        }
        // Default behavior: dismiss country selection modal
        // Note: Country selection is typically handled by the SelectCountryScope
    }

    // MARK: - Coordinator Access

    var checkoutCoordinator: CheckoutCoordinator {
        coordinator
    }
}
