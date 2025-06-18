//
//  PaymentMethodRepository.swift
//
//
//  Created on 17.06.2025.
//

import Foundation

/// Repository interface for payment method data management
@available(iOS 15.0, *)
internal protocol PaymentMethodRepository: LogReporter {
    /// Gets available payment methods
    /// - Returns: Array of PrimerComposablePaymentMethod
    /// - Throws: Error if retrieval fails
    func getAvailablePaymentMethods() async throws -> [PrimerComposablePaymentMethod]

    /// Gets currency information
    /// - Returns: ComposableCurrency object if available
    /// - Throws: Error if retrieval fails
    func getCurrency() async throws -> ComposableCurrency?
}

/// Implementation of PaymentMethodRepository
@available(iOS 15.0, *)
internal class PaymentMethodRepositoryImpl: PaymentMethodRepository, LogReporter {

    // MARK: - Dependencies

    private let paymentMethodService: PaymentMethodService

    // MARK: - Initialization

    init(paymentMethodService: PaymentMethodService) {
        self.paymentMethodService = paymentMethodService
        logger.debug(message: "🏗️ [PaymentMethodRepository] Initialized")
    }

    // MARK: - PaymentMethodRepository

    func getAvailablePaymentMethods() async throws -> [PrimerComposablePaymentMethod] {
        logger.debug(message: "🔍 [PaymentMethodRepository] Fetching available payment methods")

        do {
            let sdkPaymentMethods = try await paymentMethodService.getAvailablePaymentMethods()
            let composablePaymentMethods = convertToComposablePaymentMethods(sdkPaymentMethods)

            logger.info(message: "✅ [PaymentMethodRepository] Successfully converted \(composablePaymentMethods.count) payment methods")

            return composablePaymentMethods

        } catch {
            logger.error(message: "❌ [PaymentMethodRepository] Failed to fetch payment methods: \(error.localizedDescription)")
            throw error
        }
    }

    func getCurrency() async throws -> ComposableCurrency? {
        logger.debug(message: "💰 [PaymentMethodRepository] Fetching currency information")

        do {
            let currency = try await paymentMethodService.getCurrency()

            if let currency = currency {
                logger.info(message: "✅ [PaymentMethodRepository] Currency retrieved: \(currency.code)")
            } else {
                logger.info(message: "ℹ️ [PaymentMethodRepository] No currency information available")
            }

            return currency

        } catch {
            logger.error(message: "❌ [PaymentMethodRepository] Failed to fetch currency: \(error.localizedDescription)")
            throw error
        }
    }

    // MARK: - Private Methods

    private func convertToComposablePaymentMethods(_ sdkMethods: [Any]) -> [PrimerComposablePaymentMethod] {
        logger.debug(message: "🔄 [PaymentMethodRepository] Converting \(sdkMethods.count) SDK payment methods")

        var composableMethods: [PrimerComposablePaymentMethod] = []

        for sdkMethod in sdkMethods {
            if let composableMethod = convertSinglePaymentMethod(sdkMethod) {
                composableMethods.append(composableMethod)
            }
        }

        logger.debug(message: "✅ [PaymentMethodRepository] Successfully converted \(composableMethods.count) payment methods")

        return composableMethods
    }

    private func convertSinglePaymentMethod(_ sdkMethod: Any) -> PrimerComposablePaymentMethod? {
        // This is where we integrate with existing SDK payment method models
        // For now, we'll create a basic implementation that can be enhanced
        // when we have access to the actual SDK payment method models

        // TODO: Replace with actual SDK model conversion
        // This is a placeholder implementation

        // If the SDK method has a type property, use it
        if let method = sdkMethod as? AnyObject,
           let type = method.value(forKey: "type") as? String {

            let name = method.value(forKey: "name") as? String ?? type
            let description = method.value(forKey: "paymentDescription") as? String

            logger.debug(message: "🔄 [PaymentMethodRepository] Converting method: \(type)")

            return PrimerComposablePaymentMethod(
                paymentMethodType: type,
                paymentMethodName: name,
                description: description,
                surcharge: nil // TODO: Handle surcharge conversion
            )
        }

        // Fallback for unknown method types
        logger.warn(message: "⚠️ [PaymentMethodRepository] Unknown payment method type, creating default")

        return PrimerComposablePaymentMethod(
            paymentMethodType: "UNKNOWN",
            paymentMethodName: "Unknown Payment Method",
            description: "Payment method type not recognized",
            surcharge: nil
        )
    }
}

// MARK: - Payment Method Repository Errors

@available(iOS 15.0, *)
internal enum PaymentMethodRepositoryError: Error, LocalizedError {
    case fetchFailed
    case conversionFailed
    case noPaymentMethodsAvailable
    case currencyNotAvailable

    var errorDescription: String? {
        switch self {
        case .fetchFailed:
            return "Failed to fetch payment methods"
        case .conversionFailed:
            return "Failed to convert payment method data"
        case .noPaymentMethodsAvailable:
            return "No payment methods are available"
        case .currencyNotAvailable:
            return "Currency information is not available"
        }
    }
}
