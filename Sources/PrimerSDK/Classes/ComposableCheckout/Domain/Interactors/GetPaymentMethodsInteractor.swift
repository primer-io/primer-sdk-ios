//
//  GetPaymentMethodsInteractor.swift
//
//
//  Created on 17.06.2025.
//

import Foundation

/// Interactor (Use Case) for retrieving available payment methods
@available(iOS 15.0, *)
internal protocol GetPaymentMethodsInteractor: LogReporter {
    /// Executes the retrieval of available payment methods
    /// - Returns: Array of available payment methods
    /// - Throws: Error if retrieval fails
    func execute() async throws -> [PrimerComposablePaymentMethod]

    /// Executes the retrieval of currency information
    /// - Returns: ComposableCurrency information if available
    /// - Throws: Error if retrieval fails
    func getCurrency() async throws -> ComposableCurrency?
}

/// Implementation of GetPaymentMethodsInteractor
@available(iOS 15.0, *)
internal class GetPaymentMethodsInteractorImpl: GetPaymentMethodsInteractor, LogReporter {

    // MARK: - Dependencies

    private let paymentMethodRepository: PaymentMethodRepository

    // MARK: - Initialization

    init(paymentMethodRepository: PaymentMethodRepository) {
        self.paymentMethodRepository = paymentMethodRepository
        logger.debug(message: "🏗️ [GetPaymentMethodsInteractor] Initialized")
    }

    // MARK: - GetPaymentMethodsInteractor

    func execute() async throws -> [PrimerComposablePaymentMethod] {
        logger.debug(message: "🔍 [GetPaymentMethodsInteractor] Starting payment methods retrieval")

        do {
            let paymentMethods = try await paymentMethodRepository.getAvailablePaymentMethods()

            logger.info(message: "✅ [GetPaymentMethodsInteractor] Retrieved \(paymentMethods.count) payment methods")

            // Log payment method types for debugging
            let methodTypes = paymentMethods.map { $0.paymentMethodType }
            logger.debug(message: "📋 [GetPaymentMethodsInteractor] Payment method types: \(methodTypes)")

            return paymentMethods

        } catch {
            logger.error(message: "❌ [GetPaymentMethodsInteractor] Failed to retrieve payment methods: \(error.localizedDescription)")
            throw error
        }
    }

    func getCurrency() async throws -> ComposableCurrency? {
        logger.debug(message: "💰 [GetPaymentMethodsInteractor] Starting currency retrieval")

        do {
            let currency = try await paymentMethodRepository.getCurrency()

            if let currency = currency {
                logger.info(message: "✅ [GetPaymentMethodsInteractor] Retrieved currency: \(currency.code)")
            } else {
                logger.info(message: "ℹ️ [GetPaymentMethodsInteractor] No currency information available")
            }

            return currency

        } catch {
            logger.error(message: "❌ [GetPaymentMethodsInteractor] Failed to retrieve currency: \(error.localizedDescription)")
            throw error
        }
    }
}

/// Validation interactor for payment method validation
@available(iOS 15.0, *)
internal protocol ValidatePaymentDataInteractor: LogReporter {
    /// Validates card payment data
    /// - Parameter cardData: The card data to validate
    /// - Returns: Array of validation errors (empty if valid)
    func validateCardData(_ cardData: CardPaymentData) async -> [ComposableInputValidationError]

    /// Validates a specific field value
    /// - Parameters:
    ///   - elementType: The type of field being validated
    ///   - value: The value to validate
    /// - Returns: Array of validation errors (empty if valid)
    func validateField(elementType: ComposableInputElementType, value: String) async -> [ComposableInputValidationError]
}

/// Implementation of ValidatePaymentDataInteractor that uses existing validation system
@available(iOS 15.0, *)
internal class ValidatePaymentDataInteractorImpl: ValidatePaymentDataInteractor, LogReporter {

    // MARK: - Dependencies

    // Use existing validation system - don't change it
    private let validationService: ValidationService

    // MARK: - Initialization

    init(validationService: ValidationService) {
        self.validationService = validationService
        logger.debug(message: "🏗️ [ValidatePaymentDataInteractor] Initialized")
    }

    // MARK: - ValidatePaymentDataInteractor

    func validateCardData(_ cardData: CardPaymentData) async -> [ComposableInputValidationError] {
        logger.debug(message: "🔍 [ValidatePaymentDataInteractor] Validating card data")

        // Convert CardPaymentData to the format expected by ValidationService
        let inputFields: [ComposableInputElementType: String] = [
            .cardNumber: cardData.cardNumber,
            .cvv: cardData.cvv,
            .expiryDate: cardData.expiryDate,
            .cardholderName: cardData.cardholderName ?? "",
            .postalCode: cardData.postalCode ?? "",
            .countryCode: cardData.countryCode ?? "",
            .city: cardData.city ?? "",
            .state: cardData.state ?? "",
            .addressLine1: cardData.addressLine1 ?? "",
            .addressLine2: cardData.addressLine2 ?? "",
            .phoneNumber: cardData.phoneNumber ?? "",
            .firstName: cardData.firstName ?? "",
            .lastName: cardData.lastName ?? ""
        ]

        // Validate each field individually using the validation service
        var validationErrors: [ComposableInputValidationError] = []

        for (composableType, value) in inputFields {
            let result = validationService.validateField(type: composableType, value: value)

            if !result.isValid {
                validationErrors.append(ComposableInputValidationError(
                    elementType: composableType,
                    errorMessage: result.errorMessage ?? "Invalid input"
                ))
            }
        }

        logger.debug(message: "📊 [ValidatePaymentDataInteractor] Validation found \(validationErrors.count) errors")

        return validationErrors
    }

    func validateField(elementType: ComposableInputElementType, value: String) async -> [ComposableInputValidationError] {
        logger.debug(message: "🔍 [ValidatePaymentDataInteractor] Validating field: \(elementType)")

        // Use validation service directly with ComposableInputElementType
        let validationResult = validationService.validateField(type: elementType, value: value)

        // Convert ValidationResult back to our ComposableInputValidationError format
        let errors = convertValidationResultToErrors(result: validationResult, elementType: elementType)

        logger.debug(message: "📊 [ValidatePaymentDataInteractor] Field validation found \(errors.count) errors")

        return errors
    }

    // MARK: - Private Type Conversion Methods

    /// Converts ComposableInputElementType to legacy PrimerInputElementType
    private func convertToLegacyElementType(_ composableType: ComposableInputElementType) -> PrimerInputElementType {
        switch composableType {
        case .cardNumber:
            return .cardNumber
        case .cvv:
            return .cvv
        case .expiryDate:
            return .expiryDate
        case .cardholderName:
            return .cardholderName
        case .postalCode:
            return .postalCode
        case .countryCode:
            return .countryCode
        case .city:
            return .city
        case .state:
            return .state
        case .addressLine1:
            return .addressLine1
        case .addressLine2:
            return .addressLine2
        case .phoneNumber:
            return .phoneNumber
        case .firstName:
            return .firstName
        case .lastName:
            return .lastName
        case .retailOutlet:
            return .retailer
        case .otpCode:
            return .otp
        // Direct mappings for cases that match exactly
        case .otp:
            return .otp
        case .retailer:
            return .retailer
        case .unknown:
            return .unknown
        case .all:
            return .all
        }
    }

    /// Converts ValidationResult to array of ComposableInputValidationError
    private func convertValidationResultToErrors(result: ValidationResult, elementType: ComposableInputElementType) -> [ComposableInputValidationError] {
        if result.isValid {
            return []
        } else {
            return [ComposableInputValidationError(
                elementType: elementType,
                errorMessage: result.errorMessage ?? "Validation failed"
            )]
        }
    }

    /// Converts legacy validation results to ComposableInputValidationError array
    private func convertLegacyValidationResults(_ legacyResults: [PrimerInputElementType: ValidationResult]) -> [ComposableInputValidationError] {
        var errors: [ComposableInputValidationError] = []

        for (legacyType, result) in legacyResults {
            if !result.isValid {
                // Convert back to ComposableInputElementType
                if let composableType = convertFromLegacyElementType(legacyType) {
                    errors.append(ComposableInputValidationError(
                        elementType: composableType,
                        errorMessage: result.errorMessage ?? "Validation error"
                    ))
                }
            }
        }

        return errors
    }

    /// Converts legacy PrimerInputElementType to ComposableInputElementType
    private func convertFromLegacyElementType(_ legacyType: PrimerInputElementType) -> ComposableInputElementType? {
        switch legacyType {
        case .cardNumber:
            return .cardNumber
        case .cvv:
            return .cvv
        case .expiryDate:
            return .expiryDate
        case .cardholderName:
            return .cardholderName
        case .postalCode:
            return .postalCode
        case .countryCode:
            return .countryCode
        case .city:
            return .city
        case .state:
            return .state
        case .addressLine1:
            return .addressLine1
        case .addressLine2:
            return .addressLine2
        case .phoneNumber:
            return .phoneNumber
        case .firstName:
            return .firstName
        case .lastName:
            return .lastName
        case .retailer:
            return .retailer // Use direct mapping now
        case .otp:
            return .otp // Use direct mapping now
        case .unknown:
            return .unknown // Now available in ComposableInputElementType
        case .all:
            return .all // Now available in ComposableInputElementType
        }
    }
}
