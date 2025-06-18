//
//  Primer.swift
//
//
//  Created on 17.06.2025.
//

import SwiftUI

/// Static ComposablePrimer object that matches Android's API structure.
/// Provides a simple configuration pattern and scope-based ComposableCheckout.
@available(iOS 15.0, *)
public struct ComposablePrimer: LogReporter {

    // MARK: - Configuration Storage

    /// Current configuration set via configure() method
    internal static var configuration: ComposablePrimerConfiguration?

    // MARK: - Public API

    /// Configure Primer with client token and settings.
    /// This matches Android's Primer.configure() method exactly.
    ///
    /// - Parameters:
    ///   - clientToken: The client token for Primer SDK
    ///   - settings: Configuration settings (defaults to .default)
    public static func configure(
        clientToken: String,
        settings: ComposablePrimerSettings = .default
    ) {
        logger.debug(message: "🔧 [ComposablePrimer] Configuring with client token")

        self.configuration = ComposablePrimerConfiguration(
            clientToken: clientToken,
            settings: settings
        )

        logger.info(message: "✅ [ComposablePrimer] Configuration completed")
    }

    /// ComposableCheckout that matches Android's API structure with direct ViewBuilder support.
    /// This version eliminates the need for AnyView wrapping, providing a more Android-like experience.
    ///
    /// - Parameters:
    ///   - container: Custom container wrapper for the entire checkout flow
    ///   - splashScreen: Custom splash screen implementation
    ///   - loadingScreen: Custom loading screen implementation
    ///   - paymentSelectionScreen: Custom payment selection screen implementation
    ///   - cardFormScreen: Custom card form screen implementation
    ///   - successScreen: Custom success screen implementation
    ///   - errorScreen: Custom error screen implementation (receives error message)
    /// - Returns: SwiftUI view for the checkout flow
    // swiftlint:disable identifier_name
    public static func ComposableCheckout<Container: View, Splash: View, Loading: View, PaymentSelection: View, CardForm: View, Success: View, Error: View>(
        @ViewBuilder container: @escaping (_ content: @escaping () -> AnyView) -> Container = { content in AnyView(content()) },
        @ViewBuilder splashScreen: @escaping () -> Splash = { AnyView(EmptyView()) },
        @ViewBuilder loadingScreen: @escaping () -> Loading = { AnyView(EmptyView()) },
        @ViewBuilder paymentSelectionScreen: @escaping () -> PaymentSelection = { AnyView(EmptyView()) },
        @ViewBuilder cardFormScreen: @escaping () -> CardForm = { AnyView(EmptyView()) },
        @ViewBuilder successScreen: @escaping () -> Success = { AnyView(EmptyView()) },
        @ViewBuilder errorScreen: @escaping (_ cause: String) -> Error = { _ in AnyView(EmptyView()) }
    ) -> some View {
        ModernComposableCheckoutView(
            container: { content in AnyView(container(content)) },
            splashScreen: { AnyView(splashScreen()) },
            loadingScreen: { AnyView(loadingScreen()) },
            paymentSelectionScreen: { AnyView(paymentSelectionScreen()) },
            cardFormScreen: { AnyView(cardFormScreen()) },
            successScreen: { AnyView(successScreen()) },
            errorScreen: { cause in AnyView(errorScreen(cause)) }
        )
    }

    /// Legacy ComposableCheckout that maintains backward compatibility
    /// - Note: Use the generic version above for better Android compatibility
    public static func ComposableCheckout(
        container: ((_ content: @escaping () -> AnyView) -> AnyView)? = nil,
        splashScreen: (() -> AnyView)? = nil,
        loadingScreen: (() -> AnyView)? = nil,
        paymentSelectionScreen: (() -> AnyView)? = nil,
        cardFormScreen: (() -> AnyView)? = nil,
        successScreen: (() -> AnyView)? = nil,
        errorScreen: ((_ cause: String) -> AnyView)? = nil
    ) -> some View {
        ComposableCheckoutView(
            container: container,
            splashScreen: splashScreen,
            loadingScreen: loadingScreen,
            paymentSelectionScreen: paymentSelectionScreen,
            cardFormScreen: cardFormScreen,
            successScreen: successScreen,
            errorScreen: errorScreen
        )
    }
    // swiftlint:enable identifier_name
}
