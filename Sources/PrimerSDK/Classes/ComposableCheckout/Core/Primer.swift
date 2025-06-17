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
    @ViewBuilder
    public static func ComposableCheckout(
        container: (@ViewBuilder (_ content: @escaping () -> any View) -> any View)? = nil,
        splashScreen: (@ViewBuilder () -> any View)? = nil,
        loadingScreen: (@ViewBuilder () -> any View)? = nil,
        paymentSelectionScreen: (@ViewBuilder () -> any View)? = nil,
        cardFormScreen: (@ViewBuilder () -> any View)? = nil,
        successScreen: (@ViewBuilder () -> any View)? = nil,
        errorScreen: (@ViewBuilder (_ cause: String) -> any View)? = nil
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