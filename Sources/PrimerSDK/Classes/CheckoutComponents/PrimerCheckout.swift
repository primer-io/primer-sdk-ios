//
//  PrimerCheckout.swift
//  PrimerSDK
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// The main entry point for CheckoutComponents, providing a SwiftUI view for payment checkout.
/// This API matches the Android Composable API exactly for cross-platform consistency.
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

    /// DI container (internal use only)
    internal let diContainer: DIContainer

    /// Navigator (internal use only)
    internal let navigator: CheckoutNavigator

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
        self.diContainer = DIContainer.shared
        self.navigator = CheckoutNavigator()
    }

    /// Internal initializer with custom content
    internal init(
        clientToken: String,
        settings: PrimerSettings = PrimerSettings(),
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        @ViewBuilder customContent: @escaping (PrimerCheckoutScope) -> some View
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.scope = nil
        self.customContent = { scope in AnyView(customContent(scope)) }
        self.onCompletion = nil
        self.diContainer = diContainer
        self.navigator = navigator
    }

    /// Internal initializer with DI container and navigator
    internal init(
        clientToken: String,
        settings: PrimerSettings,
        diContainer: DIContainer,
        navigator: CheckoutNavigator
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.scope = nil
        self.customContent = nil
        self.onCompletion = nil
        self.diContainer = diContainer
        self.navigator = navigator
    }

    public var body: some View {
        // The internal implementation will be created in Phase 5
        // For now, return a placeholder that will be replaced
        InternalCheckout(
            clientToken: clientToken,
            settings: settings,
            diContainer: diContainer,
            navigator: navigator,
            scope: scope,
            customContent: customContent,
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
        onCompletion: (() -> Void)?
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.diContainer = diContainer
        self.navigator = navigator
        self.scope = scope
        self.customContent = customContent
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
            // Follow the exact same pattern as CheckoutComponentsPrimer.swift:267-317
            // Step 1: Set up SDK integration type and intent
            PrimerInternal.shared.sdkIntegrationType = .checkoutComponents
            PrimerInternal.shared.intent = .checkout
            PrimerInternal.shared.checkoutSessionId = UUID().uuidString

            // Step 2: Register settings in dependency container
            DependencyContainer.register(settings as PrimerSettingsProtocol)

            // Step 3: Initialize SDK session using configuration module
            let apiConfigurationModule = PrimerAPIConfigurationModule()

            try await withCheckedThrowingContinuation { continuation in
                firstly {
                    apiConfigurationModule.setupSession(
                        forClientToken: clientToken,
                        requestDisplayMetadata: true,
                        requestClientTokenValidation: false,
                        requestVaultedPaymentMethods: false
                    )
                }
                .done {
                    continuation.resume()
                }
                .catch { error in
                    continuation.resume(throwing: error)
                }
            }

            // Step 4: Configure CheckoutComponents DI container
            let composableContainer = ComposableContainer()
            await composableContainer.configure()

            // SDK is now ready - create the checkout scope
            let defaultScope = DefaultCheckoutScope(
                clientToken: clientToken,
                settings: settings,
                diContainer: diContainer,
                navigator: navigator
            )

            checkoutScope = defaultScope
            sdkInitialized = true
            isInitializing = false

        } catch {
            isInitializing = false

            // Convert to PrimerError if needed
            if let primerError = error as? PrimerError {
                initializationError = primerError
            } else {
                initializationError = PrimerError.underlyingErrors(
                    errors: [error],
                    userInfo: .errorUserInfoDictionary(
                        additionalInfo: ["message": "SDK initialization failed"]
                    ),
                    diagnosticsId: UUID().uuidString
                )
            }
        }
    }
}
// MARK: - Generic Payment Method Screen

/// Generic payment method screen that dynamically resolves and displays any payment method
@available(iOS 15.0, *)
@MainActor
internal struct PaymentMethodScreen: View {
    let paymentMethodType: String
    let checkoutScope: PrimerCheckoutScope

    var body: some View {
        // Truly generic dynamic scope resolution for ANY payment method
        Group {
            // Use non-generic method to get the scope as existential type, then check specific types
            if let paymentMethodScope = try? PaymentMethodRegistry.shared.createScope(
                for: paymentMethodType,
                checkoutScope: checkoutScope,
                diContainer: (checkoutScope as? DefaultCheckoutScope)?.diContainer ?? DIContainer.shared
            ) {
                // Check if this is a card form scope specifically
                if let cardFormScope = paymentMethodScope as? any PrimerCardFormScope {
                    // Use the default CardFormScreen for now
                    // Custom screen support can be added later through a different mechanism
                    AnyView(CardFormScreen(scope: cardFormScope))
                } else {
                    // For other payment method scopes in the future, we'll add similar type checks here
                    // For now, show placeholder for non-card payment methods
                    PaymentMethodPlaceholder(paymentMethodType: paymentMethodType)
                }
            } else {
                // This payment method doesn't have a scope implementation yet
                // Show placeholder that works for any payment method type
                PaymentMethodPlaceholder(paymentMethodType: paymentMethodType)
            }
        }
    }
}

/// Placeholder screen for payment methods that don't have implemented scopes yet
@available(iOS 15.0, *)
@MainActor
internal struct PaymentMethodPlaceholder: View {
    let paymentMethodType: String

    var body: some View {
        AnyView(
            VStack(spacing: 16) {
                Image(systemName: paymentMethodIcon)
                    .font(.system(size: 48))
                    .foregroundColor(.gray)

                Text("Payment Method: \(displayName)")
                    .font(.headline)

                Text("Implementation coming soon")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        )
    }

    private var displayName: String {
        PrimerPaymentMethodType(rawValue: paymentMethodType)?.checkoutComponentsDisplayName ?? paymentMethodType
    }

    private var paymentMethodIcon: String {
        switch paymentMethodType {
        case "PAYMENT_CARD": return "creditcard"
        case "APPLE_PAY": return "applelogo"
        case "GOOGLE_PAY": return "wallet.pass"
        case "PAYPAL": return "dollarsign.circle"
        default: return "creditcard"
        }
    }
}

// MARK: - Checkout Scope Observer

/// Wrapper view that properly observes the DefaultCheckoutScope as an ObservableObject
@available(iOS 15.0, *)
internal struct CheckoutScopeObserver: View, LogReporter {
    @ObservedObject private var scope: DefaultCheckoutScope
    private let customContent: ((PrimerCheckoutScope) -> AnyView)?
    private let scopeCustomization: ((PrimerCheckoutScope) -> Void)?
    private let onCompletion: (() -> Void)?
    @Environment(\.dismiss) private var dismiss

    init(scope: DefaultCheckoutScope, customContent: ((PrimerCheckoutScope) -> AnyView)?, scopeCustomization: ((PrimerCheckoutScope) -> Void)?, onCompletion: (() -> Void)?) {
        self.scope = scope
        self.customContent = customContent
        self.scopeCustomization = scopeCustomization
        self.onCompletion = onCompletion
    }

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Navigation state driven UI (now properly observing @Published navigationState)
                ZStack {
                    switch scope.navigationState {
                    case .loading:
                        if let customLoading = scope.loadingScreen {
                            AnyView(customLoading())
                        } else {
                            AnyView(LoadingScreen())
                        }

                    case .paymentMethodSelection:
                        if let customPaymentSelection = scope.paymentMethodSelectionScreen {
                            AnyView(customPaymentSelection(scope.paymentMethodSelection))
                        } else {
                            AnyView(PaymentMethodSelectionScreen(
                                scope: scope.paymentMethodSelection
                            ))
                        }

                    case .paymentMethod(let paymentMethodType):
                        // Handle all payment method types using truly unified dynamic approach
                        PaymentMethodScreen(
                            paymentMethodType: paymentMethodType,
                            checkoutScope: scope
                        )

                    case .success(let result):
                        if let customSuccess = scope.successScreen {
                            AnyView(customSuccess(result))
                        } else {
                            AnyView(SuccessScreen(result: result) {
                                // Handle auto-dismiss with completion callback
                                logger.info(message: "Success screen auto-dismiss, calling completion callback")
                                onCompletion?()
                            })
                        }

                    case .failure(let error):
                        if let customError = scope.errorScreen {
                            AnyView(customError(error.localizedDescription))
                        } else {
                            AnyView(ErrorScreen(error: error) {
                                // Handle auto-dismiss with completion callback
                                logger.info(message: "Error screen auto-dismiss, calling completion callback")
                                onCompletion?()
                            })
                        }
                    }

                    // Custom content overlay if provided
                    if let customContent = customContent {
                        customContent(scope)
                    }
                }
            }
            .environmentObject(scope)
            .environment(\.diContainer, DIContainer.currentSync)
        }
        .onAppear {
            // Apply any scope customizations (only after SDK is initialized)
            scopeCustomization?(scope)
        }
    }
}

// MARK: - SDK Initialization UI Components

/// Loading view shown during SDK initialization
@available(iOS 15.0, *)
internal struct SDKInitializationLoadingView: View {
    var body: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)

            Text("Initializing payment system...")
                .font(.headline)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

/// Error view shown when SDK initialization fails
@available(iOS 15.0, *)
internal struct SDKInitializationErrorView: View {
    let error: PrimerError
    let onRetry: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 48))
                .foregroundColor(.orange)

            Text("Payment System Error")
                .font(.headline)

            Text(error.localizedDescription)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal)

            Button("Retry") {
                onRetry()
            }
            .buttonStyle(.borderedProminent)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}
