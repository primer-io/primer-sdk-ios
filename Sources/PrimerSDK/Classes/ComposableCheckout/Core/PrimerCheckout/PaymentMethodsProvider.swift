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
        let paymentMethods = await container.resolveAll((any PaymentMethodProtocol).self)

        logger.info(message: "✅ [PaymentMethodsProvider] Found \(paymentMethods.count) payment methods")

        // Log details about each payment method found
        for (index, method) in paymentMethods.enumerated() {
            logger.debug(message: "📋 [PaymentMethodsProvider] Payment method \(index + 1): \(method.name ?? "Unknown") (ID: \(method.id), Type: \(method.type.rawValue))")
        }

        if paymentMethods.isEmpty {
            logger.warn(message: "⚠️ [PaymentMethodsProvider] No payment methods found! This might indicate a DI registration issue")
        }

        return paymentMethods
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
