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
@available(iOS 15.0, *)
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
            VStack(spacing: 0) {
                // Navigation state driven UI
                ZStack {
                    switch checkoutScope.navigationState {
                    case .loading:
                        if let customLoading = checkoutScope.loadingScreen {
                            AnyView(customLoading())
                        } else {
                            AnyView(LoadingScreen())
                        }

                    case .paymentMethodSelection:
                        if let customPaymentSelection = checkoutScope.paymentMethodSelectionScreen {
                            AnyView(customPaymentSelection(checkoutScope.paymentMethodSelection))
                        } else {
                            AnyView(PaymentMethodSelectionScreen(
                                scope: checkoutScope.paymentMethodSelection
                            ))
                        }

                    case .paymentMethod(let paymentMethodType):
                        // Handle all payment method types using truly unified dynamic approach
                        PaymentMethodScreen(
                            paymentMethodType: paymentMethodType,
                            checkoutScope: checkoutScope
                        )

                    // Note: Success case removed - CheckoutComponents dismisses immediately on success
                    // The delegate handles presenting the result screen via PrimerResultViewController

                    case .failure(let error):
                        if let customError = checkoutScope.errorScreen {
                            AnyView(customError(error.localizedDescription))
                        } else {
                            AnyView(ErrorScreen(error: error))
                        }
                    }

                    // Custom content overlay if provided
                    if let customContent = customContent {
                        customContent(checkoutScope)
                    }
                }
            }
            .environmentObject(checkoutScope)
            .environment(\.diContainer, DIContainer.currentSync)
        }
        .onAppear {
            // Apply any scope customizations
            scope?(checkoutScope)
        }
        .task {
            // Observe checkout state for dismissal
            for await state in checkoutScope.state {
                if case .dismissed = state {
                    // Trigger dismissal of the checkout
                    // This will be handled by the hosting controller
                    break
                }
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
