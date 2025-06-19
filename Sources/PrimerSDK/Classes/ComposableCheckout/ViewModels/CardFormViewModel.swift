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

    // MARK: - Private State

    private var detectedCardNetwork: CardNetwork = .unknown

    // MARK: - CardFormScope Implementation

    public var state: AnyPublisher<CardFormState, Never> {
        $_state.eraseToAnyPublisher()
    }

    // MARK: - Dependencies

    private let container: any ContainerProtocol
    private let validationService: ValidationService
    private let processCardPaymentInteractor: ProcessCardPaymentInteractor
    private let validatePaymentDataInteractor: ValidatePaymentDataInteractor
    private let navigator: CheckoutNavigator

    // MARK: - Initialization

    public init(container: any ContainerProtocol, validationService: ValidationService, navigator: CheckoutNavigator) async throws {
        self.container = container
        self.validationService = validationService
        self.navigator = navigator
        self.processCardPaymentInteractor = try await container.resolve(ProcessCardPaymentInteractor.self, name: nil)
        self.validatePaymentDataInteractor = try await container.resolve(ValidatePaymentDataInteractor.self, name: nil)
        logger.debug(message: "💳 [CardFormViewModel] Initializing card form")
        await setupInitialState()
    }

    // MARK: - Update Methods (match Android exactly)

    public func updateCardNumber(_ cardNumber: String) {
        logger.debug(message: "🔢 [CardFormViewModel] Updating card number")

        // Detect card network
        let network = CardNetworkParser.shared.cardNetwork(from: cardNumber) ?? .unknown
        if network != detectedCardNetwork {
            detectedCardNetwork = network
            logger.debug(message: "💳 [CardFormViewModel] Detected card network: \(network)")
        }

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
                // Create card payment data from current state
                let cardData = createCardPaymentData()

                // Process payment using Clean Architecture Interactor
                let result = try await processCardPaymentInteractor.execute(cardData: cardData)

                if result.success {
                    logger.info(message: "✅ [CardFormViewModel] Payment processed successfully")

                    // Reset form after successful submission
                    await resetForm()

                    // Navigate to success screen using navigator
                    await navigator.navigateToSuccess()
                } else {
                    logger.error(message: "❌ [CardFormViewModel] Payment failed: \(result.error?.localizedDescription ?? "Unknown error")")
                    await handleSubmissionError(result.error ?? PaymentProcessingError.unknownError)
                }

            } catch {
                logger.error(message: "❌ [CardFormViewModel] Submission failed: \(error)")
                await handleSubmissionError(error)
            }
        }
    }

    // MARK: - Private Methods

    private func setupInitialState() async {
        logger.debug(message: "⚙️ [CardFormViewModel] Setting up initial state")

        _state = CardFormState(
            inputFields: [:],
            fieldErrors: [],
            isLoading: false,
            isSubmitEnabled: false,
            cardNetwork: nil
        )
    }

    private func updateField(_ elementType: ComposableInputElementType, value: String) {
        var updatedFields = _state.inputFields
        updatedFields[elementType] = value

        _state = CardFormState(
            inputFields: updatedFields,
            fieldErrors: _state.fieldErrors,
            isLoading: _state.isLoading,
            isSubmitEnabled: calculateSubmitEnabled(updatedFields),
            cardNetwork: detectedCardNetwork == .unknown ? nil : detectedCardNetwork
        )
    }

    private func validateField(_ elementType: ComposableInputElementType, value: String) {
        logger.debug(message: "🔍 [CardFormViewModel] Validating field: \(elementType)")

        Task {
            do {
                let isValid = await performFieldValidation(elementType: elementType, value: value)

                await MainActor.run {
                    updateFieldValidation(elementType: elementType, isValid: isValid, value: value)
                }
            } catch {
                logger.error(message: "❌ [CardFormViewModel] Validation failed for \(elementType): \(error)")
            }
        }
    }

    /// Perform actual field validation using ValidationService
    private func performFieldValidation(elementType: ComposableInputElementType, value: String) async -> Bool {
        // Basic validation for now - can be enhanced with ValidationService integration
        switch elementType {
        case .cardNumber:
            return validateCardNumber(value)
        case .cvv:
            return validateCVV(value)
        case .expiryDate:
            return validateExpiryDate(value)
        case .cardholderName:
            return validateCardholderName(value)
        case .postalCode:
            return validatePostalCode(value)
        default:
            return !value.isEmpty
        }
    }

    /// Update field validation state
    private func updateFieldValidation(elementType: ComposableInputElementType, isValid: Bool, value: String) {
        var errors = _state.fieldErrors.filter { $0.elementType != elementType }

        if !isValid && !value.isEmpty {
            let errorMessage = getErrorMessage(for: elementType)
            errors.append(ComposableInputValidationError(elementType: elementType, errorMessage: errorMessage))
        }

        _state = CardFormState(
            inputFields: _state.inputFields,
            fieldErrors: errors,
            isLoading: _state.isLoading,
            isSubmitEnabled: calculateSubmitEnabled(_state.inputFields, errors: errors),
            cardNetwork: detectedCardNetwork == .unknown ? nil : detectedCardNetwork
        )
    }

    /// Get appropriate error message for field type
    private func getErrorMessage(for elementType: ComposableInputElementType) -> String {
        switch elementType {
        case .cardNumber:
            return "Please enter a valid card number"
        case .cvv:
            return "Please enter a valid CVV"
        case .expiryDate:
            return "Please enter a valid expiry date"
        case .cardholderName:
            return "Please enter the cardholder name"
        case .postalCode:
            return "Please enter a valid postal code"
        default:
            return "Please enter a valid value"
        }
    }

    private func updateState(isLoading: Bool? = nil, isSubmitEnabled: Bool? = nil) {
        _state = CardFormState(
            inputFields: _state.inputFields,
            fieldErrors: _state.fieldErrors,
            isLoading: isLoading ?? _state.isLoading,
            isSubmitEnabled: isSubmitEnabled ?? _state.isSubmitEnabled,
            cardNetwork: detectedCardNetwork == .unknown ? nil : detectedCardNetwork
        )
    }

    private func calculateSubmitEnabled(_ fields: [ComposableInputElementType: String], errors: [ComposableInputValidationError]? = nil) -> Bool {
        let cardNumber = fields[.cardNumber] ?? ""
        let cvv = fields[.cvv] ?? ""
        let expiryDate = fields[.expiryDate] ?? ""

        let hasRequiredFields = !cardNumber.isEmpty && !cvv.isEmpty && !expiryDate.isEmpty
        let hasNoErrors = (errors ?? _state.fieldErrors).isEmpty

        return hasRequiredFields && hasNoErrors && !_state.isLoading
    }

    // MARK: - Basic Validation Methods

    private func validateCardNumber(_ value: String) -> Bool {
        let cleanedValue = value.replacingOccurrences(of: " ", with: "")
        return cleanedValue.count >= 13 && cleanedValue.count <= 19 && cleanedValue.allSatisfy(\.isNumber)
    }

    private func validateCVV(_ value: String) -> Bool {
        return value.count >= 3 && value.count <= 4 && value.allSatisfy(\.isNumber)
    }

    private func validateExpiryDate(_ value: String) -> Bool {
        let components = value.split(separator: "/")
        guard components.count == 2,
              let month = Int(components[0]),
              let year = Int(components[1]) else {
            return false
        }

        return month >= 1 && month <= 12 && year >= 0
    }

    private func validateCardholderName(_ value: String) -> Bool {
        return value.count >= 2 && value.allSatisfy { $0.isLetter || $0.isWhitespace }
    }

    // MARK: - Clean Architecture Helper Methods

    /// Create CardPaymentData from current form state
    private func createCardPaymentData() -> CardPaymentData {
        logger.debug(message: "📋 [CardFormViewModel] Creating card payment data from form state")

        return CardPaymentData(
            cardNumber: _state.inputFields[.cardNumber] ?? "",
            cvv: _state.inputFields[.cvv] ?? "",
            expiryDate: _state.inputFields[.expiryDate] ?? "",
            cardholderName: _state.inputFields[.cardholderName],
            postalCode: _state.inputFields[.postalCode],
            countryCode: _state.inputFields[.countryCode],
            city: _state.inputFields[.city],
            state: _state.inputFields[.state],
            addressLine1: _state.inputFields[.addressLine1],
            addressLine2: _state.inputFields[.addressLine2],
            phoneNumber: _state.inputFields[.phoneNumber],
            firstName: _state.inputFields[.firstName],
            lastName: _state.inputFields[.lastName]
        )
    }

    /// Handle submission errors by updating the UI state
    @MainActor
    private func handleSubmissionError(_ error: Error) async {
        logger.error(message: "❌ [CardFormViewModel] Handling submission error: \(error.localizedDescription)")

        // Create error for UI display
        let validationError = ComposableInputValidationError(
            elementType: .cardNumber, // Show on card number field for now
            errorMessage: error.localizedDescription
        )

        // Update state with error
        _state = CardFormState(
            inputFields: _state.inputFields,
            fieldErrors: [validationError],
            isLoading: false,
            isSubmitEnabled: false,
            cardNetwork: detectedCardNetwork == .unknown ? nil : detectedCardNetwork
        )

        // Navigate to error screen using navigator
        await navigator.navigateToError(error.localizedDescription)
    }

    private func validatePostalCode(_ value: String) -> Bool {
        return value.count >= 3 && value.count <= 10
    }

    private func resetForm() async {
        logger.debug(message: "🔄 [CardFormViewModel] Resetting form")
        await setupInitialState()
    }
}
