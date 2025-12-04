//
//  CardFormProvider.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Provider view that wraps content with card form scope access and navigation handling.
///
/// Use `CardFormProvider` when embedding the card form in your own navigation hierarchy:
/// ```swift
/// CardFormProvider(
///     onSuccess: { result in
///         print("Payment succeeded: \(result.paymentId)")
///     },
///     onError: { error in
///         print("Payment failed: \(error)")
///     },
///     onCancel: {
///         print("User cancelled")
///     }
/// ) { scope in
///     CardFormScreen(scope: scope)
/// }
/// ```
///
/// Callbacks are invoked in this priority order:
/// 1. Direct callback parameters passed to this provider
/// 2. Callbacks configured in `PrimerComponents` (via environment)
///
/// If no callbacks are provided, navigation events are handled by the SDK's default behavior.
@available(iOS 15.0, *)
public struct CardFormProvider<Content: View>: View, LogReporter {
    /// Callback when payment succeeds
    private let onSuccess: ((CheckoutPaymentResult) -> Void)?

    /// Callback when payment fails
    private let onError: ((String) -> Void)?

    /// Callback when user cancels
    private let onCancel: (() -> Void)?

    /// Callback when country selection is requested
    private let onCountrySelectionRequested: (() -> Void)?

    /// Content builder that receives the card form scope
    private let content: (any PrimerCardFormScope) -> Content

    @Environment(\.primerCheckoutScope) private var checkoutScope
    @Environment(\.diContainer) private var container
    @State private var components: PrimerComponents = PrimerComponents()

    /// Creates a CardFormProvider with navigation callbacks.
    /// - Parameters:
    ///   - onSuccess: Called when payment succeeds with the result
    ///   - onError: Called when payment fails with error message
    ///   - onCancel: Called when user cancels the form
    ///   - onCountrySelectionRequested: Called when user taps country field
    ///   - content: ViewBuilder that receives the card form scope
    public init(
        onSuccess: ((CheckoutPaymentResult) -> Void)? = nil,
        onError: ((String) -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        onCountrySelectionRequested: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (any PrimerCardFormScope) -> Content
    ) {
        self.onSuccess = onSuccess
        self.onError = onError
        self.onCancel = onCancel
        self.onCountrySelectionRequested = onCountrySelectionRequested
        self.content = content
    }

    public var body: some View {
        if let checkoutScope,
           let cardFormScope = checkoutScope.getPaymentMethodScope(DefaultCardFormScope.self)
        {
            content(cardFormScope)
                .environment(\.primerCardFormScope, cardFormScope)
                .onAppear {
                    resolveComponents()
                }
                .task {
                    await observeCheckoutState()
                }
                .task {
                    await observeNavigationEvents(checkoutScope: checkoutScope)
                }
        } else {
            // Fallback when scope is not available
            Text("Card form scope not available")
                .foregroundColor(.secondary)
        }
    }

    private func resolveComponents() {
        guard let container else {
            return logger.error(message: "DIContainer not available for CardFormProvider")
        }
        do {
            components = try container.resolveSync(PrimerComponents.self)
        } catch {
            logger.error(message: "Failed to resolve PrimerComponents: \(error)")
        }
    }

    // MARK: - State Observation

    /// Observes checkout state changes and invokes appropriate callbacks.
    /// Uses iOS-native async/await pattern with AsyncStream.
    private func observeCheckoutState() async {
        guard let checkoutScope else { return }

        for await state in checkoutScope.state {
            await handleStateChange(state)
        }
    }

    /// Observes navigation events for country selection requests.
    /// Only triggers `onCountrySelectionRequested` if a direct callback is provided.
    private func observeNavigationEvents(checkoutScope: PrimerCheckoutScope) async {
        guard let onCountrySelectionRequested else { return }

        // Access the navigator through the internal checkout scope
        guard let internalScope = checkoutScope as? DefaultCheckoutScope else { return }

        for await route in internalScope.checkoutNavigator.navigationEvents {
            if case .selectCountry = route {
                await MainActor.run {
                    onCountrySelectionRequested()
                }
            }
        }
    }

    /// Handles checkout state changes by invoking the appropriate callback.
    /// Direct callbacks take precedence over PrimerComponents configuration.
    @MainActor
    private func handleStateChange(_ state: PrimerCheckoutState) {
        switch state {
        case let .success(result):
            // Direct callback takes precedence, then PrimerComponents fallback
            if let onSuccess {
                // Convert PaymentResult to CheckoutPaymentResult
                let amountString = result.amount.map { String($0) } ?? ""
                onSuccess(CheckoutPaymentResult(paymentId: result.paymentId, amount: amountString))
            } else {
                components.checkout.navigation.onSuccess?()
            }

        case let .failure(error):
            // Direct callback takes precedence, then PrimerComponents fallback
            if let onError {
                onError(error.localizedDescription)
            } else {
                components.checkout.navigation.onError?(error.localizedDescription)
            }

        case .dismissed:
            // Direct callback takes precedence, then PrimerComponents fallback
            if let onCancel {
                onCancel()
            } else {
                components.checkout.navigation.onCancel?()
            }

        case .initializing, .ready:
            // No action needed for these states
            break
        }
    }
}
