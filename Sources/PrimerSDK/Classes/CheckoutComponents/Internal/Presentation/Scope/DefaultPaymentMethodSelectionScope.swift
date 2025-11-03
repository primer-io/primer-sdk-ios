//
//  DefaultPaymentMethodSelectionScope.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default implementation of PrimerPaymentMethodSelectionScope
@available(iOS 15.0, *)
@MainActor
final class DefaultPaymentMethodSelectionScope: PrimerPaymentMethodSelectionScope, ObservableObject, LogReporter {
    // MARK: - Properties

    /// The current payment method selection state
    @Published private var internalState = PrimerPaymentMethodSelectionState()

    /// State stream for external observation
    public var state: AsyncStream<PrimerPaymentMethodSelectionState> {
        AsyncStream { continuation in
            let task = Task { @MainActor in
                for await value in $internalState.values {
                    continuation.yield(value)
                }
                continuation.finish()
            }

            continuation.onTermination = { _ in
                task.cancel()
            }
        }
    }

    /// Available dismissal mechanisms from settings
    public var dismissalMechanism: [DismissalMechanism] {
        checkoutScope?.dismissalMechanism ?? []
    }

    // MARK: - UI Customization Properties

    public var screen: (() -> AnyView)?
    public var container: ((_ content: @escaping () -> AnyView) -> AnyView)?
    public var paymentMethodItem: ((_ paymentMethod: CheckoutPaymentMethod) -> AnyView)?
    public var categoryHeader: ((_ category: String) -> AnyView)?
    public var emptyStateView: (() -> AnyView)?

    // MARK: - Private Properties

    private weak var checkoutScope: DefaultCheckoutScope?
    private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
    private var accessibilityAnnouncementService: AccessibilityAnnouncementService?

    // MARK: - Initialization

    init(
        checkoutScope: DefaultCheckoutScope,
        analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
    ) {
        self.checkoutScope = checkoutScope
        self.analyticsInteractor = analyticsInteractor

        Task {
            await loadPaymentMethods()
            await resolveAccessibilityService()
        }
    }

    // MARK: - Accessibility Setup

    private func resolveAccessibilityService() async {
        do {
            guard let container = await DIContainer.current else { return }
            accessibilityAnnouncementService = try await container.resolve(AccessibilityAnnouncementService.self)
        } catch {
            // Failed to resolve AccessibilityAnnouncementService, accessibility announcements will be disabled
            logger.debug(message: "[A11Y] Failed to resolve AccessibilityAnnouncementService: \(error.localizedDescription)")
        }
    }

    // MARK: - Setup

    private func loadPaymentMethods() async {
        // Get payment methods from the checkout scope instead of loading them again
        guard let checkoutScope = checkoutScope else {
            // Checkout scope not available
            internalState.error = CheckoutComponentsStrings.checkoutScopeNotAvailable
            return
        }

        // Wait for the checkout scope to have loaded payment methods
        for await checkoutState in checkoutScope.state {
            if case .ready = checkoutState {
                // Get payment methods directly from the checkout scope
                let paymentMethods = checkoutScope.availablePaymentMethods
                // Retrieved payment methods from checkout scope

                // Convert internal payment methods to composable payment methods using PaymentMethodMapper
                let mapper: PaymentMethodMapper
                do {
                    guard let container = await DIContainer.current else {
                        throw NSError(domain: "DIContainer", code: 1, userInfo: [NSLocalizedDescriptionKey: "DIContainer.current is nil"])
                    }
                    mapper = try await container.resolve(PaymentMethodMapper.self)
                } catch {
                    // Failed to resolve PaymentMethodMapper
                    // Fallback to manual creation without surcharge data
                    let composablePaymentMethods = paymentMethods.map { method in
                        CheckoutPaymentMethod(
                            id: method.id,
                            type: method.type,
                            name: method.name,
                            icon: method.icon,
                            metadata: nil
                        )
                    }
                    internalState.paymentMethods = composablePaymentMethods
                    internalState.filteredPaymentMethods = composablePaymentMethods
                    // Payment methods loaded successfully (without surcharge)
                    break
                }

                // Use PaymentMethodMapper to properly format surcharge data
                let composablePaymentMethods = mapper.mapToPublic(paymentMethods)

                internalState.paymentMethods = composablePaymentMethods
                internalState.filteredPaymentMethods = composablePaymentMethods

                // Payment methods loaded successfully with surcharge data
                break
            } else if case let .failure(error) = checkoutState {
                // Checkout scope has error
                internalState.error = error.localizedDescription
                break
            }
        }
    }

    // MARK: - Public Methods

    public func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod) {
        // Payment method selected

        internalState.selectedPaymentMethod = paymentMethod

        // Announce selection to VoiceOver users
        let selectionMessage = "\(paymentMethod.name) selected"
        accessibilityAnnouncementService?.announceStateChange(selectionMessage)
        logger.debug(message: "[A11Y] Payment method selected announcement: \(selectionMessage)")

        // Track payment method selection
        Task {
            await trackPaymentMethodSelection(paymentMethod.type)
        }

        // Notify checkout scope
        let internalMethod = InternalPaymentMethod(
            id: paymentMethod.id,
            type: paymentMethod.type,
            name: paymentMethod.name,
            icon: paymentMethod.icon
        )

        checkoutScope?.handlePaymentMethodSelection(internalMethod)
    }

    private func trackPaymentMethodSelection(_ paymentMethodType: String) async {
        await analyticsInteractor?.trackEvent(.paymentMethodSelection, metadata: .payment(PaymentEvent(paymentMethod: paymentMethodType)))
    }

    public func onCancel() {
        // Payment method selection cancelled
        // Navigate back or dismiss
        checkoutScope?.onDismiss()
    }

    public func searchPaymentMethods(_ query: String) {
        // Searching payment methods

        internalState.searchQuery = query

        if query.isEmpty {
            internalState.filteredPaymentMethods = internalState.paymentMethods
        } else {
            let lowercasedQuery = query.lowercased()
            internalState.filteredPaymentMethods = internalState.paymentMethods.filter { method in
                method.name.lowercased().contains(lowercasedQuery) ||
                    method.type.lowercased().contains(lowercasedQuery)
            }
        }
    }

}
