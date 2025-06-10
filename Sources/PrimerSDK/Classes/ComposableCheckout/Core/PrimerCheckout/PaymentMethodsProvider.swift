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
        logger.debug(message: "🔍 Retrieving all available payment methods")

        // Use resolveAll to get all registered payment method implementations
        let paymentMethods = await container.resolveAll((any PaymentMethodProtocol).self)

        logger.debug(message: "✅ Found \(paymentMethods.count) payment methods")
        return paymentMethods
    }

    func getPaymentMethod(named: String) async throws -> (any PaymentMethodProtocol)? {
        logger.debug(message: "🔍 Retrieving payment method: \(named)")

        do {
            let paymentMethod = try await container.resolve((any PaymentMethodProtocol).self, name: named)
            logger.debug(message: "✅ Retrieved payment method: \(named)")
            return paymentMethod
        } catch {
            logger.error(message: "❌ Failed to retrieve payment method '\(named)': \(error.localizedDescription)")
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
