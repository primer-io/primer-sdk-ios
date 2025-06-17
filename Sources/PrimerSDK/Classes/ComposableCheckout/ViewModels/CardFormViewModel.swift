//
//  CardFormViewModel.swift
//  
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// CardFormViewModel implements the CardFormScope protocol and manages card input form state.
/// This provides all card form functionality accessible through the Android-matching API.
@available(iOS 15.0, *)
@MainActor
public class CardFormViewModel: CardFormScope, LogReporter {
    
    // MARK: - Published State
    
    @Published private var _state: CardFormState = .initial
    
    // MARK: - CardFormScope Implementation
    
    public var state: AnyPublisher<CardFormState, Never> {
        $_state.eraseToAnyPublisher()
    }
    
    // MARK: - Dependencies
    
    private let container: DIContainer
    private let validationService: ValidationService
    
    // MARK: - Initialization
    
    public init(container: DIContainer, validationService: ValidationService) async throws {
        self.container = container
        self.validationService = validationService
        logger.debug(message: "💳 [CardFormViewModel] Initializing card form")
        await setupInitialState()
    }
    
    // MARK: - Update Methods (match Android exactly)
    
    public func updateCardNumber(_ cardNumber: String) {
        logger.debug(message: "🔢 [CardFormViewModel] Updating card number")
        updateField(.cardNumber, value: cardNumber)
        validateField(.cardNumber, value: cardNumber)
    }
    
    public func updateCvv(_ cvv: String) {
        logger.debug(message: "🔒 [CardFormViewModel] Updating CVV")
        updateField(.cvv, value: cvv)
        validateField(.cvv, value: cvv)
    }
    
    public func updateExpiryDate(_ expiryDate: String) {
        logger.debug(message: "📅 [CardFormViewModel] Updating expiry date")
        updateField(.expiryDate, value: expiryDate)
        validateField(.expiryDate, value: expiryDate)
    }
    
    public func updateCardholderName(_ cardholderName: String) {
        logger.debug(message: "👤 [CardFormViewModel] Updating cardholder name")
        updateField(.cardholderName, value: cardholderName)
        validateField(.cardholderName, value: cardholderName)
    }
    
    public func updatePostalCode(_ postalCode: String) {
        updateField(.postalCode, value: postalCode)
        validateField(.postalCode, value: postalCode)
    }
    
    public func updateCountryCode(_ countryCode: String) {
        updateField(.countryCode, value: countryCode)
        validateField(.countryCode, value: countryCode)
    }
    
    public func updateCity(_ city: String) {
        updateField(.city, value: city)
        validateField(.city, value: city)
    }
    
    public func updateState(_ state: String) {
        updateField(.state, value: state)
        validateField(.state, value: state)
    }
    
    public func updateAddressLine1(_ addressLine1: String) {
        updateField(.addressLine1, value: addressLine1)
        validateField(.addressLine1, value: addressLine1)
    }
    
    public func updateAddressLine2(_ addressLine2: String) {
        updateField(.addressLine2, value: addressLine2)
        validateField(.addressLine2, value: addressLine2)
    }
    
    public func updatePhoneNumber(_ phoneNumber: String) {
        updateField(.phoneNumber, value: phoneNumber)
        validateField(.phoneNumber, value: phoneNumber)
    }
    
    public func updateFirstName(_ firstName: String) {
        updateField(.firstName, value: firstName)
        validateField(.firstName, value: firstName)
    }
    
    public func updateLastName(_ lastName: String) {
        updateField(.lastName, value: lastName)
        validateField(.lastName, value: lastName)
    }
    
    public func updateRetailOutlet(_ retailOutlet: String) {
        updateField(.retailOutlet, value: retailOutlet)
        validateField(.retailOutlet, value: retailOutlet)
    }
    
    public func updateOtpCode(_ otpCode: String) {
        updateField(.otpCode, value: otpCode)
        validateField(.otpCode, value: otpCode)
    }
    
    public func submit() {
        logger.debug(message: "🚀 [CardFormViewModel] Submitting card form")
        
        // Start submission state
        updateState(isLoading: true, isSubmitEnabled: false)
        
        Task {
            do {
                // TODO: Implement actual payment submission through services
                // For now, simulate submission
                try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
                
                logger.info(message: "✅ [CardFormViewModel] Card form submitted successfully")
                
                // Reset form after successful submission
                await resetForm()
                
            } catch {
                logger.error(message: "❌ [CardFormViewModel] Submission failed: \(error)")
                updateState(isLoading: false, isSubmitEnabled: true)
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func setupInitialState() async {
        logger.debug(message: "⚙️ [CardFormViewModel] Setting up initial state")
        
        let cardFields: [PrimerInputElementType] = [.cardNumber, .cvv, .expiryDate, .cardholderName]
        let billingFields: [PrimerInputElementType] = [.postalCode, .countryCode, .city, .state, .addressLine1, .addressLine2]
        
        _state = CardFormState(
            cardFields: cardFields,
            billingFields: billingFields,
            fieldErrors: [],
            inputFields: [:],
            isLoading: false,
            isSubmitEnabled: false
        )
    }
    
    private func updateField(_ elementType: PrimerInputElementType, value: String) {
        var updatedFields = _state.inputFields
        updatedFields[elementType] = value
        
        _state = CardFormState(
            cardFields: _state.cardFields,
            billingFields: _state.billingFields,
            fieldErrors: _state.fieldErrors,
            inputFields: updatedFields,
            isLoading: _state.isLoading,
            isSubmitEnabled: calculateSubmitEnabled(updatedFields)
        )
    }
    
    private func validateField(_ elementType: PrimerInputElementType, value: String) {
        // TODO: Integrate with existing ValidationService
        // For now, we'll just log validation
        logger.debug(message: "🔍 [CardFormViewModel] Validating field: \(elementType)")
    }
    
    private func updateState(isLoading: Bool? = nil, isSubmitEnabled: Bool? = nil) {
        _state = CardFormState(
            cardFields: _state.cardFields,
            billingFields: _state.billingFields,
            fieldErrors: _state.fieldErrors,
            inputFields: _state.inputFields,
            isLoading: isLoading ?? _state.isLoading,
            isSubmitEnabled: isSubmitEnabled ?? _state.isSubmitEnabled
        )
    }
    
    private func calculateSubmitEnabled(_ fields: [PrimerInputElementType: String]) -> Bool {
        let cardNumber = fields[.cardNumber] ?? ""
        let cvv = fields[.cvv] ?? ""
        let expiryDate = fields[.expiryDate] ?? ""
        
        return !cardNumber.isEmpty && 
               !cvv.isEmpty && 
               !expiryDate.isEmpty && 
               !_state.isLoading
    }
    
    private func resetForm() async {
        logger.debug(message: "🔄 [CardFormViewModel] Resetting form")
        await setupInitialState()
    }
}