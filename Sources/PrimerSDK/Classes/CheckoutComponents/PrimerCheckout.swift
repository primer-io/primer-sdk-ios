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
///         // Customize components
///         checkoutScope.cardForm.cardNumberInput = { _ in
///             CustomCardNumberField()
///         }
///     }
/// )
/// ```
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
    
    /// DI container (internal use only)
    internal let diContainer: DIContainer
    
    /// Navigator (internal use only)
    internal let navigator: CheckoutNavigator
    
    /// Creates a new PrimerCheckout view.
    /// - Parameters:
    ///   - clientToken: The client token obtained from your backend.
    ///   - settings: Configuration settings including theme and payment options.
    ///   - scope: Optional closure to customize UI components through the scope interface.
    public init(
        clientToken: String,
        settings: PrimerSettings = PrimerSettings(),
        scope: ((PrimerCheckoutScope) -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.scope = scope
        self.customContent = nil
        self.diContainer = DIContainer()
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
            customContent: customContent
        )
    }
}

// MARK: - Internal Implementation

/// Internal checkout implementation that manages the full checkout flow.
@MainActor
internal struct InternalCheckout: View {
    let clientToken: String
    let settings: PrimerSettings
    let diContainer: DIContainer
    let navigator: CheckoutNavigator
    let scope: ((PrimerCheckoutScope) -> Void)?
    let customContent: ((PrimerCheckoutScope) -> AnyView)?
    
    @StateObject private var checkoutScope: DefaultCheckoutScope
    
    init(
        clientToken: String,
        settings: PrimerSettings,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        scope: ((PrimerCheckoutScope) -> Void)?,
        customContent: ((PrimerCheckoutScope) -> AnyView)?
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.diContainer = diContainer
        self.navigator = navigator
        self.scope = scope
        self.customContent = customContent
        
        // Create the checkout scope
        let defaultScope = DefaultCheckoutScope(
            clientToken: clientToken,
            settings: settings,
            diContainer: diContainer,
            navigator: navigator
        )
        self._checkoutScope = StateObject(wrappedValue: defaultScope)
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Navigation state driven UI
                switch checkoutScope.navigationState {
                case .loading:
                    if let customLoading = checkoutScope.loadingScreen {
                        customLoading()
                    } else {
                        LoadingScreen()
                    }
                    
                case .paymentMethodSelection:
                    if let customPaymentSelection = checkoutScope.paymentMethodSelectionScreen {
                        customPaymentSelection(checkoutScope.paymentMethodSelection)
                    } else {
                        PaymentMethodSelectionScreen(
                            scope: checkoutScope.paymentMethodSelection,
                            onDismiss: checkoutScope.onDismiss
                        )
                    }
                    
                case .cardForm:
                    if let customCardForm = checkoutScope.cardFormScreen {
                        customCardForm(checkoutScope.cardForm)
                    } else {
                        CardFormScreen(
                            scope: checkoutScope.cardForm,
                            onDismiss: checkoutScope.onDismiss
                        )
                    }
                    
                case .success(let result):
                    if let customSuccess = checkoutScope.successScreen {
                        customSuccess()
                    } else {
                        SuccessScreen(
                            result: result,
                            onDismiss: checkoutScope.onDismiss
                        )
                    }
                    
                case .error(let error):
                    if let customError = checkoutScope.errorScreen {
                        customError(error.localizedDescription)
                    } else {
                        ErrorScreen(
                            error: error,
                            onRetry: {
                                // Retry logic would go here
                            },
                            onDismiss: checkoutScope.onDismiss
                        )
                    }
                }
                
                // Custom content overlay if provided
                if let customContent = customContent {
                    customContent(checkoutScope)
                }
            }
            .environmentObject(checkoutScope)
            .environment(\.diContainer, diContainer)
            .environment(\.checkoutNavigator, navigator)
        }
        .onAppear {
            // Apply any scope customizations
            scope?(checkoutScope)
        }
    }
}