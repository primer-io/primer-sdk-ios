//
//  Primer.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI

/// Static Primer object that matches Android's API structure.
/// Provides a simple configuration pattern and scope-based ComposableCheckout.
@available(iOS 15.0, *)
public struct Primer: LogReporter {
    
    // MARK: - Configuration Storage
    
    /// Current configuration set via configure() method
    internal static var configuration: PrimerConfiguration?
    
    // MARK: - Public API
    
    /// Configure Primer with client token and settings.
    /// This matches Android's Primer.configure() method exactly.
    /// 
    /// - Parameters:
    ///   - clientToken: The client token for Primer SDK
    ///   - settings: Configuration settings (defaults to .default)
    public static func configure(
        clientToken: String,
        settings: PrimerSettings = .default
    ) {
        logger.debug(message: "🔧 [Primer] Configuring with client token")
        
        self.configuration = PrimerConfiguration(
            clientToken: clientToken,
            settings: settings
        )
        
        logger.info(message: "✅ [Primer] Configuration completed")
    }
    
    /// ComposableCheckout that matches Android's API structure.
    /// Each screen parameter receives the appropriate scope as a parameter.
    ///
    /// - Parameters:
    ///   - container: Custom container for the entire checkout flow
    ///   - splashScreen: Custom splash screen (receives PrimerCheckoutScope)
    ///   - loadingScreen: Custom loading screen (receives PrimerCheckoutScope)
    ///   - paymentSelectionScreen: Custom payment selection screen (receives PaymentMethodSelectionScope)
    ///   - cardFormScreen: Custom card form screen (receives CardFormScope)
    ///   - successScreen: Custom success screen (receives PrimerCheckoutScope)
    ///   - errorScreen: Custom error screen (receives PrimerCheckoutScope and error message)
    /// - Returns: SwiftUI view for the checkout flow
    @ViewBuilder
    public static func ComposableCheckout<Container: View>(
        container: ((AnyView) -> Container)? = nil,
        splashScreen: ((PrimerCheckoutScope) -> AnyView)? = nil,
        loadingScreen: ((PrimerCheckoutScope) -> AnyView)? = nil,
        paymentSelectionScreen: ((PaymentMethodSelectionScope) -> AnyView)? = nil,
        cardFormScreen: ((CardFormScope) -> AnyView)? = nil,
        successScreen: ((PrimerCheckoutScope) -> AnyView)? = nil,
        errorScreen: ((PrimerCheckoutScope, String) -> AnyView)? = nil
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

// MARK: - Internal Configuration Model

/// Internal configuration storage that holds client token and settings
internal struct PrimerConfiguration: LogReporter {
    let clientToken: String
    let settings: PrimerSettings
    
    init(clientToken: String, settings: PrimerSettings) {
        self.clientToken = clientToken
        self.settings = settings
        
        logger.debug(message: "📋 [PrimerConfiguration] Created with token: \(clientToken.prefix(8))...")
    }
}

// MARK: - Public Settings Model

/// Public settings model that matches Android's structure
public struct PrimerSettings {
    
    /// Default settings instance
    public static let `default` = PrimerSettings()
    
    // Additional settings properties can be added here as needed
    // to match Android's PrimerSettings structure
    
    public init() {
        // Initialize with default values
    }
}