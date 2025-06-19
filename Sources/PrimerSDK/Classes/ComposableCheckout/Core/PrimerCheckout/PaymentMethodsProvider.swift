//
//  PaymentMethodsProvider.swift
//
//
//  Created by Boris on 25.3.25..
//

import Foundation

/**
 * Service that provides available payment methods through dependency injection.
 * This centralizes payment method discovery and management.
 */
@available(iOS 15.0, *)
protocol PaymentMethodsProvider {
    /// Get all available payment methods
    func getAvailablePaymentMethods() async -> [any PaymentMethodProtocol]

    /// Get a specific payment method by name
    func getPaymentMethod(named: String) async throws -> (any PaymentMethodProtocol)?

    /// Check if a payment method is available
    func isPaymentMethodAvailable(named: String) async -> Bool
}

@available(iOS 15.0, *)
final class DefaultPaymentMethodsProvider: PaymentMethodsProvider, LogReporter, @unchecked Sendable {
    private let container: any ContainerProtocol

    init(container: any ContainerProtocol) {
        self.container = container
    }

    func getAvailablePaymentMethods() async -> [any PaymentMethodProtocol] {
        logger.info(message: "🔍 [PaymentMethodsProvider] Starting to retrieve all available payment methods")
        logger.debug(message: "🔧 [PaymentMethodsProvider] Container available: \(container)")

        // Use resolveAll to get all registered payment method implementations
        logger.debug(message: "🔄 [PaymentMethodsProvider] Calling container.resolveAll for PaymentMethodProtocol")
        let allPaymentMethods = await container.resolveAll((any PaymentMethodProtocol).self)

        logger.info(message: "📦 [PaymentMethodsProvider] Found \(allPaymentMethods.count) registered payment methods")

        // Filter based on legacy configuration
        let bridge = LegacyConfigurationBridge()
        let configuredMethods = bridge.getAvailablePaymentMethods()
        let configuredTypes = Set(configuredMethods.map { $0.type })

        logger.debug(message: "⚙️ [PaymentMethodsProvider] Configuration has \(configuredMethods.count) methods: \(configuredTypes)")

        // Filter registered payment methods to only include those configured in the backend
        let availablePaymentMethods = allPaymentMethods.filter { method in
            let isAvailable = configuredTypes.contains(method.type.rawValue) || method.type.rawValue == "PAYMENT_CARD"
            if isAvailable {
                logger.debug(message: "✅ [PaymentMethodsProvider] Including method: \(method.name ?? "Unknown") (\(method.type.rawValue))")
            } else {
                logger.debug(message: "⏭️ [PaymentMethodsProvider] Skipping method: \(method.name ?? "Unknown") (\(method.type.rawValue)) - not in configuration")
            }
            return isAvailable
        }

        logger.info(message: "✅ [PaymentMethodsProvider] Filtered to \(availablePaymentMethods.count) available payment methods")

        if availablePaymentMethods.isEmpty {
            logger.warn(message: "⚠️ [PaymentMethodsProvider] No payment methods available after filtering! Check configuration.")
        }

        return availablePaymentMethods
    }

    func getPaymentMethod(named: String) async throws -> (any PaymentMethodProtocol)? {
        logger.info(message: "🔍 [PaymentMethodsProvider] Retrieving specific payment method: \(named)")

        do {
            logger.debug(message: "🔄 [PaymentMethodsProvider] Calling container.resolve for named payment method: \(named)")
            let paymentMethod = try await container.resolve((any PaymentMethodProtocol).self, name: named)
            logger.info(message: "✅ [PaymentMethodsProvider] Successfully retrieved payment method: \(named)")
            return paymentMethod
        } catch {
            logger.error(message: "❌ [PaymentMethodsProvider] Failed to retrieve payment method '\(named)': \(error.localizedDescription)")
            throw error
        }
    }

    func isPaymentMethodAvailable(named: String) async -> Bool {
        do {
            _ = try await getPaymentMethod(named: named)
            return true
        } catch {
            return false
        }
    }
}
