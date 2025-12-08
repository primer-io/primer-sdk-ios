//
//  PrimerCheckout.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Pure SwiftUI implementation for CheckoutComponents SDK.
///
/// Example usage (minimal):
/// ```swift
/// PrimerCheckout(clientToken: "your_client_token")
/// ```
///
/// With component customization:
/// ```swift
/// PrimerCheckout(
///     clientToken: "your_client_token",
///     primerSettings: PrimerSettings(),
///     primerTheme: PrimerCheckoutTheme(),
///     components: PrimerComponents(
///         checkout: .init(
///             splash: { AnyView(CustomSplash()) },
///             navigation: .init(
///                 onSuccess: { { print("Success!") } }
///             )
///         ),
///         paymentMethodConfigurations: [
///             PrimerComponents.CardForm(
///                 cardDetails: .init(
///                     cardNumber: { AnyView(CustomCardNumberField()) }
///                 )
///             )
///         ]
///     ),
///     onCompletion: { print("Checkout completed") }
/// )
/// ```
@available(iOS 15.0, *)
@MainActor
public struct PrimerCheckout: View {

    private let clientToken: String
    private let settings: PrimerSettings
    private let theme: PrimerCheckoutTheme
    private let components: PrimerComponents
    private let customContent: ((PrimerCheckoutScope) -> AnyView)?
    private let onCompletion: (() -> Void)?
    @StateObject private var navigator: CheckoutNavigator
    private let presentationContext: PresentationContext

    /// Creates a PrimerCheckout view.
    /// - Parameters:
    ///   - clientToken: The client token obtained from your backend.
    ///   - primerSettings: Configuration settings including payment options and UI preferences. Default: `PrimerSettings()`
    ///   - primerTheme: Theme configuration for design tokens. Default: `PrimerCheckoutTheme()`
    ///   - components: Immutable UI component configuration. Default: `PrimerComponents()`
    ///   - onCompletion: Optional completion callback called when checkout completes or dismisses.
    public init(
        clientToken: String,
        primerSettings: PrimerSettings = PrimerSettings(),
        primerTheme: PrimerCheckoutTheme = PrimerCheckoutTheme(),
        components: PrimerComponents = PrimerComponents(),
        onCompletion: (() -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = primerSettings
        self.theme = primerTheme
        self.components = components
        self.customContent = nil
        self.onCompletion = onCompletion
        self._navigator = StateObject(wrappedValue: CheckoutNavigator())
        self.presentationContext = .fromPaymentSelection
    }

    init(
        clientToken: String,
        primerSettings: PrimerSettings,
        primerTheme: PrimerCheckoutTheme,
        components: PrimerComponents,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        presentationContext: PresentationContext,
        onCompletion: (() -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = primerSettings
        self.theme = primerTheme
        self.components = components
        self.customContent = nil
        self.onCompletion = onCompletion
        self._navigator = StateObject(wrappedValue: navigator)
        self.presentationContext = presentationContext
    }

    init(
        clientToken: String,
        primerSettings: PrimerSettings,
        primerTheme: PrimerCheckoutTheme,
        components: PrimerComponents,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        customContent: ((PrimerCheckoutScope) -> AnyView)?,
        presentationContext: PresentationContext,
        onCompletion: (() -> Void)? = nil
    ) {
        self.clientToken = clientToken
        self.settings = primerSettings
        self.theme = primerTheme
        self.components = components
        self.customContent = customContent
        self.onCompletion = onCompletion
        self._navigator = StateObject(wrappedValue: navigator)
        self.presentationContext = presentationContext
    }

    public var body: some View {
        let checkoutContent = InternalCheckout(
            clientToken: clientToken,
            settings: settings,
            theme: theme,
            components: components,
            diContainer: DIContainer.shared,
            navigator: navigator,
            customContent: customContent,
            presentationContext: presentationContext,
            onCompletion: onCompletion
        )

        // Apply custom container if provided, otherwise pass through unchanged
        if let container = components.container {
            AnyView(container { AnyView(checkoutContent) })
        } else {
            AnyView(checkoutContent)
        }
    }
}

// MARK: - Internal Implementation

/// Internal checkout implementation that coordinates SDK initialization and UI presentation.
@available(iOS 15.0, *)
@MainActor
struct InternalCheckout: View {
    private let clientToken: String
    private let settings: PrimerSettings
    private let theme: PrimerCheckoutTheme
    private let components: PrimerComponents
    private let diContainer: DIContainer
    private let navigator: CheckoutNavigator
    private let customContent: ((PrimerCheckoutScope) -> AnyView)?
    private let presentationContext: PresentationContext
    private let onCompletion: (() -> Void)?

    @State private var checkoutScope: DefaultCheckoutScope?
    @State private var initializationState: InitializationState = .idle

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
        components: PrimerComponents,
        diContainer: DIContainer,
        navigator: CheckoutNavigator,
        customContent: ((PrimerCheckoutScope) -> AnyView)?,
        presentationContext: PresentationContext,
        onCompletion: (() -> Void)?
    ) {
        self.clientToken = clientToken
        self.settings = settings
        self.theme = theme
        self.components = components
        self.diContainer = diContainer
        self.navigator = navigator
        self.customContent = customContent
        self.presentationContext = presentationContext
        self.onCompletion = onCompletion

        self.sdkInitializer = CheckoutSDKInitializer(
            clientToken: clientToken,
            primerSettings: settings,
            primerTheme: theme,
            primerComponents: components,
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
                        components: components,
                        theme: theme,
                        customContent: customContent,
                        onCompletion: onCompletion
                    )
                } else {
                    splashContent
                }
            case let .failed(error):
                errorContent(error: error)
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

    // MARK: - Content Builders

    @ViewBuilder
    private var splashContent: some View {
        if let customSplash = components.checkout.splash {
            AnyView(customSplash())
        } else {
            SplashScreen()
        }
    }

    @ViewBuilder
    private var loadingContent: some View {
        if let customLoading = components.checkout.loading {
            AnyView(customLoading())
        } else {
            VStack {
                Spacer()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle())
                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
    }

    @ViewBuilder
    private func errorContent(error: PrimerError) -> some View {
        if let customError = components.checkout.error.content {
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
