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
    
    /// ComposableCheckout that matches Android's API structure.
    /// Provides customizable screen implementations using ViewBuilder closures.
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
}

