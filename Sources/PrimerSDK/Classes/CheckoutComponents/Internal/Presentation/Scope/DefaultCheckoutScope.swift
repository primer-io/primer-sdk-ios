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
internal final class DefaultCheckoutScope: PrimerCheckoutScope, ObservableObject, LogReporter, SettingsObserverProtocol {
    // MARK: - Internal Navigation State

    internal enum NavigationState: Equatable {
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
            case (.paymentMethod(let lhsType), .paymentMethod(let rhsType)):
                return lhsType == rhsType
            case (.success(let lhsResult), .success(let rhsResult)):
                return lhsResult.paymentId == rhsResult.paymentId
            case (.failure(let lhsError), .failure(let rhsError)):
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

    // Removed: paymentMethodScreens - now using PaymentMethodProtocol.content()

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

    private let navigator: CheckoutNavigator
    private var paymentMethodsInteractor: GetPaymentMethodsInteractor?

    // MARK: - Internal Access

    /// Provides access to the navigator for child scopes
    internal var checkoutNavigator: CheckoutNavigator {
        navigator
    }

    // MARK: - Other Properties

    private let clientToken: String
    private let settingsService: CheckoutComponentsSettingsServiceProtocol
    internal var availablePaymentMethods: [InternalPaymentMethod] = []

    // MARK: - UI Settings Access (for settings-based screen control)

    /// Whether the initialization loading screen should be shown
    internal var isInitScreenEnabled: Bool {
        settingsService.isInitScreenEnabled
    }

    /// Whether the success screen should be shown after successful payment
    internal var isSuccessScreenEnabled: Bool {
        settingsService.isSuccessScreenEnabled
    }

    /// Whether the error screen should be shown after failed payment
    internal var isErrorScreenEnabled: Bool {
        settingsService.isErrorScreenEnabled
    }

    /// Available dismissal mechanisms (gestures, close button)
    internal var dismissalMechanism: [DismissalMechanism] {
        settingsService.dismissalMechanism
    }

    // MARK: - Debug Settings Access (critical for 3DS security)

    /// Whether 3DS sanity checks are enabled (CRITICAL for security in production)
    internal var is3DSSanityCheckEnabled: Bool {
        settingsService.is3DSSanityCheckEnabled
    }

    /// The presentation context for navigation behavior
    internal let presentationContext: PresentationContext

    // MARK: - Initialization

    init(clientToken: String, settingsService: CheckoutComponentsSettingsServiceProtocol, diContainer: DIContainer, navigator: CheckoutNavigator, presentationContext: PresentationContext = .fromPaymentSelection) {
        self.clientToken = clientToken
        self.settingsService = settingsService
        self.navigator = navigator
        self.presentationContext = presentationContext

        // Register payment methods with the registry
        registerPaymentMethods()

        Task {
            await setupInteractors()
            await loadPaymentMethods()
            await registerAsSettingsObserver()
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
            guard let _ = await DIContainer.current else {
                // DI Container is not available
                throw ContainerError.containerUnavailable
            }
            // DI Container found

            // Creating bridge to existing SDK payment methods
            paymentMethodsInteractor = CheckoutComponentsPaymentMethodsBridge()

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
        if settingsService.isInitScreenEnabled {
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
    }

    internal func updateNavigationState(_ newState: NavigationState, syncToNavigator: Bool = true) {
        // Navigation state updating
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
            case .selectCountry:
                navigator.navigateToCountrySelection()
            case .success:
                // Success handling is now done via the view's switch statement, not the navigator
                break
            case .failure(let error):
                navigator.navigateToError(error.localizedDescription)
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
                case .paymentMethod(let paymentMethodType, _):
                    newNavigationState = .paymentMethod(paymentMethodType)
                case .selectCountry:
                    newNavigationState = .selectCountry
                case .failure(let checkoutError):
                    let primerError = PrimerError.unknown(
                        message: "\(checkoutError.message) (code: \(checkoutError.code))"
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

        // Update both state and navigation state to dismissed
        updateState(.dismissed)
        updateNavigationState(.dismissed)

        // Clean up any resources
        _paymentMethodSelection = nil
        currentPaymentMethodScope = nil
        paymentMethodScopeCache.removeAll()
        // Payment method screens now handled by PaymentMethodProtocol

        // Navigate to dismiss the checkout
        navigator.dismiss()
    }

    // MARK: - Internal Methods

    internal func handlePaymentMethodSelection(_ method: InternalPaymentMethod) {
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

    internal func handlePaymentSuccess(_ result: PaymentResult) {
        // Payment successful

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
        // Payment error

        // Update state and navigate to error screen
        updateState(.failure(error))
        updateNavigationState(.failure(error))
    }

    /// Handle auto-dismiss from success or error screens
    internal func handleAutoDismiss() {
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

    // MARK: - Settings Observer Registration

    /// Register this scope as a settings observer for dynamic updates
    private func registerAsSettingsObserver() async {
        do {
            guard let container = await DIContainer.current else {
                // DI Container not available for settings observer registration
                return
            }

            let settingsObserver = try await container.resolve(SettingsObserver.self)
            settingsObserver.addObserver(self)
            // Registered as settings observer
        } catch {
            // Failed to register as settings observer
        }
    }

    // MARK: - SettingsObserverProtocol Implementation

    func settingsDidChange(from oldSettings: PrimerSettings, to newSettings: PrimerSettings) async {
        // Settings changed notification received

        // Note: Settings service is immutable and will be updated at the container level
        // The settings service itself wraps PrimerSettings, so changes are reflected automatically

        // Log significant changes
        if oldSettings.uiOptions.isInitScreenEnabled != newSettings.uiOptions.isInitScreenEnabled {
            // Init screen setting changed
        }

        if oldSettings.debugOptions.is3DSSanityCheckEnabled != newSettings.debugOptions.is3DSSanityCheckEnabled {
            // 3DS sanity check setting changed
        }

        // Settings update completed
    }

    func uiOptionsDidChange(from oldOptions: PrimerUIOptions, to newOptions: PrimerUIOptions) async {
        // UI options changed

        // Specific UI option handling
        if oldOptions.isInitScreenEnabled != newOptions.isInitScreenEnabled {
            // Init screen enabled changed

            // If currently in loading state and init screen was disabled, skip to payment method selection
            if !newOptions.isInitScreenEnabled && navigationState == .loading {
                // Init screen disabled during loading - skipping to payment method selection
                updateNavigationState(.paymentMethodSelection)
            }
        }

        if oldOptions.isSuccessScreenEnabled != newOptions.isSuccessScreenEnabled {
            // Success screen enabled changed
        }

        if oldOptions.isErrorScreenEnabled != newOptions.isErrorScreenEnabled {
            // Error screen enabled changed
        }
    }

    func debugOptionsDidChange(from oldOptions: PrimerDebugOptions, to newOptions: PrimerDebugOptions) async {
        // Debug options changed

        if oldOptions.is3DSSanityCheckEnabled != newOptions.is3DSSanityCheckEnabled {
            // 3DS sanity check changed
            // Note: 3DS sanity check changes require payment method reinitialization in most cases
            // For now, just log the change - full implementation would require payment method restart
        }
    }

    func localeDataDidChange(from oldLocale: PrimerLocaleData, to newLocale: PrimerLocaleData) async {
        // Locale data changed
        // Locale changes are handled by the standard iOS localization system
    }

    func paymentMethodOptionsDidChange(from oldOptions: PrimerPaymentMethodOptions, to newOptions: PrimerPaymentMethodOptions) async {
        // Payment method options changed

        // URL scheme changes
        let oldUrlScheme = try? oldOptions.validSchemeForUrlScheme()
        let newUrlScheme = try? newOptions.validSchemeForUrlScheme()
        if oldUrlScheme != newUrlScheme {
            // URL scheme changed
        }

        // Apple Pay changes
        let oldApplePayId = oldOptions.applePayOptions?.merchantIdentifier
        let newApplePayId = newOptions.applePayOptions?.merchantIdentifier
        if oldApplePayId != newApplePayId {
            // Apple Pay merchant ID changed
        }

        // 3DS changes
        let oldThreeDsUrl = oldOptions.threeDsOptions?.threeDsAppRequestorUrl
        let newThreeDsUrl = newOptions.threeDsOptions?.threeDsAppRequestorUrl
        if oldThreeDsUrl != newThreeDsUrl {
            // 3DS app requestor URL changed
        }
    }
}
