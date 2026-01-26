//
//  PrimerCheckout.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Pure SwiftUI implementation for CheckoutComponents SDK.
///
/// Example usage (minimal):
/// ```swift
/// PrimerCheckout(clientToken: "your_client_token")
/// ```
///
/// With scope-based customization:
/// ```swift
/// PrimerCheckout(
///     clientToken: "your_client_token",
///     primerSettings: PrimerSettings(),
///     primerTheme: PrimerCheckoutTheme(),
///     scope: { checkoutScope in
///         // Customize checkout screens
///         checkoutScope.splashScreen = { CustomSplash() }
///
///         // Customize card form fields via InputFieldConfig
///         if let cardFormScope = checkoutScope.getPaymentMethodScope(PrimerCardFormScope.self) as? DefaultCardFormScope {
///             cardFormScope.cardNumberConfig = InputFieldConfig(placeholder: "Enter card number")
///             cardFormScope.cvvConfig = InputFieldConfig(styling: PrimerFieldStyling(borderColor: .blue))
///         }
///     },
///     onCompletion: { print("Checkout completed") }
/// )
/// ```
@available(iOS 15.0, *)
@MainActor
public struct PrimerCheckout: View {

    private let clientToken: String
    private let settings: PrimerSettings
    private let theme: PrimerCheckoutTheme
    private let scope: ((PrimerCheckoutScope) -> Void)?
    private let onCompletion: ((PrimerCheckoutState) -> Void)?
    @StateObject private var navigator: CheckoutNavigator
    private let presentationContext: PresentationContext
    private let integrationType: CheckoutComponentsIntegrationType

    /// Creates a PrimerCheckout view.
    /// - Parameters:
    ///   - clientToken: The client token obtained from your backend.
    ///   - primerSettings: Configuration settings including payment options and UI preferences. Default: `PrimerSettings()`
    ///   - primerTheme: Theme configuration for design tokens. Default: `PrimerCheckoutTheme()`
    ///   - scope: Optional closure to configure the checkout scope with custom UI components.
    ///   - onCompletion: Optional completion callback called when checkout completes with the final state (success, failure, or dismissed).
    public init(
        clientToken: String,
        primerSettings: PrimerSettings = PrimerSettings(),
        primerTheme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
        scope: ((PrimerCheckoutScope) -> Void)? = nil,
        onCompletion: ((PrimerCheckoutState) -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = primerSettings
        self.theme = primerTheme
        self.scope = scope
        self.onCompletion = onCompletion
        self._navigator = StateObject(wrappedValue: CheckoutNavigator())
        self.presentationContext = .fromPaymentSelection
        self.integrationType = .swiftUI
    }

    init(
        clientToken: String,
        primerSettings: PrimerSettings,
        primerTheme: PrimerCheckoutTheme,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        presentationContext: PresentationContext,
        integrationType: CheckoutComponentsIntegrationType,
        scope: ((PrimerCheckoutScope) -> Void)? = nil,
        onCompletion: ((PrimerCheckoutState) -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = primerSettings
        self.theme = primerTheme
        self.scope = scope
        self.onCompletion = onCompletion
        self._navigator = StateObject(wrappedValue: navigator)
        self.presentationContext = presentationContext
        self.integrationType = integrationType
    }

    public var body: some View {
        InternalCheckout(
            clientToken: clientToken,
            settings: settings,
            theme: theme,
            diContainer: DIContainer.shared,
            navigator: navigator,
            scope: scope,
            presentationContext: presentationContext,
            integrationType: integrationType,
            onCompletion: onCompletion
        )
    }
}

// MARK: - Internal Implementation

/// Internal checkout implementation that coordinates SDK initialization and UI presentation.
@available(iOS 15.0, *)
@MainActor
struct InternalCheckout: View, LogReporter {
    private let clientToken: String
    private let settings: PrimerSettings
    private let theme: PrimerCheckoutTheme
    private let diContainer: DIContainer
    private let navigator: CheckoutNavigator
    private let scope: ((PrimerCheckoutScope) -> Void)?
    private let presentationContext: PresentationContext
    private let integrationType: CheckoutComponentsIntegrationType
    private let onCompletion: ((PrimerCheckoutState) -> Void)?

    @State private var checkoutScope: DefaultCheckoutScope?
    @State private var initializationState: InitializationState = .idle
    @Environment(\.colorScheme) private var colorScheme

    // Design tokens state for early theme application (splash screen)
    @StateObject private var designTokensManager = DesignTokensManager()

    private let sdkInitializer: CheckoutSDKInitializer

    enum InitializationState {
        case idle
        case initializing
        case retrying
        case initialized
        case failed(PrimerError)
    }

    init(
        clientToken: String,
        settings: PrimerSettings,
        theme: PrimerCheckoutTheme,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        scope: ((PrimerCheckoutScope) -> Void)?,
        presentationContext: PresentationContext,
        integrationType: CheckoutComponentsIntegrationType,
        onCompletion: ((PrimerCheckoutState) -> Void)?
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.theme = theme
        self.diContainer = diContainer
        self.navigator = navigator
        self.scope = scope
        self.presentationContext = presentationContext
        self.integrationType = integrationType
        self.onCompletion = onCompletion

        self.sdkInitializer = CheckoutSDKInitializer(
            clientToken: clientToken,
            primerSettings: settings,
            primerTheme: theme,
            diContainer: diContainer,
            navigator: navigator,
            presentationContext: presentationContext
        )
    }

    var body: some View {
        VStack(spacing: 0) {
            switch initializationState {
            case .idle, .initializing:
                splashContent
            case .retrying:
                loadingContent
            case .initialized:
                if let checkoutScope {
                    CheckoutScopeObserver(
                        scope: checkoutScope,
                        theme: theme,
                        onCompletion: onCompletion
                    )
                } else {
                    splashContent
                }
            case let .failed(error):
                errorContent(error: error)
            }
        }
        .background(backgroundColor)
        .environment(\.designTokens, designTokensManager.tokens)
        .applyAppearanceMode(settings.uiOptions.appearanceMode)
        .environment(\.layoutDirection, RTLSupport.layoutDirection)
        .task {
            await LoggingSessionContext.shared.recordInitStartTime()
            await LoggingSessionContext.shared.initialize(clientToken: clientToken, integrationType: integrationType)
            await setupDesignTokens()
            await initializeSDK()
        }
        .onChange(of: colorScheme) { newColorScheme in
            Task {
                await loadDesignTokens(for: newColorScheme)
            }
        }
        .onDisappear {
            sdkInitializer.cleanup()
        }
    }

    // MARK: - Design Token Management

    /// Background color that uses theme override first, then loaded tokens, then system default.
    /// This ensures the background color is correct from the first render.
    private var backgroundColor: Color {
        // Priority 1: Theme override (available immediately)
        if let themeBackground = theme.colors?.primerColorBackground {
            return themeBackground
        }
        // Priority 2: Loaded design tokens (available after async load)
        if let tokens = designTokensManager.tokens {
            return CheckoutColors.background(tokens: tokens)
        }
        // Priority 3: System default based on color scheme
        return colorScheme == .dark ? Color(white: 0.11) : .white
    }

    private func setupDesignTokens() async {
        designTokensManager.applyTheme(theme)
        await loadDesignTokens(for: colorScheme)
    }

    private func loadDesignTokens(for colorScheme: ColorScheme) async {
        do {
            try await designTokensManager.fetchTokens(for: colorScheme)
        } catch {
            logger.error(message: "[InternalCheckout] Failed to load design tokens: \(error)")
        }
    }

    // MARK: - Content Builders

    @ViewBuilder
    private var splashContent: some View {
        if let customSplash = checkoutScope?.splashScreen {
            AnyView(customSplash())
        } else {
            SplashScreen()
        }
    }

    @ViewBuilder
    private var loadingContent: some View {
        if let customLoading = checkoutScope?.loading {
            AnyView(customLoading())
        } else {
            DefaultLoadingScreen()
        }
    }

    @ViewBuilder
    private func errorContent(error: PrimerError) -> some View {
        if let customError = checkoutScope?.errorScreen {
            AnyView(customError(error.localizedDescription))
        } else {
            SDKInitializationErrorView(error: error) {
                Task {
                    await initializeSDK(isRetry: true)
                }
            }
        }
    }

    // MARK: - Private Methods

    private func initializeSDK(isRetry: Bool = false) async {
        switch initializationState {
        case .idle:
            break
        case .failed:
            break
        default:
            return
        }

        initializationState = isRetry ? .retrying : .initializing

        do {
            let result = try await sdkInitializer.initialize()
            checkoutScope = result.checkoutScope

            // Apply scope configuration if provided
            if let scope {
                scope(checkoutScope!)
            }

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
