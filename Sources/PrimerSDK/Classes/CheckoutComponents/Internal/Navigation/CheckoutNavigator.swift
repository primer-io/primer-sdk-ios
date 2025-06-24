//
//  CheckoutNavigator.swift
//  PrimerSDK - CheckoutComponents
//
//  Wrapper for CheckoutCoordinator that provides simple navigation methods
//  Follows CheckoutComponents plan: NO Combine, uses AsyncStream and state-driven navigation
//

import SwiftUI

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
        logger.info(message: "🧭 [CheckoutNavigator] Initialized with state-driven navigation")
    }

    // MARK: - Navigation Methods

    /// Navigate to splash screen
    func navigateToSplash() {
        coordinator.navigate(to: .splash)
    }

    /// Navigate to loading screen
    func navigateToLoading() {
        coordinator.navigate(to: .loading)
    }

    /// Navigate to payment selection screen
    func navigateToPaymentSelection() {
        coordinator.navigate(to: .paymentMethodSelection)
    }

    /// Navigate to card form
    func navigateToCardForm() {
        coordinator.navigate(to: .cardForm)
    }

    /// Navigate to Apple Pay flow
    func navigateToApplePay() {
        coordinator.navigate(to: .paymentMethod("APPLE_PAY"))
    }

    /// Navigate to PayPal flow
    func navigateToPayPal() {
        coordinator.navigate(to: .paymentMethod("PAYPAL"))
    }

    /// Navigate to country selection
    func navigateToCountrySelection() {
        coordinator.navigate(to: .selectCountry)
    }

    /// Navigate to success screen with payment result
    func navigateToSuccess(_ result: PaymentResult) {
        logger.info(message: "Navigating to success screen for payment: \(result.paymentId)")

        let checkoutResult = CheckoutPaymentResult(
            paymentId: result.paymentId,
            amount: result.amount?.description ?? "N/A",
            method: result.paymentMethodType ?? "Card"
        )
        coordinator.navigate(to: .success(checkoutResult))
    }

    /// Navigate to success screen (legacy method for backward compatibility)
    func navigateToSuccess() {
        logger.info(message: "Legacy success navigation - handled by CheckoutComponentsPrimer delegate")

        // Success handling is now managed by CheckoutComponentsPrimer delegate
        // which will call PrimerUIManager.dismissOrShowResultScreen() appropriately
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
        logger.info(message: "Error navigation - handled by CheckoutComponentsPrimer delegate")
    }

    /// Navigate back
    func navigateBack() {
        coordinator.goBack()
    }

    /// Reset navigation to root
    func resetToRoot() {
        coordinator.resetToRoot()
    }

    /// Dismiss the entire checkout flow
    func dismiss() {
        coordinator.dismiss()
    }

    /// Complete the checkout with success delegate
    func completeCheckout() async {
        await handleCheckoutCompletion()
    }

    // MARK: - Coordinator Access

    /// Access to the underlying coordinator for advanced navigation
    var checkoutCoordinator: CheckoutCoordinator {
        coordinator
    }

    // MARK: - Private Methods

    /// Handle successful checkout completion
    private func handleCheckoutCompletion() async {
        // Create minimal checkout data for successful payment
        // In a full implementation, this would contain the actual payment result
        let checkoutData = PrimerCheckoutData(payment: nil, additionalInfo: nil)

        // Call the legacy delegate to maintain compatibility
        // The delegate proxy already handles UI dismissal
        PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)

        // Dismissal would be handled by parent view controller
    }

    /// Handle checkout error
    private func handleCheckoutError(_ message: String) async {
        // Create a generic error for the delegate
        let nsError = NSError(domain: "CheckoutComponents", code: -1, userInfo: [NSLocalizedDescriptionKey: message])
        let error = PrimerError.underlyingErrors(errors: [nsError], userInfo: [String: String]?.errorUserInfoDictionary(), diagnosticsId: UUID().uuidString)

        // Call the legacy delegate to maintain compatibility
        PrimerDelegateProxy.primerDidFailWithError(error, data: nil) { errorDecision in
            // Handle error decision
            switch errorDecision.type {
            case .fail:
                break // Dismissal would be handled by parent view controller
            }
        }
    }
}

/// Environment key for CheckoutNavigator
@available(iOS 15.0, *)
internal struct CheckoutNavigatorKey: EnvironmentKey {
    @MainActor static let defaultValue: CheckoutNavigator = CheckoutNavigator()
}

@available(iOS 15.0, *)
internal extension EnvironmentValues {
    var checkoutNavigator: CheckoutNavigator {
        get { self[CheckoutNavigatorKey.self] }
        set { self[CheckoutNavigatorKey.self] = newValue }
    }
}
