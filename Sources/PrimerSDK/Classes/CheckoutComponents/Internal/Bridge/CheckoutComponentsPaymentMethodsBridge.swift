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

        // Filter payment methods based on CheckoutComponents support (only show implemented payment methods)
        let filteredMethods = filterPaymentMethodsBySupport(paymentMethods)
        logger.info(message: "🔍 [PaymentMethodsBridge] Filtered to \(filteredMethods.count) payment methods based on CheckoutComponents support")

        // Convert filtered PrimerPaymentMethod to InternalPaymentMethod with surcharge data
        let convertedMethods = filteredMethods.map { primerMethod -> InternalPaymentMethod in
            let type = primerMethod.type

            logger.debug(message: "🔄 [PaymentMethodsBridge] Converting payment method: \(type)")

            // Extract network surcharges for card payment methods
            let networkSurcharges = extractNetworkSurcharges(for: type)

            // Extract background color from display metadata
            let backgroundColor = primerMethod.displayMetadata?.button.backgroundColor?.uiColor

            // Extract surcharge data for payment method

            return InternalPaymentMethod(
                id: primerMethod.id ?? UUID().uuidString,
                type: type,
                name: primerMethod.name,
                icon: primerMethod.logo,
                configId: primerMethod.processorConfigId,
                isEnabled: true, // Assume enabled if in configuration
                supportedCurrencies: nil, // Could be extracted if available
                requiredInputElements: getRequiredInputElements(for: type),
                metadata: nil, // Could be extracted from displayMetadata
                surcharge: primerMethod.surcharge, // Direct from PrimerPaymentMethod
                hasUnknownSurcharge: primerMethod.hasUnknownSurcharge, // Direct from PrimerPaymentMethod
                networkSurcharges: networkSurcharges, // Extract from client session
                backgroundColor: backgroundColor // Dynamic color from server
            )
        }

        logger.info(message: "✅ [PaymentMethodsBridge] Successfully converted \(convertedMethods.count) payment methods")

        // Log each converted method
        for (index, method) in convertedMethods.enumerated() {
            logger.debug(message: "💳 [PaymentMethodsBridge] Method \(index + 1): \(method.type) - \(method.name)")
        }

        return convertedMethods
    }

    // MARK: - Surcharge Extraction Methods (from HeadlessRepositoryImpl)

    /// Extract network-specific surcharges from client session configuration
    private func extractNetworkSurcharges(for paymentMethodType: String) -> [String: Int]? {
        // Only card payment methods have network-specific surcharges
        guard paymentMethodType == PrimerPaymentMethodType.paymentCard.rawValue else {
            return nil
        }

        // Get client session payment method data
        let session = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
        guard let paymentMethodData = session?.paymentMethod else {
            return nil
        }

        // Check for networks in payment method options
        guard let options = paymentMethodData.options else {
            return nil
        }

        // Find the payment card option
        guard let paymentCardOption = options.first(where: { ($0["type"] as? String) == paymentMethodType }) else {
            return nil
        }

        // Check for networks data - handle both array and dictionary formats
        if let networksArray = paymentCardOption["networks"] as? [[String: Any]] {
            return extractFromNetworksArray(networksArray)
        } else if let networksDict = paymentCardOption["networks"] as? [String: [String: Any]] {
            return extractFromNetworksDict(networksDict)
        } else {
            return nil
        }
    }

    /// Extract surcharges from networks array (traditional format)
    private func extractFromNetworksArray(_ networksArray: [[String: Any]]) -> [String: Int]? {
        var networkSurcharges: [String: Int] = [:]

        for networkData in networksArray {
            guard let networkType = networkData["type"] as? String else {
                continue
            }

            // Handle nested surcharge structure: surcharge.amount
            if let surchargeData = networkData["surcharge"] as? [String: Any],
               let surchargeAmount = surchargeData["amount"] as? Int,
               surchargeAmount > 0 {
                networkSurcharges[networkType] = surchargeAmount
            }
            // Fallback: handle direct surcharge integer format
            else if let surcharge = networkData["surcharge"] as? Int,
                    surcharge > 0 {
                networkSurcharges[networkType] = surcharge
            } else {
            }
        }

        return networkSurcharges.isEmpty ? nil : networkSurcharges
    }

    /// Extract surcharges from networks dictionary
    private func extractFromNetworksDict(_ networksDict: [String: [String: Any]]) -> [String: Int]? {
        var networkSurcharges: [String: Int] = [:]

        for (networkType, networkData) in networksDict {
            // Handle nested surcharge structure: surcharge.amount
            if let surchargeData = networkData["surcharge"] as? [String: Any],
               let surchargeAmount = surchargeData["amount"] as? Int,
               surchargeAmount > 0 {
                networkSurcharges[networkType] = surchargeAmount
            }
            // Fallback: handle direct surcharge integer format
            else if let surcharge = networkData["surcharge"] as? Int,
                    surcharge > 0 {
                networkSurcharges[networkType] = surcharge
            } else {
            }
        }

        return networkSurcharges.isEmpty ? nil : networkSurcharges
    }

    /// Get required input elements for a payment method type
    private func getRequiredInputElements(for paymentMethodType: String) -> [PrimerInputElementType] {
        switch paymentMethodType {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            return [.cardNumber, .cvv, .expiryDate, .cardholderName]
        default:
            return []
        }
    }

    /// Filter payment methods based on CheckoutComponents support (only show implemented payment methods)
    private func filterPaymentMethodsBySupport(_ paymentMethods: [PrimerPaymentMethod]) -> [PrimerPaymentMethod] {
        // For iOS 15+, use PaymentMethodRegistry to get supported payment methods
        if #available(iOS 15.0, *) {
            // Get payment methods that CheckoutComponents can actually handle
            // Note: We need to access this synchronously since we can't make this method async
            // PaymentMethodRegistry.shared.registeredTypes is currently ["PAYMENT_CARD"]
            let supportedPaymentMethods = ["PAYMENT_CARD", "PAYPAL"] // Hardcoded for now since only card is implemented

            logger.debug(message: "🔍 [PaymentMethodsBridge] CheckoutComponents supports: \(supportedPaymentMethods.joined(separator: ", "))")

            // Filter payment methods to only include those CheckoutComponents can handle
            let filteredMethods = paymentMethods.filter { primerMethod in
                let isSupported = supportedPaymentMethods.contains(primerMethod.type)
                if !isSupported {
                    logger.debug(message: "🔍 [PaymentMethodsBridge] Filtering out: \(primerMethod.type) - not implemented in CheckoutComponents")
                } else {
                    logger.debug(message: "🔍 [PaymentMethodsBridge] Including: \(primerMethod.type) - supported by CheckoutComponents")
                }
                return isSupported
            }

            return filteredMethods
        } else {
            // For iOS < 15.0, CheckoutComponents is not available, return all payment methods
            logger.debug(message: "🔍 [PaymentMethodsBridge] iOS < 15.0, CheckoutComponents not available, returning all payment methods")
            return paymentMethods
        }
    }
}
