//
//  DefaultPaymentMethodSelectionScope.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

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

    // MARK: - UI Customization Properties

    public var screen: (() -> AnyView)?
    public var container: ((_ content: @escaping () -> AnyView) -> AnyView)?
    public var paymentMethodItem: ((_ paymentMethod: PrimerComposablePaymentMethod) -> AnyView)?
    public var categoryHeader: ((_ category: String) -> AnyView)?
    public var emptyStateView: (() -> AnyView)?

    // MARK: - Private Properties

    private weak var checkoutScope: DefaultCheckoutScope?
    private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

    // MARK: - Initialization

    init(
        checkoutScope: DefaultCheckoutScope,
        analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
    ) {
        self.checkoutScope = checkoutScope
        self.analyticsInteractor = analyticsInteractor

        Task {
            await loadPaymentMethods()
        }
    }

    // MARK: - Setup

    private func loadPaymentMethods() async {
        // Loading payment methods from checkout scope...

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
                        PrimerComposablePaymentMethod(
                            id: method.id,
                            type: method.type,
                            name: method.name,
                            icon: method.icon,
                            metadata: nil
                        )
                    }
                    internalState.paymentMethods = composablePaymentMethods
                    internalState.filteredPaymentMethods = composablePaymentMethods
                    updateCategories()
                    // Payment methods loaded and categorized successfully (without surcharge)
                    break
                }

                // Use PaymentMethodMapper to properly format surcharge data
                let composablePaymentMethods = mapper.mapToPublic(paymentMethods)

                internalState.paymentMethods = composablePaymentMethods
                internalState.filteredPaymentMethods = composablePaymentMethods

                // Group by category if needed
                updateCategories()

                // Payment methods loaded and categorized successfully with surcharge data
                break
            } else if case let .failure(error) = checkoutState {
                // Checkout scope has error
                internalState.error = error.localizedDescription
                break
            }
        }
    }

    // MARK: - Public Methods

    public func onPaymentMethodSelected(paymentMethod: PrimerComposablePaymentMethod) {
        // Payment method selected

        internalState.selectedPaymentMethod = paymentMethod

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

        updateCategories()
    }

    // MARK: - Private Methods

    private func updateCategories() {
        // Group payment methods by category
        // For now, we'll use simple categories based on payment method type
        var categorizedMethods: [(category: String, methods: [PrimerComposablePaymentMethod])] = []

        let methodsToGroup = internalState.searchQuery.isEmpty
            ? internalState.paymentMethods
            : internalState.filteredPaymentMethods

        // Cards category
        let cardMethods = methodsToGroup.filter {
            $0.type.contains("CARD") || $0.type == "PAYMENT_CARD"
        }
        if !cardMethods.isEmpty {
            categorizedMethods.append((category: "Cards", methods: cardMethods))
        }

        // Wallets category
        let walletMethods = methodsToGroup.filter {
            ["PAYPAL", "APPLE_PAY", "GOOGLE_PAY"].contains($0.type)
        }
        if !walletMethods.isEmpty {
            categorizedMethods.append((category: "Digital Wallets", methods: walletMethods))
        }

        // Bank transfers category
        let bankMethods = methodsToGroup.filter {
            $0.type.contains("BANK") || $0.type.contains("SEPA") || $0.type.contains("ACH")
        }
        if !bankMethods.isEmpty {
            categorizedMethods.append((category: "Bank Transfers", methods: bankMethods))
        }

        // Other payment methods
        let categorizedTypes = Set(cardMethods.map { $0.type } +
                                    walletMethods.map { $0.type } +
                                    bankMethods.map { $0.type })
        let otherMethods = methodsToGroup.filter { !categorizedTypes.contains($0.type) }
        if !otherMethods.isEmpty {
            categorizedMethods.append((category: "Other Payment Methods", methods: otherMethods))
        }

        internalState.categorizedPaymentMethods = categorizedMethods
    }
}
