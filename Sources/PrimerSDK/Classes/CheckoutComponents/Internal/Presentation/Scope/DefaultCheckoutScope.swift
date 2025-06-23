//
//  DefaultCheckoutScope.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// Default implementation of PrimerCheckoutScope
@available(iOS 15.0, *)
@MainActor
internal final class DefaultCheckoutScope: PrimerCheckoutScope, ObservableObject, LogReporter {
    // MARK: - Internal Navigation State

    internal enum NavigationState {
        case loading
        case paymentMethodSelection
        case cardForm
        case success(PaymentResult)
        case failure(PrimerError)
    }

    // MARK: - Properties

    /// The current checkout state
    @Published private var internalState = PrimerCheckoutState.initializing

    /// The current navigation state
    @Published internal var navigationState = NavigationState.loading

    /// State stream for external observation
    public var state: AsyncStream<PrimerCheckoutState> {
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

    public var container: ((_ content: @escaping () -> AnyView) -> AnyView)?
    public var splashScreen: (() -> AnyView)?
    public var loadingScreen: (() -> AnyView)?
    public var successScreen: (() -> AnyView)?
    public var errorScreen: ((_ message: String) -> AnyView)?
    public var paymentMethodSelectionScreen: ((_ scope: PrimerPaymentMethodSelectionScope) -> AnyView)?
    public var cardFormScreen: ((_ scope: PrimerCardFormScope) -> AnyView)?

    // MARK: - Child Scopes

    private var _cardForm: PrimerCardFormScope?
    public var cardForm: PrimerCardFormScope {
        if let existing = _cardForm {
            return existing
        }
        let scope = DefaultCardFormScope(checkoutScope: self)
        _cardForm = scope
        return scope
    }

    private var _paymentMethodSelection: PrimerPaymentMethodSelectionScope?
    public var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
        if let existing = _paymentMethodSelection {
            return existing
        }
        let scope = DefaultPaymentMethodSelectionScope(checkoutScope: self)
        _paymentMethodSelection = scope
        return scope
    }

    // MARK: - Services

    internal let diContainer: DIContainer
    private let navigator: CheckoutNavigator
    private var getPaymentMethodsInteractor: GetPaymentMethodsInteractor?

    // MARK: - Internal Access

    /// Provides access to the navigator for child scopes
    internal var checkoutNavigator: CheckoutNavigator {
        navigator
    }

    // MARK: - Other Properties

    private let clientToken: String
    private let settings: PrimerSettings
    private var availablePaymentMethods: [InternalPaymentMethod] = []

    // MARK: - Initialization

    init(clientToken: String, settings: PrimerSettings, diContainer: DIContainer, navigator: CheckoutNavigator) {
        self.clientToken = clientToken
        self.settings = settings
        self.diContainer = diContainer
        self.navigator = navigator

        Task {
            await setupInteractors()
            await loadPaymentMethods()
        }
    }

    // MARK: - Setup

    private func setupInteractors() async {
        do {
            guard let container = await DIContainer.current else {
                throw ContainerError.containerUnavailable
            }
            // getPaymentMethodsInteractor = try await container.resolve(GetPaymentMethodsInteractor.self)
        } catch {
            logger.error(message: "Failed to setup interactors: \\(error)")
            let primerError = PrimerError.unknown(
                userInfo: nil,
                diagnosticsId: UUID().uuidString
            )
            updateNavigationState(.failure(primerError))
            updateState(.failure(primerError))
        }
    }

    private func loadPaymentMethods() async {
        updateNavigationState(.loading)

        do {
            guard let interactor = getPaymentMethodsInteractor else {
                throw PrimerError.unknown(
                    userInfo: nil,
                    diagnosticsId: UUID().uuidString
                )
            }

            availablePaymentMethods = try await interactor.execute()

            if availablePaymentMethods.isEmpty {
                let error = PrimerError.unknown(
                    userInfo: nil,
                    diagnosticsId: UUID().uuidString
                )
                updateNavigationState(.failure(error))
                updateState(.failure(error))
            } else {
                updateState(.ready)

                // Check if we have only card payment method
                if availablePaymentMethods.count == 1,
                   availablePaymentMethods.first?.type == "PAYMENT_CARD" {
                    // Go directly to card form
                    updateNavigationState(.cardForm)
                } else {
                    // Show payment method selection
                    updateNavigationState(.paymentMethodSelection)
                }
            }
        } catch {
            logger.error(message: "Failed to load payment methods: \\(error)")
            let primerError = error as? PrimerError ?? PrimerError.unknown(
                userInfo: nil,
                diagnosticsId: UUID().uuidString
            )
            updateNavigationState(.failure(primerError))
            updateState(.failure(primerError))
        }
    }

    // MARK: - State Management

    private func updateState(_ newState: PrimerCheckoutState) {
        logger.debug(message: "Checkout state updating to: \\(newState)")
        internalState = newState
    }

    private func updateNavigationState(_ newState: NavigationState) {
        logger.debug(message: "Navigation state updating to: \\(newState)")
        navigationState = newState

        // Update navigation based on state
        switch newState {
        case .loading:
            navigator.navigateToLoading()
        case .paymentMethodSelection:
            navigator.navigateToPaymentSelection()
        case .cardForm:
            navigator.navigateToCardForm()
        case .success:
            navigator.navigateToSuccess()
        case .failure(let error):
            navigator.navigateToError(error.localizedDescription)
        }
    }

    // MARK: - Public Methods

    public func onDismiss() {
        logger.debug(message: "Checkout dismissed")
        // Clean up any resources
        _cardForm = nil
        _paymentMethodSelection = nil

        // Notify parent
        // This would be handled by the parent view controller
    }

    // MARK: - Internal Methods

    internal func handlePaymentMethodSelection(_ method: InternalPaymentMethod) {
        logger.debug(message: "Payment method selected: \\(method.type)")

        switch method.type {
        case "PAYMENT_CARD":
            updateNavigationState(.cardForm)
        default:
            // For now, only card is supported
            logger.warn(message: "Unsupported payment method: \\(method.type)")
        }
    }

    internal func handlePaymentSuccess(_ result: PaymentResult) {
        logger.debug(message: "Payment successful")
        updateNavigationState(.success(result))
    }

    internal func handlePaymentError(_ error: PrimerError) {
        logger.error(message: "Payment error: \\(error)")
        updateNavigationState(.failure(error))
        updateState(.failure(error))
    }
}
