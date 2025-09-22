//
//  PrimerCheckout.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// The main entry point for CheckoutComponents, providing a SwiftUI view for payment checkout.
///
/// Example usage:
/// ```swift
/// PrimerCheckout(
///     clientToken: "your_client_token",
///     settings: PrimerSettings()
/// )
/// ```
///
/// With scope customization:
/// ```swift
/// PrimerCheckout(
///     clientToken: "your_client_token",
///     settings: PrimerSettings(),
///     scope: { checkoutScope in
///         // Customize components using type-safe API
///         if let cardFormScope = checkoutScope.getPaymentMethodScope(PrimerCardFormScope.self) {
///             cardFormScope.cardNumberInput = { _ in
///                 CustomCardNumberField()
///             }
///         }
///     }
/// )
/// ```
@available(iOS 15.0, *)
@MainActor
public struct PrimerCheckout: View {

    /// The client token for initializing the checkout session.
    private let clientToken: String

    /// Configuration settings for the checkout experience.
    private let settings: PrimerSettings

    /// Optional scope configuration closure for customizing UI components.
    private let scope: ((PrimerCheckoutScope) -> Void)?

    /// Optional custom content builder for complete UI replacement
    private let customContent: ((PrimerCheckoutScope) -> AnyView)?

    /// Optional completion callback for dismissal handling
    private let onCompletion: (() -> Void)?

    /// Navigator (internal use only)
    let navigator: CheckoutNavigator

    /// Presentation context determining navigation behavior (internal use only)
    let presentationContext: PresentationContext

    /// Creates a new PrimerCheckout view.
    /// - Parameters:
    ///   - clientToken: The client token obtained from your backend.
    ///   - settings: Configuration settings including theme and payment options.
    ///   - scope: Optional closure to customize UI components through the scope interface.
    ///   - onCompletion: Optional completion callback called when checkout completes or dismisses.
    public init(
        clientToken: String,
        settings: PrimerSettings = PrimerSettings(),
        scope: ((PrimerCheckoutScope) -> Void)? = nil,
        onCompletion: (() -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.scope = scope
        self.customContent = nil
        self.onCompletion = onCompletion
        self.navigator = CheckoutNavigator()
        self.presentationContext = .fromPaymentSelection
    }

    /// Internal initializer with presentation context
    internal init(
        clientToken: String,
        settings: PrimerSettings,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        presentationContext: PresentationContext,
        onCompletion: (() -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.scope = nil
        self.customContent = nil
        self.onCompletion = onCompletion
        self.navigator = navigator
        self.presentationContext = presentationContext
    }

    /// Internal initializer with custom content and presentation context
    internal init(
        clientToken: String,
        settings: PrimerSettings,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        customContent: ((PrimerCheckoutScope) -> AnyView)?,
        presentationContext: PresentationContext,
        onCompletion: (() -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.scope = nil
        self.customContent = customContent
        self.onCompletion = onCompletion
        self.navigator = navigator
        self.presentationContext = presentationContext
    }

    public var body: some View {
        InternalCheckout(
            clientToken: clientToken,
            settings: settings,
            diContainer: DIContainer.shared,
            navigator: navigator,
            scope: scope,
            customContent: customContent,
            presentationContext: presentationContext,
            onCompletion: onCompletion
        )
    }
}

// MARK: - Internal Implementation

/// Internal checkout implementation that manages the full checkout flow.
@available(iOS 15.0, *)
@MainActor
internal struct InternalCheckout: View {
    let clientToken: String
    let settings: PrimerSettings
    let diContainer: DIContainer
    let navigator: CheckoutNavigator
    let scope: ((PrimerCheckoutScope) -> Void)?
    let customContent: ((PrimerCheckoutScope) -> AnyView)?
    let presentationContext: PresentationContext
    let onCompletion: (() -> Void)?

    @State private var checkoutScope: DefaultCheckoutScope?
    @State private var sdkInitialized = false
    @State private var initializationError: PrimerError?
    @State private var isInitializing = false

    init(
        clientToken: String,
        settings: PrimerSettings,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        scope: ((PrimerCheckoutScope) -> Void)?,
        customContent: ((PrimerCheckoutScope) -> AnyView)?,
        presentationContext: PresentationContext,
        onCompletion: (() -> Void)?
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.diContainer = diContainer
        self.navigator = navigator
        self.scope = scope
        self.customContent = customContent
        self.presentationContext = presentationContext
        self.onCompletion = onCompletion

        // Don't create checkout scope until SDK is initialized
        self._checkoutScope = State(initialValue: nil)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Show initialization state first
            if isInitializing {
                SDKInitializationLoadingView()
            } else if let error = initializationError {
                SDKInitializationErrorView(error: error) {
                    Task {
                        await initializeSDK()
                    }
                }
            } else if sdkInitialized, let checkoutScope = checkoutScope {
                // Only show the checkout UI when SDK is fully initialized and scope is created
                CheckoutScopeObserver(scope: checkoutScope, customContent: customContent, scopeCustomization: scope, onCompletion: onCompletion)
            } else {
                // This shouldn't happen, but show loading as fallback
                SDKInitializationLoadingView()
            }
        }
        .task {
            // Initialize SDK first, before anything else
            await initializeSDK()
        }
    }

    // MARK: - SDK Initialization

    /// Initialize the SDK using the same pattern as CheckoutComponentsPrimer
    private func initializeSDK() async {
        guard !isInitializing && !sdkInitialized else { return }

        isInitializing = true
        initializationError = nil

        do {
            try await performSDKInitialization()
            await finalizeSDKInitialization()
        } catch {
            handleInitializationError(error)
        }
    }

    private func performSDKInitialization() async throws {
        // Follow the exact same pattern as CheckoutComponentsPrimer.swift:267-317
        setupSDKIntegration()
        DependencyContainer.register(settings as PrimerSettingsProtocol)
        try await initializeAPIConfiguration()

        let composableContainer = ComposableContainer(settings: settings)
        await composableContainer.configure()
    }

    private func setupSDKIntegration() {
        PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
        PrimerInternal.shared.intent = .checkout
        PrimerInternal.shared.checkoutSessionId = UUID().uuidString
    }

    private func initializeAPIConfiguration() async throws {
        let apiConfigurationModule = PrimerAPIConfigurationModule()

        try await apiConfigurationModule.setupSession(
            forClientToken: clientToken,
            requestDisplayMetadata: true,
            requestClientTokenValidation: false,
            requestVaultedPaymentMethods: false
        )
    }

    private func finalizeSDKInitialization() async {
        // Create settings service
        let settingsService = CheckoutComponentsSettingsService(settings: settings)

        let defaultScope = DefaultCheckoutScope(
            clientToken: clientToken,
            settingsService: settingsService,
            diContainer: diContainer,
            navigator: navigator,
            presentationContext: presentationContext
        )

        checkoutScope = defaultScope
        sdkInitialized = true
        isInitializing = false

        if presentationContext == .direct {
            defaultScope.checkoutNavigator.navigateToPaymentMethod("PAYMENT_CARD", context: .direct)
        }
    }

    private func handleInitializationError(_ error: Error) {
        isInitializing = false

        if let primerError = error as? PrimerError {
            initializationError = primerError
        } else {
            initializationError = PrimerError.underlyingErrors(errors: [error])
        }
    }
}
