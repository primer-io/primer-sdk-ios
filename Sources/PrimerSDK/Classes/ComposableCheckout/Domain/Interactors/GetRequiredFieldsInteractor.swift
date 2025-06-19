//
//  GetRequiredFieldsInteractor.swift
//
//
//  Created on 19.06.2025.
//

import Foundation

/// Interactor that determines which fields are required for the current payment method
/// This matches Android's GetRequiredFieldsInteractor for dynamic field visibility
@available(iOS 15.0, *)
internal class GetRequiredFieldsInteractor: LogReporter {

    // MARK: - Dependencies

    private let configurationRepository: ConfigurationRepository

    // MARK: - Initialization

    internal init(configurationRepository: ConfigurationRepository) {
        self.configurationRepository = configurationRepository
        logger.debug(message: "📋 [GetRequiredFieldsInteractor] Initialized")
    }

    // MARK: - Public Methods

    /// Get required card fields based on payment method configuration
    public func getCardFields() async -> [ComposableInputElementType] {
        logger.debug(message: "💳 [GetRequiredFieldsInteractor] Getting required card fields")

        // Get configuration from repository
        let configuration = configurationRepository.getCurrentConfiguration()

        // For now, return standard card fields
        // In production, this would be determined by backend configuration
        var fields: [ComposableInputElementType] = [.cardNumber]

        // Add fields based on configuration
        if configuration?.requiresCVV ?? true {
            fields.append(.cvv)
        }

        if configuration?.requiresExpiryDate ?? true {
            fields.append(.expiryDate)
        }

        if configuration?.requiresCardholderName ?? false {
            fields.append(.cardholderName)
        }

        logger.debug(message: "💳 [GetRequiredFieldsInteractor] Required card fields: \(fields)")
        return fields
    }

    /// Get required billing fields based on payment method configuration
    public func getBillingFields() async -> [ComposableInputElementType] {
        logger.debug(message: "🏠 [GetRequiredFieldsInteractor] Getting required billing fields")

        // Get configuration from repository
        let configuration = configurationRepository.getCurrentConfiguration()

        var fields: [ComposableInputElementType] = []

        // Add fields based on configuration
        if configuration?.requiresPostalCode ?? false {
            fields.append(.postalCode)
        }

        if configuration?.requiresCountryCode ?? false {
            fields.append(.countryCode)
        }

        if configuration?.requiresCity ?? false {
            fields.append(.city)
        }

        if configuration?.requiresState ?? false {
            fields.append(.state)
        }

        if configuration?.requiresAddressLine1 ?? false {
            fields.append(.addressLine1)
        }

        if configuration?.requiresAddressLine2 ?? false {
            fields.append(.addressLine2)
        }

        if configuration?.requiresFirstName ?? false {
            fields.append(.firstName)
        }

        if configuration?.requiresLastName ?? false {
            fields.append(.lastName)
        }

        logger.debug(message: "🏠 [GetRequiredFieldsInteractor] Required billing fields: \(fields)")
        return fields
    }

    /// Get all required fields (card + billing)
    public func getAllRequiredFields() async -> [ComposableInputElementType] {
        let cardFields = await getCardFields()
        let billingFields = await getBillingFields()
        return cardFields + billingFields
    }
}

// MARK: - Configuration Model Extension

// Temporary extension for configuration - in production this would come from backend
@available(iOS 15.0, *)
private extension ComposablePrimerConfiguration {
    var requiresCVV: Bool { true }
    var requiresExpiryDate: Bool { true }
    var requiresCardholderName: Bool { false }
    var requiresPostalCode: Bool { false }
    var requiresCountryCode: Bool { false }
    var requiresCity: Bool { false }
    var requiresState: Bool { false }
    var requiresAddressLine1: Bool { false }
    var requiresAddressLine2: Bool { false }
    var requiresFirstName: Bool { false }
    var requiresLastName: Bool { false }
}
