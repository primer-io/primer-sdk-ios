//
//  PrimerCheckout.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Pure SwiftUI implementation for CheckoutComponents SDK.
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
///             cardFormScope.cardNumberField = { label, styling in
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

    /// Navigator for coordinating navigation
    @StateObject private var navigator: CheckoutNavigator

    /// Presentation context determining navigation behavior
    private let presentationContext: PresentationContext

    /// Creates a new PrimerCheckout view.
    /// - Parameters:
    ///   - clientToken: The client token obtained from your backend.
    ///   - primerSettings: Configuration settings including payment options and UI preferences.
    ///   - scope: Optional closure to customize UI components through the scope interface.
    ///   - onCompletion: Optional completion callback called when checkout completes or dismisses.
    public init(
        clientToken: String,
        primerSettings: PrimerSettings = PrimerSettings(),
        scope: ((PrimerCheckoutScope) -> Void)? = nil,
        onCompletion: (() -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = primerSettings
        self.scope = scope
        self.customContent = nil
        self.onCompletion = onCompletion
        self._navigator = StateObject(wrappedValue: CheckoutNavigator())
        self.presentationContext = .fromPaymentSelection
    }

    /// Internal initializer with presentation context
    init(
        clientToken: String,
        primerSettings: PrimerSettings,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        presentationContext: PresentationContext,
        onCompletion: (() -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = primerSettings
        self.scope = nil
        self.customContent = nil
        self.onCompletion = onCompletion
        self._navigator = StateObject(wrappedValue: navigator)
        self.presentationContext = presentationContext
    }

    /// Internal initializer with custom content and presentation context
    init(
        clientToken: String,
        primerSettings: PrimerSettings,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        customContent: ((PrimerCheckoutScope) -> AnyView)?,
        presentationContext: PresentationContext,
        onCompletion: (() -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = primerSettings
        self.scope = nil
        self.customContent = customContent
        self.onCompletion = onCompletion
        self._navigator = StateObject(wrappedValue: navigator)
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

/// Internal checkout implementation that coordinates SDK initialization and UI presentation.
@available(iOS 15.0, *)
@MainActor
struct InternalCheckout: View {
    private let clientToken: String
    private let settings: PrimerSettings
    private let diContainer: DIContainer
    private let navigator: CheckoutNavigator
    private let scope: ((PrimerCheckoutScope) -> Void)?
    private let customContent: ((PrimerCheckoutScope) -> AnyView)?
    private let presentationContext: PresentationContext
    private let onCompletion: (() -> Void)?

    @State private var checkoutScope: DefaultCheckoutScope?
    @State private var initializationState: InitializationState = .idle

    private let sdkInitializer: CheckoutSDKInitializer

    enum InitializationState {
        case idle
        case initializing
        case initialized
        case failed(PrimerError)
    }

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

        self.sdkInitializer = CheckoutSDKInitializer(
            clientToken: clientToken,
            primerSettings: settings,
            diContainer: diContainer,
            navigator: navigator,
            presentationContext: presentationContext
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            switch initializationState {
            case .idle, .initializing:
                SplashScreen()
            case .initialized:
                if let checkoutScope = checkoutScope {
                    CheckoutScopeObserver(
                        scope: checkoutScope,
                        customContent: customContent,
                        scopeCustomization: scope,
                        onCompletion: onCompletion
                    )
                } else {
                    SplashScreen()
                }
            case let .failed(error):
                SDKInitializationErrorView(error: error) {
                    Task {
                        await initializeSDK()
                    }
                }
            }
        }
        .applyAppearanceMode(settings.uiOptions.appearanceMode)
        .task {
            await initializeSDK()
        }
        .onDisappear {
            sdkInitializer.cleanup()
        }
    }

    // MARK: - Private Methods

    private func initializeSDK() async {
        guard case .idle = initializationState else { return }

        initializationState = .initializing

        do {
            let result = try await sdkInitializer.initialize()
            checkoutScope = result.checkoutScope
            initializationState = .initialized
        } catch {
            let primerError = error as? PrimerError ?? PrimerError.underlyingErrors(errors: [error])
            initializationState = .failed(primerError)
        }
    }
}

// MARK: - Appearance Mode Support

@available(iOS 15.0, *)
private extension View {
    /// Applies appearance mode to the view
    @ViewBuilder
    func applyAppearanceMode(_ mode: PrimerAppearanceMode) -> some View {
        switch mode {
        case .system:
            self
        case .light:
            self.preferredColorScheme(.light)
        case .dark:
            self.preferredColorScheme(.dark)
        }
    }
}
