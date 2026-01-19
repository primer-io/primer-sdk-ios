//
//  PaymentMethodSelectionProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Provider view that wraps content with payment method selection scope access and navigation handling.
///
/// Use `PaymentMethodSelectionProvider` when embedding payment selection in your own navigation hierarchy:
/// ```swift
/// PaymentMethodSelectionProvider(
///     onPaymentMethodSelected: { paymentMethodType in
///         print("Selected: \(paymentMethodType)")
///         // Navigate to payment method screen
///     },
///     onCancel: {
///         print("User cancelled")
///     }
/// ) { scope in
///     PaymentMethodSelectionScreen(scope: scope)
/// }
/// ```
///
/// Callbacks are invoked when provided. If no callbacks are provided, navigation events
/// are handled by the SDK's default behavior.
@available(iOS 15.0, *)
public struct PaymentMethodSelectionProvider<Content: View>: View, LogReporter {
    private let onPaymentMethodSelected: ((String) -> Void)?
    private let onCancel: (() -> Void)?
    private let content: (any PrimerPaymentMethodSelectionScope) -> Content

    @Environment(\.primerCheckoutScope) private var checkoutScope
    @State private var lastSelectedPaymentMethodType: String?

    /// Creates a PaymentMethodSelectionProvider.
    /// - Parameters:
    ///   - onPaymentMethodSelected: Called when user selects a payment method with the type identifier
    ///   - onCancel: Called when user cancels the selection
    ///   - content: ViewBuilder that receives the payment method selection scope
    public init(
        onPaymentMethodSelected: ((String) -> Void)? = nil,
        onCancel: (() -> Void)? = nil,
        @ViewBuilder content: @escaping (any PrimerPaymentMethodSelectionScope) -> Content
    ) {
        self.onPaymentMethodSelected = onPaymentMethodSelected
        self.onCancel = onCancel
        self.content = content
    }

    public var body: some View {
        if let checkoutScope {
            let selectionScope = checkoutScope.paymentMethodSelection
            content(selectionScope)
                .environment(\.primerPaymentMethodSelectionScope, selectionScope)
                .task {
                    await observePaymentMethodSelection(selectionScope: selectionScope)
                }
                .task {
                    await observeCheckoutState()
                }
        } else {
            // Fallback when scope is not available
            Text("Payment selection scope not available")
                .foregroundColor(.secondary)
        }
    }

    // MARK: - State Observation

    /// Observes payment method selection state changes and invokes appropriate callbacks.
    /// Uses iOS-native async/await pattern with AsyncStream.
    private func observePaymentMethodSelection(selectionScope: PrimerPaymentMethodSelectionScope) async {
        for await state in selectionScope.state {
            await handleSelectionStateChange(state)
        }
    }

    /// Observes checkout state for cancel/dismiss events.
    private func observeCheckoutState() async {
        guard let checkoutScope else { return }

        for await state in checkoutScope.state {
            await handleCheckoutStateChange(state)
        }
    }

    /// Handles payment method selection state changes.
    @MainActor
    private func handleSelectionStateChange(_ state: PrimerPaymentMethodSelectionState) {
        // Check if a NEW payment method was selected (different from last seen)
        if let selectedMethod = state.selectedPaymentMethod,
           selectedMethod.type != lastSelectedPaymentMethodType {
            lastSelectedPaymentMethodType = selectedMethod.type
            onPaymentMethodSelected?(selectedMethod.type)
        }
    }

    /// Handles checkout state changes for cancel detection.
    @MainActor
    private func handleCheckoutStateChange(_ state: PrimerCheckoutState) {
        if case .dismissed = state {
            onCancel?()
        }
    }
}
