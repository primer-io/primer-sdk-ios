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
    private var getPaymentMethodsInteractor: GetPaymentMethodsInteractor?

    // MARK: - Internal Access

    /// Provides access to the navigator for child scopes
    internal var checkoutNavigator: CheckoutNavigator {
        navigator
    }

    // MARK: - Other Properties

    private let clientToken: String
    private let settings: PrimerSettings
    private var settingsService: CheckoutComponentsSettingsServiceProtocol?
    private var localeService: LocaleServiceProtocol?
    internal var availablePaymentMethods: [InternalPaymentMethod] = []

    // MARK: - UI Settings Access (for settings-based screen control)

    /// Whether the initialization loading screen should be shown
    internal var isInitScreenEnabled: Bool {
        settingsService?.isInitScreenEnabled ?? settings.uiOptions.isInitScreenEnabled
    }

    /// Whether the success screen should be shown after successful payment
    internal var isSuccessScreenEnabled: Bool {
        settingsService?.isSuccessScreenEnabled ?? settings.uiOptions.isSuccessScreenEnabled
    }

    /// Whether the error screen should be shown after failed payment
    internal var isErrorScreenEnabled: Bool {
        settingsService?.isErrorScreenEnabled ?? settings.uiOptions.isErrorScreenEnabled
    }

    /// Available dismissal mechanisms (gestures, close button)
    internal var dismissalMechanism: [DismissalMechanism] {
        settingsService?.dismissalMechanism ?? settings.uiOptions.dismissalMechanism
    }

    // MARK: - Debug Settings Access (critical for 3DS security)

    /// Whether 3DS sanity checks are enabled (CRITICAL for security in production)
    internal var is3DSSanityCheckEnabled: Bool {
        settingsService?.is3DSSanityCheckEnabled ?? settings.debugOptions.is3DSSanityCheckEnabled
    }

    /// The presentation context for navigation behavior
    internal let presentationContext: PresentationContext

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

            // Inject settings service
            settingsService = try await container.resolve(CheckoutComponentsSettingsServiceProtocol.self)
            logger.info(message: "✅ [CheckoutComponents] Settings service injected")

            // LOCALE DATA INTEGRATION: Inject locale service for localized strings
            localeService = try await container.resolve(LocaleServiceProtocol.self)
            logger.info(message: "🌐 [CheckoutComponents] Locale service injected - using locale: \(localeService?.currentLocale.identifier ?? "default")")

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

        // Only show loading screen if enabled in settings (UI Options integration)
        if settingsService?.isInitScreenEnabled == true {
            updateNavigationState(.loading)
            logger.debug(message: "✅ [CheckoutComponents] Init screen enabled - showing loading state")
        } else {
            logger.debug(message: "⏭️ [CheckoutComponents] Init screen disabled - skipping loading state")
        }

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
                logger.debug(message: "💳 [CheckoutComponents] Payment Method \(index + 1): \(method.type) - \(method.name)")
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
                    logger.info(message: "🎯 [CheckoutComponents] Single payment method detected: \(singlePaymentMethod.type), navigating directly to payment method")
                    updateNavigationState(.paymentMethod(singlePaymentMethod.type))
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

    internal func updateNavigationState(_ newState: NavigationState, syncToNavigator: Bool = true) {
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
            case .selectCountry:
                navigator.navigateToCountrySelection()
            case .success:
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
                case .selectCountry:
                    newNavigationState = .selectCountry
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
        logger.debug(message: "Getting payment method scope for type: \\(paymentMethodType)")

        // Check cache first
        if let cachedScope = paymentMethodScopeCache[paymentMethodType] as? T {
            logger.debug(message: "Found cached scope for payment method: \\(paymentMethodType)")
            return cachedScope
        }

        // Create new scope using registry
        do {
            // Get current container for thread-safe access
            guard let container = DIContainer.currentSync else {
                logger.error(message: "No DI container available for payment method scope creation")
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
        logger.debug(message: "Getting payment method scope for type: \\(String(describing: scopeType))")

        // Check cache first using type name
        if let cachedScope = paymentMethodScopeCache.values.first(where: { type(of: $0) == scopeType }) as? T {
            logger.debug(message: "Found cached scope for type: \\(String(describing: scopeType))")
            return cachedScope
        }

        // Create new scope using type-safe registry method
        do {
            // Get current container for thread-safe access
            guard let container = DIContainer.currentSync else {
                logger.error(message: "No DI container available for payment method scope creation")
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

    // Removed: setPaymentMethodScreen - now using PaymentMethodProtocol.content()

    // Removed: getPaymentMethodScreen - now using PaymentMethodProtocol.content()

    // Removed: getPaymentMethodScreenByIdentifier - now using PaymentMethodProtocol.content()

    public func onDismiss() {
        logger.debug(message: "Checkout dismissed")

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
        logger.info(message: "🧭 [CheckoutScope] Payment method selected: \(method.type)")
        logger.info(message: "🧭 [CheckoutScope]   - Available methods count: \(availablePaymentMethods.count)")
        logger.info(message: "🧭 [CheckoutScope]   - Checkout context: \(presentationContext)")

        // Use dynamic scope creation instead of hardcoded switch statement
        do {
            // Get current container for thread-safe access
            guard let container = DIContainer.currentSync else {
                logger.error(message: "No DI container available for payment method scope creation")
                updateNavigationState(.failure(PrimerError.invalidArchitecture(
                    description: "Dependency injection container not available",
                    recoverSuggestion: "Ensure DI container is properly initialized",
                    userInfo: nil,
                    diagnosticsId: UUID().uuidString
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

    // MARK: - Settings Observer Registration

    /// Register this scope as a settings observer for dynamic updates
    private func registerAsSettingsObserver() async {
        do {
            guard let container = await DIContainer.current else {
                logger.warn(message: "🔧 [CheckoutScope] DI Container not available for settings observer registration")
                return
            }

            let settingsObserver = try await container.resolve(SettingsObserver.self)
            settingsObserver.addObserver(self)
            logger.info(message: "🔧 [CheckoutScope] Registered as settings observer")
        } catch {
            logger.error(message: "🔧 [CheckoutScope] Failed to register as settings observer: \(error)")
        }
    }

    // MARK: - SettingsObserverProtocol Implementation

    func settingsDidChange(from oldSettings: PrimerSettings, to newSettings: PrimerSettings) async {
        logger.info(message: "🔧 [CheckoutScope] Settings changed notification received")

        // Update settings service with new settings (this will propagate to other services)
        if let container = await DIContainer.current {
            settingsService = try? await container.resolve(CheckoutComponentsSettingsServiceProtocol.self)
        }

        // Log significant changes
        if oldSettings.uiOptions.isInitScreenEnabled != newSettings.uiOptions.isInitScreenEnabled {
            logger.info(message: "🔧 [CheckoutScope] Init screen setting changed: \(oldSettings.uiOptions.isInitScreenEnabled) → \(newSettings.uiOptions.isInitScreenEnabled)")
        }

        if oldSettings.debugOptions.is3DSSanityCheckEnabled != newSettings.debugOptions.is3DSSanityCheckEnabled {
            logger.info(message: "🔧 [CheckoutScope] 3DS sanity check setting changed: \(oldSettings.debugOptions.is3DSSanityCheckEnabled) → \(newSettings.debugOptions.is3DSSanityCheckEnabled)")
        }

        logger.info(message: "🔧 [CheckoutScope] Settings update completed")
    }

    func uiOptionsDidChange(from oldOptions: PrimerUIOptions, to newOptions: PrimerUIOptions) async {
        logger.info(message: "🔧 [CheckoutScope] UI options changed")

        // Specific UI option handling
        if oldOptions.isInitScreenEnabled != newOptions.isInitScreenEnabled {
            logger.info(message: "🔧 [CheckoutScope] Init screen enabled changed: \(oldOptions.isInitScreenEnabled) → \(newOptions.isInitScreenEnabled)")

            // If currently in loading state and init screen was disabled, skip to payment method selection
            if !newOptions.isInitScreenEnabled && navigationState == .loading {
                logger.info(message: "🔧 [CheckoutScope] Init screen disabled during loading - skipping to payment method selection")
                updateNavigationState(.paymentMethodSelection)
            }
        }

        if oldOptions.isSuccessScreenEnabled != newOptions.isSuccessScreenEnabled {
            logger.info(message: "🔧 [CheckoutScope] Success screen enabled changed: \(oldOptions.isSuccessScreenEnabled) → \(newOptions.isSuccessScreenEnabled)")
        }

        if oldOptions.isErrorScreenEnabled != newOptions.isErrorScreenEnabled {
            logger.info(message: "🔧 [CheckoutScope] Error screen enabled changed: \(oldOptions.isErrorScreenEnabled) → \(newOptions.isErrorScreenEnabled)")
        }
    }

    func debugOptionsDidChange(from oldOptions: PrimerDebugOptions, to newOptions: PrimerDebugOptions) async {
        logger.info(message: "🔧 [CheckoutScope] Debug options changed")

        if oldOptions.is3DSSanityCheckEnabled != newOptions.is3DSSanityCheckEnabled {
            logger.info(message: "🔧 [CheckoutScope] 3DS sanity check changed: \(oldOptions.is3DSSanityCheckEnabled) → \(newOptions.is3DSSanityCheckEnabled)")
            // Note: 3DS sanity check changes require payment method reinitialization in most cases
            // For now, just log the change - full implementation would require payment method restart
        }
    }

    func localeDataDidChange(from oldLocale: PrimerLocaleData, to newLocale: PrimerLocaleData) async {
        logger.info(message: "🔧 [CheckoutScope] Locale data changed: \(oldLocale.localeCode) → \(newLocale.localeCode)")

        // Reinject locale service to pick up new locale configuration
        if let container = await DIContainer.current {
            localeService = try? await container.resolve(LocaleServiceProtocol.self)
        }

        logger.info(message: "🔧 [CheckoutScope] Locale service reinjected with new locale data")
    }

    func paymentMethodOptionsDidChange(from oldOptions: PrimerPaymentMethodOptions, to newOptions: PrimerPaymentMethodOptions) async {
        logger.info(message: "🔧 [CheckoutScope] Payment method options changed")

        // URL scheme changes
        let oldUrlScheme = try? oldOptions.validSchemeForUrlScheme()
        let newUrlScheme = try? newOptions.validSchemeForUrlScheme()
        if oldUrlScheme != newUrlScheme {
            logger.info(message: "🔧 [CheckoutScope] URL scheme changed: \(oldUrlScheme ?? "none") → \(newUrlScheme ?? "none")")
        }

        // Apple Pay changes
        let oldApplePayId = oldOptions.applePayOptions?.merchantIdentifier
        let newApplePayId = newOptions.applePayOptions?.merchantIdentifier
        if oldApplePayId != newApplePayId {
            logger.info(message: "🔧 [CheckoutScope] Apple Pay merchant ID changed: \(oldApplePayId ?? "none") → \(newApplePayId ?? "none")")
        }

        // 3DS changes
        let oldThreeDsUrl = oldOptions.threeDsOptions?.threeDsAppRequestorUrl
        let newThreeDsUrl = newOptions.threeDsOptions?.threeDsAppRequestorUrl
        if oldThreeDsUrl != newThreeDsUrl {
            logger.info(message: "🔧 [CheckoutScope] 3DS app requestor URL changed: \(oldThreeDsUrl ?? "none") → \(newThreeDsUrl ?? "none")")
        }
    }
}
