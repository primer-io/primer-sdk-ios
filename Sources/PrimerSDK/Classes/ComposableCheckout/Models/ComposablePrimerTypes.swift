//
//  ComposablePrimerTypes.swift
//
//
//  Created on 17.06.2025.
//

import Foundation

/// Internal configuration storage that holds client token and settings
@available(iOS 15.0, *)
internal struct ComposablePrimerConfiguration: LogReporter {
    let clientToken: String
    let settings: ComposablePrimerSettings

    init(clientToken: String, settings: ComposablePrimerSettings) {
        self.clientToken = clientToken
        self.settings = settings

        logger.debug(message: "📋 [ComposablePrimerConfiguration] Created with token: \(clientToken.prefix(8))...")
    }
}

/// Public settings model that matches Android's structure
@available(iOS 15.0, *)
public struct ComposablePrimerSettings {

    /// Default settings instance
    public static let `default` = ComposablePrimerSettings()

    // Additional settings properties can be added here as needed
    // to match Android's PrimerSettings structure

    public init() {
        // Initialize with default values
    }
}
