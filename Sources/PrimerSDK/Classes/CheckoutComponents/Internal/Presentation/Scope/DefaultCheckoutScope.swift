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
    public var successScreen: ((_ result: CheckoutPaymentResult) -> AnyView)?
    public var errorScreen: ((_ message: String) -> any View)?
    public var paymentMethodSelectionScreen: ((_ scope: PrimerPaymentMethodSelectionScope) -> AnyView)?

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
    private var accessibilityAnnouncementService: AccessibilityAnnouncementService?

    /// Stores the API-provided display name of the currently selected payment method for accessibility announcements
    private var selectedPaymentMethodName: String?

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

        registerPaymentMethods()

        Task {
            await setupInteractors()
            await loadPaymentMethods()
        }

        observeNavigationEvents()
    }

    /// Registers all available payment method implementations with the registry
    @MainActor
    private func registerPaymentMethods() {
        CardPaymentMethod.register()
    }

    // MARK: - Setup

    private func setupInteractors() async {
        do {
            guard let container = await DIContainer.current else {
                throw ContainerError.containerUnavailable
            }

            let configService = try await container.resolve(ConfigurationService.self)
            paymentMethodsInteractor = CheckoutComponentsPaymentMethodsBridge(configurationService: configService)

            analyticsInteractor = try? await container.resolve(CheckoutComponentsAnalyticsInteractorProtocol.self)

            accessibilityAnnouncementService = try? await container.resolve(AccessibilityAnnouncementService.self)
        } catch {
            let primerError = PrimerError.invalidArchitecture(
                description: "Failed to setup interactors: \(error.localizedDescription)",
                recoverSuggestion: "Ensure proper SDK initialization"
            )
            updateNavigationState(.failure(primerError))
            updateState(.failure(primerError))
        }
    }

    private func loadPaymentMethods() async {
        // Only show loading screen if enabled in settings (UI Options integration)
        if settings.uiOptions.isInitScreenEnabled {
            updateNavigationState(.loading)
        }

        do {
            // Add a small delay to ensure SDK configuration is fully loaded
            try await Task.sleep(nanoseconds: 500_000_000) // 0.5 seconds

            guard let interactor = paymentMethodsInteractor else {
                throw PrimerError.invalidArchitecture(
                    description: "GetPaymentMethodsInteractor not resolved",
                    recoverSuggestion: "Ensure proper SDK initialization and dependency injection setup"
                )
            }

            availablePaymentMethods = try await interactor.execute()

            if availablePaymentMethods.isEmpty {
                let error = PrimerError.missingPrimerConfiguration()
                updateNavigationState(.failure(error))
                updateState(.failure(error))
            } else {
                updateState(.ready)

                if availablePaymentMethods.count == 1,
                   let singlePaymentMethod = availablePaymentMethods.first {
                    updateNavigationState(.paymentMethod(singlePaymentMethod.type))
                } else {
                    updateNavigationState(.paymentMethodSelection)
                }
            }
        } catch {
            let primerError = error as? PrimerError ?? PrimerError.unknown(
                message: error.localizedDescription
            )
            updateNavigationState(.failure(primerError))
            updateState(.failure(primerError))
        }
    }

    // MARK: - State Management

    private func updateState(_ newState: PrimerCheckoutState) {
        internalState = newState

        Task {
            await trackStateChange(newState)
        }
    }

    private func trackStateChange(_ state: PrimerCheckoutState) async {
        switch state {
        case .ready:
            await analyticsInteractor?.trackEvent(.checkoutFlowStarted, metadata: .general())

        case let .success(result):
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
            await analyticsInteractor?.trackEvent(.paymentFailure, metadata: extractFailureMetadata(from: error))

        case .dismissed:
            await analyticsInteractor?.trackEvent(.paymentFlowExited, metadata: .general())

        default:
            break
        }
    }

    private func extractFailureMetadata(from error: PrimerError) -> AnalyticsEventMetadata {
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
        navigationState = newState

        announceScreenChange(for: newState)

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

    /// Announces screen changes to VoiceOver users
    private func announceScreenChange(for state: NavigationState) {
        guard let service = accessibilityAnnouncementService else { return }

        let message: String?
        switch state {
        case .loading:
            message = CheckoutComponentsStrings.a11yScreenLoadingPaymentMethods
        case .paymentMethodSelection:
            message = CheckoutComponentsStrings.choosePaymentMethod
        case let .paymentMethod(type):
            if let name = selectedPaymentMethodName {
                message = CheckoutComponentsStrings.a11yScreenPaymentMethod(name)
            } else {
                // Fallback: Format raw payment method type for display
                // This should rarely be used as API always provides display names
                let displayName = type
                    .replacingOccurrences(of: "_", with: " ")
                    .capitalized
                message = CheckoutComponentsStrings.a11yScreenPaymentMethod(displayName)
            }
        case .selectCountry:
            message = CheckoutComponentsStrings.a11yScreenCountrySelection
        case .success:
            message = CheckoutComponentsStrings.a11yScreenSuccess
            selectedPaymentMethodName = nil
        case .failure:
            message = CheckoutComponentsStrings.a11yScreenError
            selectedPaymentMethodName = nil
        case .dismissed:
            message = nil
            selectedPaymentMethodName = nil
        }

        if let message = message {
            service.announceScreenChange(message)
            logger.debug(message: "[A11Y] Screen change announcement: \(message)")
        }
    }

    // MARK: - Navigation Events Observer

    private func observeNavigationEvents() {
        Task { @MainActor in
            for await route in navigator.navigationEvents {
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
                    continue
                }

                // Only update if the state has actually changed to avoid loops
                if case let .failure(currentError) = navigationState,
                   case let .failure(newError) = newNavigationState {
                    // For error states, compare messages to avoid redundant updates
                    if currentError.localizedDescription != newError.localizedDescription {
                        updateNavigationState(newNavigationState, syncToNavigator: false)
                    }
                } else if !navigationStateEquals(navigationState, newNavigationState) {
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
        if let cachedScope = paymentMethodScopeCache[paymentMethodType] as? T {
            return cachedScope
        }

        do {
            guard let container = DIContainer.currentSync else {
                return nil
            }

            let scope: T? = try PaymentMethodRegistry.shared.createScope(
                for: paymentMethodType,
                checkoutScope: self,
                diContainer: container
            )

            if let scope {
                paymentMethodScopeCache[paymentMethodType] = scope
                return scope
            } else {
                return nil
            }

        } catch {
            return nil
        }
    }

    public func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? {
        if let cachedScope = paymentMethodScopeCache.values.first(where: { type(of: $0) == scopeType }) as? T {
            return cachedScope
        }

        do {
            guard let container = DIContainer.currentSync else {
                return nil
            }

            let scope: T? = try PaymentMethodRegistry.shared.createScope(
                scopeType,
                checkoutScope: self,
                diContainer: container
            )

            if let scope {
                let scopeTypeName = String(describing: type(of: scope))
                paymentMethodScopeCache[scopeTypeName] = scope
                return scope
            } else {
                return nil
            }

        } catch {
            return nil
        }
    }

    public func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T? {
        getPaymentMethodScope(for: methodType.rawValue)
    }

    // MARK: - Payment Method Screen Management

    /// Type mapping from payment method enum to string identifier
    private func getPaymentMethodIdentifier(_ type: PrimerPaymentMethodType) -> String {
        type.rawValue
    }

    public func onDismiss() {
        // Ensure state updates happen on main thread for SwiftUI observation
        Task { @MainActor in
            updateState(.dismissed)
            updateNavigationState(.dismissed)

            _paymentMethodSelection = nil
            currentPaymentMethodScope = nil
            paymentMethodScopeCache.removeAll()
        }

        navigator.dismiss()
    }

    // MARK: - Internal Methods

    func handlePaymentMethodSelection(_ method: InternalPaymentMethod) {
        selectedPaymentMethodName = method.name

        do {
            guard let container = DIContainer.currentSync else {
                updateNavigationState(.failure(PrimerError.invalidArchitecture(
                    description: "Dependency injection container not available",
                    recoverSuggestion: "Ensure DI container is properly initialized",
                    )))
                return
            }

            let scope = try PaymentMethodRegistry.shared.createScope(
                for: method.type,
                checkoutScope: self,
                diContainer: container
            )

            if let scope {
                paymentMethodScopeCache[method.type] = scope

                currentPaymentMethodScope = scope

                scope.start()

                updateNavigationState(.paymentMethod(method.type))

            } else {
                // Still navigate to payment method screen - PaymentMethodScreen will show placeholder UI
                // This allows graceful handling of unimplemented payment methods with "Coming Soon" message
                logger.debug(message: "⚠️ [DefaultCheckoutScope] Payment method \(method.type) not implemented, showing placeholder")
                updateNavigationState(.paymentMethod(method.type))
            }

        } catch {
            updateNavigationState(.failure(PrimerError.invalidArchitecture(
                description: "Failed to initialize payment method \\(method.type): \\(error.localizedDescription)",
                recoverSuggestion: "Check payment method implementation"
            )))
        }
    }

    func handlePaymentSuccess(_ result: PaymentResult) {
        CheckoutComponentsPrimer.shared.storePaymentResult(result)

        updateState(.success(result))

        // Invoke custom success callback if configured
        navigator.handleSuccess()

        let checkoutResult = CheckoutPaymentResult(
            paymentId: result.paymentId,
            amount: result.amount?.description ?? "N/A"
        )
        updateNavigationState(.success(checkoutResult))
    }

    func handlePaymentError(_ error: PrimerError) {
        updateState(.failure(error))
        // Note: Error callback is invoked via navigateToError in updateNavigationState
        updateNavigationState(.failure(error))
    }

    /// Handle auto-dismiss from success or error screens
    func handleAutoDismiss() {
        // This will be handled by the parent view (PrimerCheckout) to dismiss the entire checkout
        Task { @MainActor in
            updateState(.dismissed)
        }
    }

    // MARK: - Configuration

    /// Configures the checkout scope with PrimerComponents.
    /// Maps immutable component configuration to internal scope properties.
    /// - Parameter components: The immutable component configuration
    func configure(with components: PrimerComponents) {
        // Configure checkout screens
        if let splash = components.checkout.splash {
            splashScreen = { AnyView(splash()) }
        }

        if let success = components.checkout.success {
            successScreen = { _ in success() }
        }

        if let errorContent = components.checkout.error.content {
            errorScreen = { message in AnyView(errorContent(message)) }
        }

        // Configure container
        if let customContainer = components.container {
            container = { content in
                AnyView(customContainer(content))
            }
        }

        // Configure navigator with navigation callbacks
        navigator.configure(with: components)

        // Note: Payment method selection and card form configuration
        // is handled by accessing components directly from scopes
    }
}
