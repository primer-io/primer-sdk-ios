//
//  DefaultCheckoutScope.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Default implementation of PrimerCheckoutScope
@available(iOS 15.0, *)
@MainActor
final class DefaultCheckoutScope: PrimerCheckoutScope, ObservableObject, LogReporter {
    // MARK: - Internal Navigation State

    enum NavigationState: Equatable {
        case loading
        case paymentMethodSelection
        case paymentMethod(String)  // Dynamic payment method with type identifier
        case selectCountry  // Country selection screen
        case success(CheckoutPaymentResult)
        case failure(PrimerError)
        case dismissed

        static func == (lhs: NavigationState, rhs: NavigationState) -> Bool {
            switch (lhs, rhs) {
            case (.loading, .loading):
                return true
            case (.paymentMethodSelection, .paymentMethodSelection):
                return true
            case (.selectCountry, .selectCountry):
                return true
            case (.dismissed, .dismissed):
                return true
            case let (.paymentMethod(lhsType), .paymentMethod(rhsType)):
                return lhsType == rhsType
            case let (.success(lhsResult), .success(rhsResult)):
                return lhsResult.paymentId == rhsResult.paymentId
            case let (.failure(lhsError), .failure(rhsError)):
                return lhsError.localizedDescription == rhsError.localizedDescription
            default:
                return false
            }
        }
    }

    // MARK: - Properties

    /// The current checkout state
    @Published private var internalState = PrimerCheckoutState.initializing

    /// The current navigation state
    @Published var navigationState = NavigationState.loading

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

    public var container: ((_ content: @escaping () -> AnyView) -> any View)?
    public var splashScreen: (() -> any View)?
    public var loadingScreen: (() -> any View)?
    public var successScreen: ((_ result: CheckoutPaymentResult) -> AnyView)?
    public var errorScreen: ((_ message: String) -> any View)?
    public var paymentMethodSelectionScreen: ((_ scope: PrimerPaymentMethodSelectionScope) -> AnyView)?

    // Removed: paymentMethodScreens - now using PaymentMethodProtocol.content()

    // MARK: - Child Scopes

    private var _paymentMethodSelection: PrimerPaymentMethodSelectionScope?
    public var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
        if let existing = _paymentMethodSelection {
            return existing
        }
        let scope = DefaultPaymentMethodSelectionScope(
            checkoutScope: self,
            analyticsInteractor: analyticsInteractor
        )
        _paymentMethodSelection = scope
        return scope
    }

    // MARK: - Dynamic Payment Method Scope

    /// The currently active payment method scope (dynamically created)
    private var currentPaymentMethodScope: (any PrimerPaymentMethodScope)?

    /// Cache of created payment method scopes by type
    private var paymentMethodScopeCache: [String: any PrimerPaymentMethodScope] = [:]

    // MARK: - Services

    private let navigator: CheckoutNavigator
    private var paymentMethodsInteractor: GetPaymentMethodsInteractor?
    private var analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

    // MARK: - Internal Access

    /// Provides access to the navigator for child scopes
    var checkoutNavigator: CheckoutNavigator {
        navigator
    }

    // MARK: - Other Properties

    private let clientToken: String
    private let settings: PrimerSettings
    var availablePaymentMethods: [InternalPaymentMethod] = []

    // MARK: - UI Settings Access (for settings-based screen control)

    /// Whether the initialization loading screen should be shown
    var isInitScreenEnabled: Bool {
        settings.uiOptions.isInitScreenEnabled
    }

    /// Whether the success screen should be shown after successful payment
    var isSuccessScreenEnabled: Bool {
        settings.uiOptions.isSuccessScreenEnabled
    }

    /// Whether the error screen should be shown after failed payment
    var isErrorScreenEnabled: Bool {
        settings.uiOptions.isErrorScreenEnabled
    }

    /// Exposes card form UI options for child scopes
    var cardFormUIOptions: PrimerCardFormUIOptions? {
        settings.uiOptions.cardFormUIOptions
    }

    /// Available dismissal mechanisms (gestures, close button)
    var dismissalMechanism: [DismissalMechanism] {
        settings.uiOptions.dismissalMechanism
    }

    // MARK: - Debug Settings Access (critical for 3DS security)

    /// Whether 3DS sanity checks are enabled (CRITICAL for security in production)
    var is3DSSanityCheckEnabled: Bool {
        settings.debugOptions.is3DSSanityCheckEnabled
    }

    // MARK: - Payment Settings

    /// Payment handling mode from settings
    public var paymentHandling: PrimerPaymentHandling {
        settings.paymentHandling
    }

    /// The presentation context for navigation behavior
    let presentationContext: PresentationContext

    // MARK: - Initialization

    init(clientToken: String, settings: PrimerSettings, diContainer: DIContainer, navigator: CheckoutNavigator, presentationContext: PresentationContext = .fromPaymentSelection) {
        self.clientToken = clientToken
        self.settings = settings
        self.navigator = navigator
        self.presentationContext = presentationContext

        // Register payment methods with the registry
        registerPaymentMethods()

        Task {
            await setupInteractors()
            await loadPaymentMethods()
        }

        // Observe navigation events for back navigation
        observeNavigationEvents()
    }

    /// Registers all available payment method implementations with the registry
    @MainActor
    private func registerPaymentMethods() {
        // Register card payment method
        CardPaymentMethod.register()

        // Registered payment methods
    }

    // MARK: - Setup

    private func setupInteractors() async {
        // Setting up interactors...
        do {
            // Checking DI container availability...
            guard let container = await DIContainer.current else {
                // DI Container is not available
                throw ContainerError.containerUnavailable
            }
            // DI Container found

            // Creating bridge to existing SDK payment methods
            paymentMethodsInteractor = CheckoutComponentsPaymentMethodsBridge()

            // Resolve analytics interactor
            analyticsInteractor = try? await container.resolve(CheckoutComponentsAnalyticsInteractorProtocol.self)

            // Interactor setup completed with bridge
        } catch {
            // Failed to setup interactors
            // Error type logged
            let primerError = PrimerError.invalidArchitecture(
                description: "Failed to setup interactors: \(error.localizedDescription)",
                recoverSuggestion: "Ensure proper SDK initialization"
            )
            updateNavigationState(.failure(primerError))
            updateState(.failure(primerError))
        }
    }

    private func loadPaymentMethods() async {
        // Starting payment methods loading...

        // Only show loading screen if enabled in settings (UI Options integration)
        if settings.uiOptions.isInitScreenEnabled {
            updateNavigationState(.loading)
            // Init screen enabled - showing loading state
        } else {
            // Init screen disabled - skipping loading state
        }

        do {
            // Add a small delay to ensure SDK configuration is fully loaded
            // Waiting for SDK configuration to be ready...
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            // Checking payment methods interactor...
            guard let interactor = paymentMethodsInteractor else {
                // GetPaymentMethodsInteractor is nil - DI resolution failed
                throw PrimerError.invalidArchitecture(
                    description: "GetPaymentMethodsInteractor not resolved",
                    recoverSuggestion: "Ensure proper SDK initialization and dependency injection setup"
                )
            }

            // Payment methods interactor found, executing...
            availablePaymentMethods = try await interactor.execute()

            // Retrieved payment methods

            // Log each payment method for debugging
            for (index, method) in availablePaymentMethods.enumerated() {
                // Payment Method details
            }

            if availablePaymentMethods.isEmpty {
                // No payment methods available
                let error = PrimerError.missingPrimerConfiguration()
                updateNavigationState(.failure(error))
                updateState(.failure(error))
            } else {
                // Payment methods loaded successfully
                updateState(.ready)

                // Check if we have only one payment method (any type)
                if availablePaymentMethods.count == 1,
                   let singlePaymentMethod = availablePaymentMethods.first {
                    // Single payment method detected, navigating directly
                    updateNavigationState(.paymentMethod(singlePaymentMethod.type))
                } else {
                    // Multiple payment methods available, showing selection screen
                    updateNavigationState(.paymentMethodSelection)
                }
            }
        } catch {
            // Failed to load payment methods
            // Error type logged
            // Error description logged

            let primerError = error as? PrimerError ?? PrimerError.unknown(
                message: error.localizedDescription
            )
            updateNavigationState(.failure(primerError))
            updateState(.failure(primerError))
        }
    }

    // MARK: - State Management

    private func updateState(_ newState: PrimerCheckoutState) {
        // Checkout state updating
        // Previous state logged
        internalState = newState
        // State update completed

        // Track analytics events based on state transitions
        Task {
            await trackStateChange(newState)
        }
    }

    private func trackStateChange(_ state: PrimerCheckoutState) async {
        switch state {
        case .ready:
            // Checkout flow is now interactive
            await analyticsInteractor?.trackEvent(.checkoutFlowStarted, metadata: .general())

        case let .success(result):
            // Payment succeeded
            if let paymentMethod = result.paymentMethodType {
                await analyticsInteractor?.trackEvent(.paymentSuccess, metadata: .payment(PaymentEvent(
                    paymentMethod: paymentMethod,
                    paymentId: result.paymentId
                )))
            } else {
                // No payment method type available, use general event
                await analyticsInteractor?.trackEvent(.paymentSuccess, metadata: .general())
            }

        case let .failure(error):
            // Payment failed - extract metadata from error if available
            await analyticsInteractor?.trackEvent(.paymentFailure, metadata: extractFailureMetadata(from: error))

        case .dismissed:
            // User exited checkout without completion
            await analyticsInteractor?.trackEvent(.paymentFlowExited, metadata: .general())

        default:
            break
        }
    }

    private func extractFailureMetadata(from error: PrimerError) -> AnalyticsEventMetadata {
        // Extract payment information from paymentFailed error if available
        if case let .paymentFailed(paymentMethodType, paymentId, _, _, _) = error,
           let paymentMethod = paymentMethodType {
            return .payment(PaymentEvent(
                paymentMethod: paymentMethod,
                paymentId: paymentId
            ))
        }

        // For other error types, just include userLocale
        return .general()
    }

    func updateNavigationState(_ newState: NavigationState, syncToNavigator: Bool = true) {
        // Navigation state updating
        navigationState = newState

        // Update navigation based on state (only if not syncing from navigator to avoid loops)
        if syncToNavigator {
            switch newState {
            case .loading:
                navigator.navigateToLoading()
            case .paymentMethodSelection:
                navigator.navigateToPaymentSelection()
            case let .paymentMethod(paymentMethodType):
                navigator.navigateToPaymentMethod(paymentMethodType, context: presentationContext)
            case .selectCountry:
                navigator.navigateToCountrySelection()
            case .success:
                // Success handling is now done via the view's switch statement, not the navigator
                break
            case let .failure(error):
                navigator.navigateToError(error)
            case .dismissed:
                // Dismissal is handled by the view layer through onCompletion callback
                break
            }
        }
    }

    // MARK: - Navigation Events Observer

    private func observeNavigationEvents() {
        Task { @MainActor in
            // Starting navigation events observer
            for await route in navigator.navigationEvents {
                // Received navigation event

                // Sync internal navigation state with the navigator's current route
                let newNavigationState: NavigationState
                switch route {
                case .loading:
                    newNavigationState = .loading
                case .paymentMethodSelection:
                    newNavigationState = .paymentMethodSelection
                case let .paymentMethod(paymentMethodType, _):
                    newNavigationState = .paymentMethod(paymentMethodType)
                case .selectCountry:
                    newNavigationState = .selectCountry
                case let .failure(primerError):
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
                        // Navigation state synced from navigator
                        updateNavigationState(newNavigationState, syncToNavigator: false)
                    }
                } else if !navigationStateEquals(navigationState, newNavigationState) {
                    // Navigation state synced from navigator
                    updateNavigationState(newNavigationState, syncToNavigator: false)
                }
            }
        }
    }

    private func navigationStateEquals(_ lhs: NavigationState, _ rhs: NavigationState) -> Bool {
        switch (lhs, rhs) {
        case (.loading, .loading),
             (.paymentMethodSelection, .paymentMethodSelection),
             (.selectCountry, .selectCountry):
            return true
        case let (.paymentMethod(lhsType), .paymentMethod(rhsType)):
            return lhsType == rhsType
        case let (.failure(lhsError), .failure(rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }

    // MARK: - Public Methods

    public func getPaymentMethodScope<T: PrimerPaymentMethodScope>(
        for paymentMethodType: String
    ) -> T? {
        // Getting payment method scope for type

        // Check cache first
        if let cachedScope = paymentMethodScopeCache[paymentMethodType] as? T {
            // Found cached scope for payment method
            return cachedScope
        }

        // Create new scope using registry
        do {
            // Get current container for thread-safe access
            guard let container = DIContainer.currentSync else {
                // No DI container available for payment method scope creation
                return nil
            }

            let scope: T? = try PaymentMethodRegistry.shared.createScope(
                for: paymentMethodType,
                checkoutScope: self,
                diContainer: container
            )

            if let scope = scope {
                // Cache the scope for future use
                paymentMethodScopeCache[paymentMethodType] = scope
                // Created and cached new scope for payment method
                return scope
            } else {
                // No scope registered for payment method
                return nil
            }

        } catch {
            // Failed to create scope for payment method
            return nil
        }
    }

    public func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? {
        // Getting payment method scope for type

        // Check cache first using type name
        if let cachedScope = paymentMethodScopeCache.values.first(where: { type(of: $0) == scopeType }) as? T {
            // Found cached scope for type
            return cachedScope
        }

        // Create new scope using type-safe registry method
        do {
            // Get current container for thread-safe access
            guard let container = DIContainer.currentSync else {
                // No DI container available for payment method scope creation
                return nil
            }

            let scope: T? = try PaymentMethodRegistry.shared.createScope(
                scopeType,
                checkoutScope: self,
                diContainer: container
            )

            if let scope = scope {
                // Cache the scope using its identifier for future use
                let scopeTypeName = String(describing: type(of: scope))
                paymentMethodScopeCache[scopeTypeName] = scope
                // Created and cached new scope for type
                return scope
            } else {
                // No scope registered for type
                return nil
            }

        } catch {
            // Failed to create scope for type
            return nil
        }
    }

    public func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T? {
        // Getting payment method scope for enum type

        // Delegate to string-based method
        return getPaymentMethodScope(for: methodType.rawValue)
    }

    // MARK: - Payment Method Screen Management

    /// Type mapping from payment method enum to string identifier
    private func getPaymentMethodIdentifier(_ type: PrimerPaymentMethodType) -> String {
        return type.rawValue
    }

    // Removed: setPaymentMethodScreen - now using PaymentMethodProtocol.content()

    // Removed: getPaymentMethodScreen - now using PaymentMethodProtocol.content()

    // Removed: getPaymentMethodScreenByIdentifier - now using PaymentMethodProtocol.content()

    public func onDismiss() {
        // Checkout dismissed

        // Ensure state updates happen on main thread for SwiftUI observation
        Task { @MainActor in
            // Update both state and navigation state to dismissed
            updateState(.dismissed)
            updateNavigationState(.dismissed)

            // Clean up any resources
            _paymentMethodSelection = nil
            currentPaymentMethodScope = nil
            paymentMethodScopeCache.removeAll()
            // Payment method screens now handled by PaymentMethodProtocol
        }

        // Navigate to dismiss the checkout
        navigator.dismiss()
    }

    // MARK: - Internal Methods

    func handlePaymentMethodSelection(_ method: InternalPaymentMethod) {
        // Payment method selected
        // Available methods count logged
        // Checkout context logged

        // Use dynamic scope creation instead of hardcoded switch statement
        do {
            // Get current container for thread-safe access
            guard let container = DIContainer.currentSync else {
                // No DI container available for payment method scope creation
                updateNavigationState(.failure(PrimerError.invalidArchitecture(
                    description: "Dependency injection container not available",
                    recoverSuggestion: "Ensure DI container is properly initialized",
                    )))
                return
            }

            // Try to create a scope for this payment method type using the registry
            let scope = try PaymentMethodRegistry.shared.createScope(
                for: method.type,
                checkoutScope: self,
                diContainer: container
            )

            if let scope = scope {
                // Successfully created scope for payment method

                // Store the current payment method scope for navigation
                currentPaymentMethodScope = scope

                // Start the payment method flow
                scope.start()

                // Navigate to the payment method using unified approach
                updateNavigationState(.paymentMethod(method.type))

            } else {
                // No scope registered for payment method
                // Fallback: show error or stay on payment method selection
                updateNavigationState(.failure(PrimerError.invalidArchitecture(
                    description: "Payment method \\(method.type) is not supported",
                    recoverSuggestion: "Register the payment method implementation"
                )))
            }

        } catch {
            // Failed to create scope for payment method
            updateNavigationState(.failure(PrimerError.invalidArchitecture(
                description: "Failed to initialize payment method \\(method.type): \\(error.localizedDescription)",
                recoverSuggestion: "Check payment method implementation"
            )))
        }
    }

    func handlePaymentSuccess(_ result: PaymentResult) {
        // Payment successful

        // Store the payment result in CheckoutComponentsPrimer for later retrieval in completion callback
        CheckoutComponentsPrimer.shared.storePaymentResult(result)

        // Update state to success for any listeners
        updateState(.success(result))

        // Navigate to success screen with payment result
        let checkoutResult = CheckoutPaymentResult(
            paymentId: result.paymentId,
            amount: result.amount?.description ?? "N/A"
        )
        updateNavigationState(.success(checkoutResult))
    }

    func handlePaymentError(_ error: PrimerError) {
        // Payment error

        // Update state and navigate to error screen
        updateState(.failure(error))
        updateNavigationState(.failure(error))
    }

    /// Handle auto-dismiss from success or error screens
    func handleAutoDismiss() {
        // Auto-dismiss triggered, completing checkout
        // Current state before auto-dismiss
        // This will be handled by the parent view (PrimerCheckout) to dismiss the entire checkout
        Task { @MainActor in
            // Notify any parent view that the checkout should be dismissed
            // Updating state to dismissed
            updateState(.dismissed)
            // State updated to dismissed
        }
    }
}
