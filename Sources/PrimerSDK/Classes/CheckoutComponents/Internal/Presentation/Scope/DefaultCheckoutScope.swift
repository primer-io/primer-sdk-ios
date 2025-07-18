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
        case paymentMethod(String)  // Dynamic payment method with type identifier
        case success(CheckoutPaymentResult)
        case failure(PrimerError)
        case dismissed
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
    public var successScreen: ((_ result: CheckoutPaymentResult) -> AnyView)?
    public var errorScreen: ((_ message: String) -> AnyView)?
    public var paymentMethodSelectionScreen: ((_ scope: PrimerPaymentMethodSelectionScope) -> AnyView)?

    /// Generic payment method screen registry for type-safe screen customization
    private var paymentMethodScreens: [String: Any] = [:]

    // MARK: - State Management
    // Note: Success result is no longer stored - delegate is called immediately on success

    // MARK: - Child Scopes

    private var _paymentMethodSelection: PrimerPaymentMethodSelectionScope?
    public var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
        if let existing = _paymentMethodSelection {
            return existing
        }
        let scope = DefaultPaymentMethodSelectionScope(checkoutScope: self)
        _paymentMethodSelection = scope
        return scope
    }

    // MARK: - Dynamic Payment Method Scope

    /// The currently active payment method scope (dynamically created)
    private var currentPaymentMethodScope: (any PrimerPaymentMethodScope)?

    /// Cache of created payment method scopes by type
    private var paymentMethodScopeCache: [String: any PrimerPaymentMethodScope] = [:]

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

    /// The presentation context for navigation behavior
    internal let presentationContext: PresentationContext

    // MARK: - Initialization

    init(clientToken: String, settings: PrimerSettings, diContainer: DIContainer, navigator: CheckoutNavigator, presentationContext: PresentationContext = .fromPaymentSelection) {
        self.clientToken = clientToken
        self.settings = settings
        self.diContainer = diContainer
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

        logger.debug(message: "Registered payment methods: \\(PaymentMethodRegistry.shared.registeredTypes)")
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

                // Check if we have only one payment method (any type)
                if availablePaymentMethods.count == 1,
                   let singlePaymentMethod = availablePaymentMethods.first {
                    logger.info(message: "🎯 [CheckoutComponents] Single payment method detected: \(singlePaymentMethod.type ?? "unknown"), navigating directly to payment method")
                    updateNavigationState(.paymentMethod(singlePaymentMethod.type ?? "UNKNOWN"))
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
        logger.debug(message: "Previous state was: \(internalState)")
        internalState = newState
        logger.debug(message: "State update completed. Current state: \(internalState)")
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
            case .paymentMethod(let paymentMethodType):
                navigator.navigateToPaymentMethod(paymentMethodType, context: presentationContext)
            case .success(let result):
                // Success handling is now done via the view's switch statement, not the navigator
                logger.info(message: "Success navigation handled by view layer")
            case .failure(let error):
                navigator.navigateToError(error.localizedDescription)
            case .dismissed:
                // Dismissal is handled by the view layer through onCompletion callback
                logger.info(message: "Dismissal navigation handled by view layer")
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
                case .paymentMethod(let paymentMethodType, _):
                    newNavigationState = .paymentMethod(paymentMethodType)
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
             (.paymentMethodSelection, .paymentMethodSelection):
            return true
        case (.paymentMethod(let lhsType), .paymentMethod(let rhsType)):
            return lhsType == rhsType
        case (.failure(let lhsError), .failure(let rhsError)):
            return lhsError.localizedDescription == rhsError.localizedDescription
        default:
            return false
        }
    }

    // MARK: - Public Methods

    public func getPaymentMethodScope<T: PrimerPaymentMethodScope>(
        for paymentMethodType: String
    ) -> T? {
        logger.debug(message: "Getting payment method scope for type: \\(paymentMethodType)")

        // Check cache first
        if let cachedScope = paymentMethodScopeCache[paymentMethodType] as? T {
            logger.debug(message: "Found cached scope for payment method: \\(paymentMethodType)")
            return cachedScope
        }

        // Create new scope using registry
        do {
            let scope: T? = try PaymentMethodRegistry.shared.createScope(
                for: paymentMethodType,
                checkoutScope: self,
                diContainer: diContainer
            )

            if let scope = scope {
                // Cache the scope for future use
                paymentMethodScopeCache[paymentMethodType] = scope
                logger.debug(message: "Created and cached new scope for payment method: \\(paymentMethodType)")
                return scope
            } else {
                logger.warn(message: "No scope registered for payment method: \\(paymentMethodType)")
                return nil
            }

        } catch {
            logger.error(message: "Failed to create scope for payment method \\(paymentMethodType): \\(error)")
            return nil
        }
    }

    public func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? {
        let typeName = String(describing: scopeType)
        logger.debug(message: "Getting payment method scope for type: \\(typeName)")

        // Check cache first using type name
        if let cachedScope = paymentMethodScopeCache.values.first(where: { type(of: $0) == scopeType }) as? T {
            logger.debug(message: "Found cached scope for type: \\(typeName)")
            return cachedScope
        }

        // Create new scope using type-safe registry method
        do {
            let scope: T? = try PaymentMethodRegistry.shared.createScope(
                scopeType,
                checkoutScope: self,
                diContainer: diContainer
            )

            if let scope = scope {
                // Cache the scope using its identifier for future use
                let scopeTypeName = String(describing: type(of: scope))
                paymentMethodScopeCache[scopeTypeName] = scope
                logger.debug(message: "Created and cached new scope for type: \\(typeName)")
                return scope
            } else {
                logger.warn(message: "No scope registered for type: \\(typeName)")
                return nil
            }

        } catch {
            logger.error(message: "Failed to create scope for type \\(typeName): \\(error)")
            return nil
        }
    }

    public func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T? {
        logger.debug(message: "Getting payment method scope for enum type: \\(methodType)")

        // Delegate to string-based method
        return getPaymentMethodScope(for: methodType.rawValue)
    }

    // MARK: - Payment Method Screen Management

    /// Type mapping from payment method enum to string identifier
    private func getPaymentMethodIdentifier(_ type: PrimerPaymentMethodType) -> String {
        return type.rawValue
    }

    /// Sets a custom screen for a specific payment method type
    /// - Parameters:
    ///   - paymentMethodType: The payment method type enum (e.g., .paymentCard)
    ///   - screenBuilder: The custom screen builder closure that receives the appropriate scope
    public func setPaymentMethodScreen(
        _ paymentMethodType: PrimerPaymentMethodType,
        screenBuilder: @escaping (any PrimerPaymentMethodScope) -> AnyView
    ) {
        let identifier = getPaymentMethodIdentifier(paymentMethodType)
        logger.debug(message: "Setting custom screen for payment method type: \(paymentMethodType) (\(identifier))")
        paymentMethodScreens[identifier] = screenBuilder
    }

    /// Gets a custom screen for a specific payment method type
    /// - Parameter paymentMethodType: The payment method type enum
    /// - Returns: The custom screen builder closure if set, nil otherwise
    public func getPaymentMethodScreen(
        _ paymentMethodType: PrimerPaymentMethodType
    ) -> ((any PrimerPaymentMethodScope) -> AnyView)? {
        let identifier = getPaymentMethodIdentifier(paymentMethodType)
        logger.debug(message: "Getting custom screen for payment method type: \(paymentMethodType) (\(identifier))")
        return paymentMethodScreens[identifier] as? (any PrimerPaymentMethodScope) -> AnyView
    }

    /// Internal method to get custom screen by string identifier (for backwards compatibility)
    internal func getPaymentMethodScreenByIdentifier(_ identifier: String) -> ((any PrimerPaymentMethodScope) -> AnyView)? {
        return paymentMethodScreens[identifier] as? (any PrimerPaymentMethodScope) -> AnyView
    }

    public func onDismiss() {
        logger.debug(message: "Checkout dismissed")

        // Update both state and navigation state to dismissed
        updateState(.dismissed)
        updateNavigationState(.dismissed)

        // Clean up any resources
        _paymentMethodSelection = nil
        currentPaymentMethodScope = nil
        paymentMethodScopeCache.removeAll()
        paymentMethodScreens.removeAll()

        // Navigate to dismiss the checkout
        navigator.dismiss()
    }

    // MARK: - Internal Methods

    internal func handlePaymentMethodSelection(_ method: InternalPaymentMethod) {
        logger.info(message: "🧭 [CheckoutScope] Payment method selected: \(method.type)")
        logger.info(message: "🧭 [CheckoutScope]   - Available methods count: \(availablePaymentMethods.count)")
        logger.info(message: "🧭 [CheckoutScope]   - Checkout context: \(presentationContext)")

        // Use dynamic scope creation instead of hardcoded switch statement
        do {
            // Try to create a scope for this payment method type using the registry
            let scope = try PaymentMethodRegistry.shared.createScope(
                for: method.type,
                checkoutScope: self,
                diContainer: diContainer
            )

            if let scope = scope {
                logger.debug(message: "Successfully created scope for payment method: \\(method.type)")

                // Store the current payment method scope for navigation
                currentPaymentMethodScope = scope

                // Start the payment method flow
                scope.start()

                // Navigate to the payment method using unified approach
                updateNavigationState(.paymentMethod(method.type))

            } else {
                logger.warn(message: "No scope registered for payment method: \\(method.type)")
                // Fallback: show error or stay on payment method selection
                updateNavigationState(.failure(PrimerError.invalidArchitecture(
                    description: "Payment method \\(method.type) is not supported",
                    recoverSuggestion: "Register the payment method implementation",
                    userInfo: ["paymentMethodType": method.type],
                    diagnosticsId: UUID().uuidString
                )))
            }

        } catch {
            logger.error(message: "Failed to create scope for payment method \\(method.type): \\(error)")
            updateNavigationState(.failure(PrimerError.invalidArchitecture(
                description: "Failed to initialize payment method",
                recoverSuggestion: "Check payment method implementation",
                userInfo: ["paymentMethodType": method.type, "error": error.localizedDescription],
                diagnosticsId: UUID().uuidString
            )))
        }
    }

    internal func handlePaymentSuccess(_ result: PaymentResult) {
        logger.info(message: "Payment successful: \(result.paymentId)")

        // Store the payment result in CheckoutComponentsPrimer for later retrieval in completion callback
        CheckoutComponentsPrimer.shared.storePaymentResult(result)

        // Update state to success for any listeners
        updateState(.success(result))

        // Navigate to success screen with payment result
        let checkoutResult = CheckoutPaymentResult(
            paymentId: result.paymentId,
            amount: result.amount?.description ?? "N/A",
            method: result.paymentMethodType ?? "Card"
        )
        updateNavigationState(.success(checkoutResult))
    }

    internal func handlePaymentError(_ error: PrimerError) {
        logger.error(message: "Payment error: \\(error)")

        // Update state and navigate to error screen
        updateState(.failure(error))
        updateNavigationState(.failure(error))
    }

    /// Handle auto-dismiss from success or error screens
    internal func handleAutoDismiss() {
        logger.info(message: "Auto-dismiss triggered, completing checkout")
        logger.info(message: "Current state before auto-dismiss: \(internalState)")
        // This will be handled by the parent view (PrimerCheckout) to dismiss the entire checkout
        Task { @MainActor in
            // Notify any parent view that the checkout should be dismissed
            logger.info(message: "Updating state to dismissed")
            updateState(.dismissed)
            logger.info(message: "State updated to dismissed: \(internalState)")
        }
    }
}
