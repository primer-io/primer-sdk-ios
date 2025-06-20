//
//  ConfigurationRepository.swift
//
//
//  Created on 17.06.2025.
//

import Foundation

/// Repository interface for configuration management
@available(iOS 15.0, *)
internal protocol ConfigurationRepository: LogReporter {
    /// Initializes the configuration with the provided client token
    /// - Parameter clientToken: The client token for initialization
    /// - Returns: PrimerConfiguration object
    /// - Throws: Error if initialization fails
    func initialize(clientToken: String) async throws -> ComposablePrimerConfiguration

    /// Gets the current configuration if available
    /// - Returns: Current PrimerConfiguration or nil if not initialized
    func getCurrentConfiguration() -> ComposablePrimerConfiguration?
}

/// Implementation of ConfigurationRepository
@available(iOS 15.0, *)
internal class ConfigurationRepositoryImpl: ConfigurationRepository, LogReporter {

    // MARK: - Dependencies

    private let configurationService: ConfigurationService
    private var currentConfiguration: ComposablePrimerConfiguration?

    // MARK: - Initialization

    init(configurationService: ConfigurationService) {
        self.configurationService = configurationService
        logger.debug(message: "🏗️ [ConfigurationRepository] Initialized")
    }

    // MARK: - ConfigurationRepository

    func initialize(clientToken: String) async throws -> ComposablePrimerConfiguration {
        logger.debug(message: "🔧 [ConfigurationRepository] Initializing configuration")

        do {
            let config = try await configurationService.initialize(clientToken: clientToken)
            self.currentConfiguration = config

            logger.info(message: "✅ [ConfigurationRepository] Configuration initialized successfully")
            logger.debug(message: "📋 [ConfigurationRepository] Client token: \(clientToken.prefix(8))...")

            return config

        } catch {
            logger.error(message: "❌ [ConfigurationRepository] Configuration initialization failed: \(error.localizedDescription)")
            throw error
        }
    }

    func getCurrentConfiguration() -> ComposablePrimerConfiguration? {
        logger.debug(message: "🔍 [ConfigurationRepository] Getting current configuration")

        if currentConfiguration != nil {
            logger.debug(message: "✅ [ConfigurationRepository] Current configuration found")
        } else {
            logger.debug(message: "⚠️ [ConfigurationRepository] No current configuration available")
        }

        return currentConfiguration
    }
}

// MARK: - Configuration Errors

@available(iOS 15.0, *)
internal enum ConfigurationError: Error, LocalizedError {
    case initializationFailed
    case missingConfiguration
    case invalidClientToken
    case networkError

    var errorDescription: String? {
        switch self {
        case .initializationFailed:
            return "Failed to initialize configuration"
        case .missingConfiguration:
            return "Configuration is not available"
        case .invalidClientToken:
            return "Invalid client token provided"
        case .networkError:
            return "Network error during configuration initialization"
        }
    }
}
