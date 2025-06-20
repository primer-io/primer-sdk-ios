//
//  LegacyConfigurationBridge.swift
//  PrimerSDK
//
//  Created to bridge ComposableCheckout with legacy configuration services
//

import Foundation

/// Bridge service that connects ComposableCheckout with legacy PrimerAPIConfigurationModule
@available(iOS 15.0, *)
class LegacyConfigurationBridge: LogReporter {

    // MARK: - Properties
    private let apiConfigModule: PrimerAPIConfigurationModuleProtocol

    // MARK: - Initialization
    init(apiConfigModule: PrimerAPIConfigurationModuleProtocol = PrimerAPIConfigurationModule()) {
        self.apiConfigModule = apiConfigModule
    }

    // MARK: - Public Methods

    /// Setup session using the legacy configuration module
    func setupSession(with clientToken: String) async throws {
        logger.info(message: "🌉 [LegacyConfigurationBridge] Setting up session with client token")

        return try await withCheckedThrowingContinuation { continuation in
            apiConfigModule.setupSession(
                forClientToken: clientToken,
                requestDisplayMetadata: true,
                requestClientTokenValidation: false,
                requestVaultedPaymentMethods: false
            )
            .done {
                self.logger.info(message: "✅ [LegacyConfigurationBridge] Session setup completed")
                continuation.resume()
            }
            .catch { error in
                self.logger.error(message: "❌ [LegacyConfigurationBridge] Session setup failed: \(error)")
                continuation.resume(throwing: error)
            }
        }
    }

    /// Get the current API configuration
    func getConfiguration() -> PrimerAPIConfiguration? {
        return PrimerAPIConfigurationModule.apiConfiguration
    }

    /// Get available payment methods from configuration
    func getAvailablePaymentMethods() -> [PrimerPaymentMethod] {
        guard let config = getConfiguration() else {
            logger.warn(message: "⚠️ [LegacyConfigurationBridge] No configuration available")
            return []
        }

        return config.paymentMethods ?? []
    }

    /// Check if a specific payment method type is available
    func isPaymentMethodAvailable(type: String) -> Bool {
        return getAvailablePaymentMethods().contains { $0.type == type }
    }
}
