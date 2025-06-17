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
    /// - Returns: Currency information if available
    /// - Throws: Error if retrieval fails
    func getCurrency() async throws -> Currency?
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
    
    func getCurrency() async throws -> Currency? {
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
    func validateCardData(_ cardData: CardPaymentData) async -> [PrimerInputValidationError]
    
    /// Validates a specific field value
    /// - Parameters:
    ///   - elementType: The type of field being validated
    ///   - value: The value to validate
    /// - Returns: Array of validation errors (empty if valid)
    func validateField(elementType: PrimerInputElementType, value: String) async -> [PrimerInputValidationError]
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
    
    func validateCardData(_ cardData: CardPaymentData) async -> [PrimerInputValidationError] {
        logger.debug(message: "🔍 [ValidatePaymentDataInteractor] Validating card data")
        
        // Convert CardPaymentData to the format expected by ValidationService
        let inputFields: [PrimerInputElementType: String] = [
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
        
        // Use existing validation service
        let errors = validationService.validateAllFields(inputFields)
        
        logger.debug(message: "📊 [ValidatePaymentDataInteractor] Validation found \(errors.count) errors")
        
        return errors
    }
    
    func validateField(elementType: PrimerInputElementType, value: String) async -> [PrimerInputValidationError] {
        logger.debug(message: "🔍 [ValidatePaymentDataInteractor] Validating field: \(elementType)")
        
        // Use existing validation service for single field validation
        let errors = validationService.validateField(elementType: elementType, value: value)
        
        logger.debug(message: "📊 [ValidatePaymentDataInteractor] Field validation found \(errors.count) errors")
        
        return errors
    }
}