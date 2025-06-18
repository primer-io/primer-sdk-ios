//
//  ComposablePrimerConfiguration.swift
//  
//
//  Created on 17.06.2025.
//

import Foundation

/// Configuration object for ComposableCheckout that wraps existing SDK configuration
@available(iOS 15.0, *)
internal struct PrimerConfiguration: LogReporter {
    let clientToken: String
    let settings: PrimerSettings
    
    init(clientToken: String, settings: PrimerSettings) {
        self.clientToken = clientToken
        self.settings = settings
        logger.debug(message: "🔧 [PrimerConfiguration] Configuration created with client token")
    }
}

/// Extension to provide easy access to default settings
@available(iOS 15.0, *)
extension PrimerSettings {
    static var `default`: PrimerSettings {
        // Use the existing SDK's default settings
        return PrimerSettings(
            paymentHandling: .auto,
            localeData: PrimerLocaleData(language: .current),
            paymentMethodOptions: PrimerPaymentMethodOptions(),
            uiOptions: PrimerUIOptions(),
            debugOptions: PrimerDebugOptions(),
            clientSessionCachingEnabled: true,
            apiVersion: .v2024_09_10
        )
    }
}