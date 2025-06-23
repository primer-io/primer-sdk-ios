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
internal final class DefaultPaymentMethodSelectionScope: PrimerPaymentMethodSelectionScope, ObservableObject, LogReporter {
    // MARK: - Properties

    /// The current payment method selection state
    @Published private var internalState = PrimerPaymentMethodSelectionScope.State()

    /// State stream for external observation
    public var state: AsyncStream<PrimerPaymentMethodSelectionScope.State> {
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

    public var container: (@ViewBuilder (_ content: @escaping () -> any View) -> any View)?
    public var paymentMethodItem: (@ViewBuilder (_ paymentMethod: PrimerComposablePaymentMethod) -> any View)?
    public var searchBar: (@ViewBuilder (_ searchText: @escaping (String) -> Void) -> any View)?
    public var categoryHeader: (@ViewBuilder (_ category: String) -> any View)?
    public var emptyStateView: (@ViewBuilder () -> any View)?

    // MARK: - Private Properties

    private weak var checkoutScope: DefaultCheckoutScope?
    private let diContainer: DIContainer
    private var getPaymentMethodsInteractor: GetPaymentMethodsInteractor?

    // MARK: - Initialization

    init(checkoutScope: DefaultCheckoutScope) {
        self.checkoutScope = checkoutScope
        self.diContainer = DIContainer.global

        Task {
            await setupInteractors()
            await loadPaymentMethods()
        }
    }

    // MARK: - Setup

    private func setupInteractors() async {
        do {
            getPaymentMethodsInteractor = try await diContainer.resolve(GetPaymentMethodsInteractor.self)
        } catch {
            log(logLevel: .error, message: "Failed to setup interactors: \\(error)")
        }
    }

    private func loadPaymentMethods() async {
        do {
            guard let interactor = getPaymentMethodsInteractor else {
                throw PrimerError.failedToLoadAvailablePaymentMethods(
                    userInfo: .errorUserInfoDictionary(),
                    diagnosticsId: UUID().uuidString
                )
            }

            let paymentMethods = try await interactor.execute()

            // Convert internal payment methods to composable payment methods
            let composablePaymentMethods = paymentMethods.map { method in
                PrimerComposablePaymentMethod(
                    id: method.id,
                    type: method.type,
                    name: method.name,
                    displayName: method.displayName,
                    logo: method.logo,
                    isEnabled: method.isEnabled
                )
            }

            internalState.paymentMethods = composablePaymentMethods

            // Group by category if needed
            updateCategories()

        } catch {
            log(logLevel: .error, message: "Failed to load payment methods: \\(error)")
            internalState.error = error.localizedDescription
        }
    }

    // MARK: - Public Methods

    public func onPaymentMethodSelected(_ paymentMethod: PrimerComposablePaymentMethod) {
        log(logLevel: .debug, message: "Payment method selected: \\(paymentMethod.type)")

        internalState.selectedPaymentMethod = paymentMethod

        // Notify checkout scope
        let internalMethod = InternalPaymentMethod(
            id: paymentMethod.id,
            type: paymentMethod.type,
            name: paymentMethod.name,
            displayName: paymentMethod.displayName,
            logo: paymentMethod.logo,
            config: nil
        )

        checkoutScope?.handlePaymentMethodSelection(internalMethod)
    }

    public func searchPaymentMethods(_ query: String) {
        log(logLevel: .debug, message: "Searching payment methods with query: \\(query)")

        internalState.searchQuery = query

        if query.isEmpty {
            internalState.filteredPaymentMethods = internalState.paymentMethods
        } else {
            let lowercasedQuery = query.lowercased()
            internalState.filteredPaymentMethods = internalState.paymentMethods.filter { method in
                method.displayName.lowercased().contains(lowercasedQuery) ||
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
