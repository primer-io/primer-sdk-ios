//
//  CheckoutComponentsPaymentMethodsBridge.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import Foundation

/// Bridge to connect CheckoutComponents to the existing SDK payment methods
internal class CheckoutComponentsPaymentMethodsBridge: GetPaymentMethodsInteractor, LogReporter {

    func execute() async throws -> [InternalPaymentMethod] {
        logger.info(message: "🌉 [PaymentMethodsBridge] Starting payment methods bridge...")

        // Get the current configuration from PrimerAPIConfiguration
        guard let configuration = PrimerAPIConfiguration.current else {
            logger.error(message: "❌ [PaymentMethodsBridge] No configuration available")
            throw PrimerError.unknown(
                userInfo: ["error": "No configuration available"],
                diagnosticsId: UUID().uuidString
            )
        }

        logger.info(message: "✅ [PaymentMethodsBridge] Configuration found")

        guard let paymentMethods = configuration.paymentMethods, !paymentMethods.isEmpty else {
            logger.error(message: "❌ [PaymentMethodsBridge] No payment methods in configuration")
            throw PrimerError.unknown(
                userInfo: ["error": "No payment methods in configuration"],
                diagnosticsId: UUID().uuidString
            )
        }

        logger.info(message: "📊 [PaymentMethodsBridge] Found \(paymentMethods.count) payment methods in configuration")

        // Convert PrimerPaymentMethod to InternalPaymentMethod
        let convertedMethods = paymentMethods.map { primerMethod -> InternalPaymentMethod in
            let type = primerMethod.type

            logger.debug(message: "🔄 [PaymentMethodsBridge] Converting payment method: \(type)")

            return InternalPaymentMethod(
                id: primerMethod.id ?? UUID().uuidString,
                type: type,
                name: primerMethod.name,
                isEnabled: true // Assume enabled if in configuration
            )
        }

        logger.info(message: "✅ [PaymentMethodsBridge] Successfully converted \(convertedMethods.count) payment methods")

        // Log each converted method
        for (index, method) in convertedMethods.enumerated() {
            logger.debug(message: "💳 [PaymentMethodsBridge] Method \(index + 1): \(method.type) - \(method.name)")
        }

        return convertedMethods
    }
}
