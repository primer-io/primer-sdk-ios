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
        case failure(PrimerError)
        // Note: Success case removed - CheckoutComponents dismisses immediately on success
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
    public var errorScreen: ((_ message: String) -> AnyView)?
    public var paymentMethodSelectionScreen: ((_ scope: PrimerPaymentMethodSelectionScope) -> AnyView)?
    public var cardFormScreen: ((_ scope: PrimerCardFormScope) -> AnyView)?

    // MARK: - State Management
    // Note: Success result is no longer stored - delegate is called immediately on success

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
    internal var availablePaymentMethods: [InternalPaymentMethod] = []

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

        // Observe navigation events for back navigation
        observeNavigationEvents()
    }

    // MARK: - Setup

    private func setupInteractors() async {
        logger.info(message: "🔧 [CheckoutComponents] Setting up interactors...")
        do {
            logger.debug(message: "🔍 [CheckoutComponents] Checking DI container availability...")
            guard let container = await DIContainer.current else {
                logger.error(message: "❌ [CheckoutComponents] DI Container is not available")
                throw ContainerError.containerUnavailable
            }
            logger.info(message: "✅ [CheckoutComponents] DI Container found")

            // TODO: Implement proper interactor resolution when available
            // For now, create a bridge to existing SDK payment methods
            logger.info(message: "🌉 [CheckoutComponents] Creating bridge to existing SDK payment methods")
            getPaymentMethodsInteractor = CheckoutComponentsPaymentMethodsBridge()

            logger.info(message: "✅ [CheckoutComponents] Interactor setup completed with bridge")
        } catch {
            logger.error(message: "❌ [CheckoutComponents] Failed to setup interactors: \(error)")
            logger.error(message: "❌ [CheckoutComponents] Error type: \(type(of: error))")
            let primerError = PrimerError.unknown(
                userInfo: ["setupError": error.localizedDescription],
                diagnosticsId: UUID().uuidString
            )
            updateNavigationState(.failure(primerError))
            updateState(.failure(primerError))
        }
    }

    private func loadPaymentMethods() async {
        logger.info(message: "🔄 [CheckoutComponents] Starting payment methods loading...")
        updateNavigationState(.loading)

        do {
            // Add a small delay to ensure SDK configuration is fully loaded
            logger.debug(message: "⏳ [CheckoutComponents] Waiting for SDK configuration to be ready...")
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            logger.debug(message: "🔍 [CheckoutComponents] Checking payment methods interactor...")
            guard let interactor = getPaymentMethodsInteractor else {
                logger.error(message: "❌ [CheckoutComponents] GetPaymentMethodsInteractor is nil - DI resolution failed")
                throw PrimerError.unknown(
                    userInfo: ["error": "GetPaymentMethodsInteractor not resolved"],
                    diagnosticsId: UUID().uuidString
                )
            }

            logger.info(message: "✅ [CheckoutComponents] Payment methods interactor found, executing...")
            availablePaymentMethods = try await interactor.execute()

            logger.info(message: "📊 [CheckoutComponents] Retrieved \(availablePaymentMethods.count) payment methods")

            // Log each payment method for debugging
            for (index, method) in availablePaymentMethods.enumerated() {
                logger.debug(message: "💳 [CheckoutComponents] Payment Method \(index + 1): \(method.type ?? "unknown") - \(method.name ?? "unnamed")")
            }

            if availablePaymentMethods.isEmpty {
                logger.error(message: "❌ [CheckoutComponents] No payment methods available")
                let error = PrimerError.unknown(
                    userInfo: ["error": "No payment methods available"],
                    diagnosticsId: UUID().uuidString
                )
                updateNavigationState(.failure(error))
                updateState(.failure(error))
            } else {
                logger.info(message: "✅ [CheckoutComponents] Payment methods loaded successfully")
                updateState(.ready)

                // Check if we have only card payment method
                if availablePaymentMethods.count == 1,
                   availablePaymentMethods.first?.type == "PAYMENT_CARD" {
                    logger.info(message: "🎯 [CheckoutComponents] Single card payment method detected, navigating to card form")
                    updateNavigationState(.cardForm)
                } else {
                    logger.info(message: "🎯 [CheckoutComponents] Multiple payment methods available, showing selection screen")
                    updateNavigationState(.paymentMethodSelection)
                }
            }
        } catch {
            logger.error(message: "❌ [CheckoutComponents] Failed to load payment methods: \(error)")
            logger.error(message: "❌ [CheckoutComponents] Error type: \(type(of: error))")
            logger.error(message: "❌ [CheckoutComponents] Error description: \(error.localizedDescription)")

            let primerError = error as? PrimerError ?? PrimerError.unknown(
                userInfo: ["originalError": error.localizedDescription],
                diagnosticsId: UUID().uuidString
            )
            updateNavigationState(.failure(primerError))
            updateState(.failure(primerError))
        }
    }

    // MARK: - State Management

    private func updateState(_ newState: PrimerCheckoutState) {
        logger.debug(message: "Checkout state updating to: \(newState)")
        internalState = newState
    }

    private func updateNavigationState(_ newState: NavigationState, syncToNavigator: Bool = true) {
        logger.debug(message: "Navigation state updating to: \(newState)")
        navigationState = newState

        // Update navigation based on state (only if not syncing from navigator to avoid loops)
        if syncToNavigator {
            switch newState {
            case .loading:
                navigator.navigateToLoading()
            case .paymentMethodSelection:
                navigator.navigateToPaymentSelection()
            case .cardForm:
                navigator.navigateToCardForm()
            case .failure(let error):
                navigator.navigateToError(error.localizedDescription)
            }
        }
    }

    // MARK: - Navigation Events Observer

    private func observeNavigationEvents() {
        Task { @MainActor in
            logger.debug(message: "🔍 [CheckoutComponents] Starting navigation events observer")
            for await route in navigator.navigationEvents {
                logger.debug(message: "🧭 [CheckoutComponents] Received navigation event: \(route)")

                // Sync internal navigation state with the navigator's current route
                let newNavigationState: NavigationState
                switch route {
                case .loading:
                    newNavigationState = .loading
                case .paymentMethodSelection:
                    newNavigationState = .paymentMethodSelection
                case .cardForm:
                    newNavigationState = .cardForm
                case .failure(let checkoutError):
                    let primerError = PrimerError.unknown(
                        userInfo: ["error": checkoutError.message, "code": checkoutError.code],
                        diagnosticsId: UUID().uuidString
                    )
                    newNavigationState = .failure(primerError)
                default:
                    // For any other routes, keep current state
                    continue
                }

                // Only update if the state has actually changed to avoid loops
                if case let .failure(currentError) = navigationState,
                   case let .failure(newError) = newNavigationState {
                    // For error states, compare messages to avoid redundant updates
                    if currentError.localizedDescription != newError.localizedDescription {
                        logger.debug(message: "🔄 [CheckoutComponents] Navigation state synced from navigator: \(newNavigationState)")
                        updateNavigationState(newNavigationState, syncToNavigator: false)
                    }
                } else if !navigationStateEquals(navigationState, newNavigationState) {
                    logger.debug(message: "🔄 [CheckoutComponents] Navigation state synced from navigator: \(newNavigationState)")
                    updateNavigationState(newNavigationState, syncToNavigator: false)
                }
            }
        }
    }

    private func navigationStateEquals(_ lhs: NavigationState, _ rhs: NavigationState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
             (.paymentMethodSelection, .paymentMethodSelection),
             (.cardForm, .cardForm):
            return true
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }

    // MARK: - Public Methods

    public func onDismiss() {
        logger.debug(message: "Checkout dismissed")

        // Update state to dismissed
        updateState(.dismissed)

        // Clean up any resources
        _cardForm = nil
        _paymentMethodSelection = nil

        // Navigate to dismiss the checkout
        navigator.dismiss()
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
        logger.info(message: "Payment successful: \(result.paymentId)")

        // For CheckoutComponents, notify CheckoutComponentsPrimer to handle success and dismissal
        // This matches the expected flow: CheckoutComponents dismisses → delegate presents result screen
        logger.info(message: "Payment successful, notifying CheckoutComponentsPrimer to handle success and dismissal")

        // Update state to success for any listeners
        updateState(.success(result))

        // Notify CheckoutComponentsPrimer about success with the actual payment result
        CheckoutComponentsPrimer.shared.handlePaymentSuccess(result)
    }

    internal func handlePaymentError(_ error: PrimerError) {
        logger.error(message: "Payment error: \\(error)")

        // Notify CheckoutComponentsPrimer about the failure
        // This will propagate to PrimerUIManager to show the error screen
        logger.info(message: "Notifying CheckoutComponentsPrimer about payment failure")
        CheckoutComponentsPrimer.shared.handlePaymentFailure(error)

        updateNavigationState(.failure(error))
        updateState(.failure(error))
    }
}
