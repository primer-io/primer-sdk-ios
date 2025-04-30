//
//  CardViewModel.swift
//
//
//  Created by Boris on 24.3.25..
//

// swiftlint:disable file_length
import Foundation
import SwiftUI

@available(iOS 15.0, *)
@MainActor
class CardViewModel: ObservableObject, CardPaymentMethodScope, LogReporter {
    // MARK: - Properties

    @Published private var uiState: CardPaymentUiState = .empty
    private var stateContinuation: AsyncStream<CardPaymentUiState?>.Continuation?

    // Validation services
    private let validationService: ValidationService
    private let formValidator: FormValidator

    // Field validators using the protocol-based approach
    private lazy var cardNumberValidator = CardNumberFieldValidator(validationService: validationService)
    private lazy var cvvValidator = CVVFieldValidator(validationService: validationService, cardNetwork: .unknown)
    private lazy var expiryDateValidator = ExpiryDateFieldValidator(validationService: validationService)
    private lazy var cardholderNameValidator = CardholderNameFieldValidator(validationService: validationService)

    // MARK: - Initialization

    init(validationService: ValidationService = DefaultValidationService()) {
        self.validationService = validationService
        self.formValidator = CardFormValidator(validationService: validationService)
        logger.debug(message: "📝 CardViewModel initialized with validation system")
    }

    // MARK: - PrimerPaymentMethodScope Implementation

    func state() -> AsyncStream<CardPaymentUiState?> {
        return AsyncStream { continuation in
            self.stateContinuation = continuation
            continuation.yield(uiState)

            continuation.onTermination = { [weak self] _ in
                Task {
                    await self?.clearStateContinuation()
                }
            }
        }
    }

    @MainActor
    private func clearStateContinuation() {
        stateContinuation = nil
    }

    func submit() async throws -> PaymentResult {
        try await withCheckedThrowingContinuation { continuation in
            Task {
                // Update UI state to show processing
                updateState { state in
                    var newState = state
                    newState.isProcessing = true
                    return newState
                }

                logger.debug(message: "🔄 Processing payment submission")

                // Validate all fields
                let isValid = await validateAllFields()

                if isValid {
                    logger.debug(message: "✅ Form validation successful, processing payment")

                    // Process payment
                    do {
                        // Simulate network call
                        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)

                        let result = PaymentResult(
                            transactionId: UUID().uuidString,
                            amount: Decimal(100),
                            currency: "USD"
                        )

                        logger.debug(message: "✅ Payment processed successfully: \(result.transactionId)")

                        // Reset processing state
                        updateState { state in
                            var newState = state
                            newState.isProcessing = false
                            return newState
                        }

                        continuation.resume(returning: result)
                    } catch {
                        logger.error(message: "❌ Payment processing failed: \(error.localizedDescription)")

                        updateState { state in
                            var newState = state
                            newState.isProcessing = false
                            return newState
                        }

                        continuation.resume(throwing: ComponentsPrimerError.paymentProcessingError(error))
                    }
                } else {
                    // Invalid form
                    logger.error(message: "❌ Form validation failed, cannot submit payment")

                    updateState { state in
                        var newState = state
                        newState.isProcessing = false
                        return newState
                    }

                    continuation.resume(throwing: ComponentsPrimerError.invalidCardDetails)
                }
            }
        }
    }

    func cancel() async {
        logger.debug(message: "🛑 Payment flow cancelled")
        updateState { _ in .empty }
    }

    // MARK: - Card Field Update Methods

    func updateCardNumber(_ value: String) {
        logger.debug(message: "🔄 Updating card number: \(value.isEmpty ? "[empty]" : "[masked]")")

        let sanitized = value.replacingOccurrences(of: " ", with: "")

        // Perform real-time validation
        let validationResult = cardNumberValidator.validateWhileTyping(sanitized)

        // Detect card network from the input
        let network = CardNetwork(cardNumber: sanitized)
        if network != .unknown {
            updateCardNetwork(network)
        }

        updateState { state in
            var newState = state
            newState.cardData.cardNumber = InputFieldState(
                value: sanitized,
                validationError: validationResult.toValidationError,
                isVisible: state.cardData.cardNumber.isVisible,
                isRequired: true,
                isLast: state.cardData.cardNumber.isLast
            )
            return newState
        }
    }

    func updateCardholderName(_ value: String) {
        logger.debug(message: "🔄 Updating cardholder name: \(value.isEmpty ? "[empty]" : value)")

        // Perform real-time validation
        let validationResult = cardholderNameValidator.validateWhileTyping(value)

        updateState { state in
            var newState = state
            newState.cardData.cardholderName = InputFieldState(
                value: value,
                validationError: validationResult.toValidationError,
                isVisible: state.cardData.cardholderName.isVisible,
                isRequired: true,
                isLast: state.cardData.cardholderName.isLast
            )
            return newState
        }
    }

    func updateCvv(_ value: String) {
        logger.debug(message: "🔄 Updating CVV: \(value.isEmpty ? "[empty]" : "[masked]")")

        // Perform real-time validation
        let validationResult = cvvValidator.validateWhileTyping(value)

        updateState { state in
            var newState = state
            newState.cardData.cvv = InputFieldState(
                value: value,
                validationError: validationResult.toValidationError,
                isVisible: state.cardData.cvv.isVisible,
                isRequired: true,
                isLast: state.cardData.cvv.isLast
            )
            return newState
        }
    }

    func updateExpiryMonth(_ value: String) {
        logger.debug(message: "🔄 Updating expiry month: \(value)")

        // Extract current year from the expiry value
        let components = uiState.cardData.expiration.value.components(separatedBy: "/")
        let currentYear = components.count > 1 ? components[1] : ""

        // Create a new expiry string with updated month
        let newExpiryValue = "\(value)/\(currentYear)"
        updateExpirationValue(newExpiryValue)
    }

    func updateExpiryYear(_ value: String) {
        logger.debug(message: "🔄 Updating expiry year: \(value)")

        // Extract current month from the expiry value
        let components = uiState.cardData.expiration.value.components(separatedBy: "/")
        let currentMonth = components.count > 0 ? components[0] : ""

        // Create a new expiry string with updated year
        let newExpiryValue = "\(currentMonth)/\(value)"
        updateExpirationValue(newExpiryValue)
    }

    // Helper method to update the expiration value
    private func updateExpirationValue(_ value: String) {
        // Perform real-time validation
        let validationResult = expiryDateValidator.validateWhileTyping(value)

        updateState { state in
            var newState = state
            newState.cardData.expiration = InputFieldState(
                value: value,
                validationError: validationResult.toValidationError,
                isVisible: state.cardData.expiration.isVisible,
                isRequired: state.cardData.expiration.isRequired,
                isLast: state.cardData.expiration.isLast
            )
            return newState
        }
    }

    func updateCardNetwork(_ network: CardNetwork) {
        logger.debug(message: "🔄 Updating card network to: \(network.displayName)")

        updateState { state in
            var newState = state
            newState.cardNetworkData.selectedNetwork = network
            newState.surcharge = getFormattedSurchargeOrNull(network)
            return newState
        }

        // Update the CVV validator to use the new network
        cvvValidator = CVVFieldValidator(
            validationService: validationService,
            cardNetwork: network
        )

        // Update context in the form validator
        formValidator.updateContext(key: "cardNetwork", value: network)
    }

    // MARK: - Billing Address Update Methods

    func updateCountry(_ country: Country) {
        logger.debug(message: "🔄 Updating country: \(country.name)")

        updateState { state in
            var newState = state

            // Validate using form validator
            let validationResult = formValidator.validateField(type: .countryCode, value: country.name)

            newState.billingAddress.country = InputFieldState(
                value: country.name,
                validationError: validationResult.toValidationError,
                isVisible: state.billingAddress.country.isVisible,
                isRequired: state.billingAddress.country.isRequired,
                isLast: state.billingAddress.country.isLast
            )
            return newState
        }
    }

    func updateFirstName(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.firstName,
            value: value,
            inputType: .firstName
        )
    }

    func updateLastName(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.lastName,
            value: value,
            inputType: .lastName
        )
    }

    func updateAddressLine1(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.addressLine1,
            value: value,
            inputType: .addressLine1
        )
    }

    func updateAddressLine2(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.addressLine2,
            value: value,
            inputType: .addressLine2
        )
    }

    func updatePostalCode(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.postalCode,
            value: value,
            inputType: .postalCode
        )
    }

    func updateCity(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.city,
            value: value,
            inputType: .city
        )
    }

    func updateState(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.state,
            value: value,
            inputType: .state
        )
    }

    // MARK: - CardPaymentMethodScope Component Methods

    @available(iOS 15.0, *)
    func PrimerCardNumberField(modifier: Any, label: String?) -> any View {
        return CardNumberInputField(
            label: label,
            placeholder: "1234 5678 9012 3456",
            validationService: validationService,
            onCardNetworkChange: { [weak self] network in
                self?.updateCardNetwork(network)
            },
            onFormattedChange: { [weak self] formatted in
                self?.updateCardNumber(formatted.filter { $0.isNumber })
            },
            onValidationChange: { _ in },
            onErrorChange: { _ in }
        )
    }

    @available(iOS 15.0, *)
    func PrimerCardExpirationField(modifier: Any, label: String?) -> any View {
        ExpiryDateInputField(
            placeholder: label ?? "Expiry Date",
            onFormattedChange: { formattedText in
                let parts = formattedText.split(separator: "/")
                if parts.count == 2 {
                    self.updateExpiryMonth(String(parts[0]))
                    self.updateExpiryYear(String(parts[1]))
                }
            },
            onValidationChange: { _ in },
            onErrorChange: { _ in }
        )
    }

    @available(iOS 15.0, *)
    func PrimerCvvField(modifier: Any, label: String?) -> any View {
        CVVInputField(
            placeholder: label ?? "CVV",
            cardNetwork: uiState.cardNetworkData.selectedNetwork ?? .unknown,
            onFormattedChange: { self.updateCvv($0) },
            onValidationChange: { _ in },
            onErrorChange: { _ in }
        )
    }

    @available(iOS 15.0, *)
    func PrimerCardholderNameField(modifier: Any, label: String?) -> any View {
        CardholderNameInputField(
            placeholder: label ?? "Cardholder Name",
            onFormattedChange: { self.updateCardholderName($0) },
            onValidationChange: { _ in },
            onErrorChange: { _ in }
        )
    }

    func PrimerCountryField(modifier: Any, label: String?) -> any View {
        guard uiState.billingAddress.country.isVisible else { return EmptyView() }

        return CountryPickerField(
            label: label ?? "Country",
            selectedCountry: uiState.billingAddress.country.value,
            onCountrySelected: { country in
                self.updateCountry(country)
            },
            validationError: uiState.billingAddress.country.validationError?.message
        )
    }

    func PrimerFirstNameField(modifier: Any, label: String?) -> any View {
        guard uiState.billingAddress.firstName.isVisible else { return EmptyView() }

        return PrimerInputField(
            value: uiState.billingAddress.firstName.value,
            onValueChange: { self.updateFirstName($0) },
            labelText: label ?? "First Name",
            validationError: uiState.billingAddress.firstName.validationError?.message,
            keyboardType: .namePhonePad,
            keyboardReturnKey: uiState.billingAddress.firstName.imeAction
        )
    }

    func PrimerLastNameField(modifier: Any, label: String?) -> any View {
        guard uiState.billingAddress.lastName.isVisible else { return EmptyView() }

        return PrimerInputField(
            value: uiState.billingAddress.lastName.value,
            onValueChange: { self.updateLastName($0) },
            labelText: label ?? "Last Name",
            validationError: uiState.billingAddress.lastName.validationError?.message,
            keyboardType: .namePhonePad,
            keyboardReturnKey: uiState.billingAddress.lastName.imeAction
        )
    }

    func PrimerAddressLine1Field(modifier: Any, label: String?) -> any View {
        guard uiState.billingAddress.addressLine1.isVisible else { return EmptyView() }

        return PrimerInputField(
            value: uiState.billingAddress.addressLine1.value,
            onValueChange: { self.updateAddressLine1($0) },
            labelText: label ?? "Address Line 1",
            validationError: uiState.billingAddress.addressLine1.validationError?.message,
            keyboardType: .default,
            keyboardReturnKey: uiState.billingAddress.addressLine1.imeAction
        )
    }

    func PrimerAddressLine2Field(modifier: Any, label: String?) -> any View {
        guard uiState.billingAddress.addressLine2.isVisible else { return EmptyView() }

        return PrimerInputField(
            value: uiState.billingAddress.addressLine2.value,
            onValueChange: { self.updateAddressLine2($0) },
            labelText: label ?? "Address Line 2 (optional)",
            validationError: uiState.billingAddress.addressLine2.validationError?.message,
            keyboardType: .default,
            keyboardReturnKey: uiState.billingAddress.addressLine2.imeAction
        )
    }

    func PrimerPostalCodeField(modifier: Any, label: String?) -> any View {
        guard uiState.billingAddress.postalCode.isVisible else { return EmptyView() }

        return PrimerInputField(
            value: uiState.billingAddress.postalCode.value,
            onValueChange: { self.updatePostalCode($0) },
            labelText: label ?? "Postal Code",
            validationError: uiState.billingAddress.postalCode.validationError?.message,
            keyboardType: .default,
            keyboardReturnKey: uiState.billingAddress.postalCode.imeAction
        )
    }

    func PrimerCityField(modifier: Any, label: String?) -> any View {
        guard uiState.billingAddress.city.isVisible else { return EmptyView() }

        return PrimerInputField(
            value: uiState.billingAddress.city.value,
            onValueChange: { self.updateCity($0) },
            labelText: label ?? "City",
            validationError: uiState.billingAddress.city.validationError?.message,
            keyboardType: .default,
            keyboardReturnKey: uiState.billingAddress.city.imeAction
        )
    }

    func PrimerStateField(modifier: Any, label: String?) -> any View {
        guard uiState.billingAddress.state.isVisible else { return EmptyView() }

        return PrimerInputField(
            value: uiState.billingAddress.state.value,
            onValueChange: { self.updateState($0) },
            labelText: label ?? "State / Region / County",
            validationError: uiState.billingAddress.state.validationError?.message,
            keyboardType: .default,
            keyboardReturnKey: uiState.billingAddress.state.imeAction
        )
    }

    func PrimerPayButton(enabled: Bool, modifier: Any, text: String?) -> any View {
        return PrimerComponentsButton(
            text: text ?? "Pay",
            isLoading: uiState.isProcessing,
            isEnabled: enabled && !uiState.isProcessing,
            action: { [weak self] in
                Task {
                    guard let self = self else { return }
                    do {
                        _ = try await self.submit()
                    } catch {
                        self.logger.error(message: "❌ Payment button action failed: \(error.localizedDescription)")
                    }
                }
            }
        )
    }

    // MARK: - Helper Methods

    private func updateState(_ transform: (CardPaymentUiState) -> CardPaymentUiState) {
        uiState = transform(uiState)
        stateContinuation?.yield(uiState)
    }

    private func updateBillingFieldState(
        keyPath: KeyPath<CardPaymentUiState.BillingAddress, InputFieldState>,
        value: String,
        inputType: PrimerInputElementType
    ) {
        logger.debug(message: "🔄 Updating billing field \(inputType.rawValue): \(value)")

        updateState { state in
            var newState = state

            // Get validation result from form validator
            let validationResult = formValidator.validateField(type: inputType, value: value)

            // Update the specific field
            let currentField = state.billingAddress[keyPath: keyPath]
            let updatedField = InputFieldState(
                value: value,
                validationError: validationResult.toValidationError,
                isVisible: currentField.isVisible,
                isRequired: currentField.isRequired,
                isLast: currentField.isLast
            )

            // Create a new billing address with the updated field
            let updatedFields = [keyPath: updatedField]
            let newBillingAddress = createUpdatedBillingAddress(
                currentBillingAddress: state.billingAddress,
                updatedFields: updatedFields
            )

            // Update the state with the new billing address
            newState = newState.copyWithBillingAddress(newBillingAddress)

            return newState
        }
    }

    // Helper method to create updated billing address
    private func createUpdatedBillingAddress(
        currentBillingAddress: CardPaymentUiState.BillingAddress,
        updatedFields: [KeyPath<CardPaymentUiState.BillingAddress, InputFieldState>: InputFieldState]
    ) -> CardPaymentUiState.BillingAddress {
        // Create a new billing address with updates
        return CardPaymentUiState.BillingAddress(
            country: updatedFields[\CardPaymentUiState.BillingAddress.country] ?? currentBillingAddress.country,
            firstName: updatedFields[\CardPaymentUiState.BillingAddress.firstName] ?? currentBillingAddress.firstName,
            lastName: updatedFields[\CardPaymentUiState.BillingAddress.lastName] ?? currentBillingAddress.lastName,
            addressLine1: updatedFields[\CardPaymentUiState.BillingAddress.addressLine1] ?? currentBillingAddress.addressLine1,
            addressLine2: updatedFields[\CardPaymentUiState.BillingAddress.addressLine2] ?? currentBillingAddress.addressLine2,
            city: updatedFields[\CardPaymentUiState.BillingAddress.city] ?? currentBillingAddress.city,
            postalCode: updatedFields[\CardPaymentUiState.BillingAddress.postalCode] ?? currentBillingAddress.postalCode,
            state: updatedFields[\CardPaymentUiState.BillingAddress.state] ?? currentBillingAddress.state
        )
    }

    private func validateAllFields() async -> Bool {
        logger.debug(message: "🔍 Validating all fields for form submission")

        // Create a map of all card fields
        let cardFieldsMap: [PrimerInputElementType: String?] = [
            .cardNumber: uiState.cardData.cardNumber.value,
            .expiryDate: uiState.cardData.expiration.value,
            .cvv: uiState.cardData.cvv.value,
            .cardholderName: uiState.cardData.cardholderName.value
        ]

        // Create a map of all billing address fields (only required fields)
        let billingAddressMap: [PrimerInputElementType: String?] = [
            .countryCode: uiState.billingAddress.country.isRequired ? uiState.billingAddress.country.value : nil,
            .firstName: uiState.billingAddress.firstName.isRequired ? uiState.billingAddress.firstName.value : nil,
            .lastName: uiState.billingAddress.lastName.isRequired ? uiState.billingAddress.lastName.value : nil,
            .addressLine1: uiState.billingAddress.addressLine1.isRequired ? uiState.billingAddress.addressLine1.value : nil,
            .city: uiState.billingAddress.city.isRequired ? uiState.billingAddress.city.value : nil,
            .postalCode: uiState.billingAddress.postalCode.isRequired ? uiState.billingAddress.postalCode.value : nil,
            .state: uiState.billingAddress.state.isRequired ? uiState.billingAddress.state.value : nil
        ]

        // Combine all fields into one map
        var allFields = cardFieldsMap
        for (key, value) in billingAddressMap where value != nil {
            // Only include fields that need validation
            allFields[key] = value
        }

        // Use form validator to validate all fields at once
        let validationErrors = formValidator.validateForm(fields: allFields)

        // Update UI state with validation errors
        updateState { state in
            var newState = state

            // Update card fields validation errors
            newState.cardData.cardNumber = updateFieldWithError(
                field: state.cardData.cardNumber,
                error: validationErrors[.cardNumber] ?? nil
            )

            newState.cardData.expiration = updateFieldWithError(
                field: state.cardData.expiration,
                error: validationErrors[.expiryDate] ?? nil
            )

            newState.cardData.cvv = updateFieldWithError(
                field: state.cardData.cvv,
                error: validationErrors[.cvv] ?? nil
            )

            newState.cardData.cardholderName = updateFieldWithError(
                field: state.cardData.cardholderName,
                error: validationErrors[.cardholderName] ?? nil
            )

            // Update billing address fields validation errors
            let newBillingAddress = CardPaymentUiState.BillingAddress(
                country: updateFieldWithError(
                    field: state.billingAddress.country,
                    error: validationErrors[.countryCode] ?? nil
                ),
                firstName: updateFieldWithError(
                    field: state.billingAddress.firstName,
                    error: validationErrors[.firstName] ?? nil
                ),
                lastName: updateFieldWithError(
                    field: state.billingAddress.lastName,
                    error: validationErrors[.lastName] ?? nil
                ),
                addressLine1: updateFieldWithError(
                    field: state.billingAddress.addressLine1,
                    error: validationErrors[.addressLine1] ?? nil
                ),
                addressLine2: updateFieldWithError(
                    field: state.billingAddress.addressLine2,
                    error: validationErrors[.addressLine2] ?? nil
                ),
                city: updateFieldWithError(
                    field: state.billingAddress.city,
                    error: validationErrors[.city] ?? nil
                ),
                postalCode: updateFieldWithError(
                    field: state.billingAddress.postalCode,
                    error: validationErrors[.postalCode] ?? nil
                ),
                state: updateFieldWithError(
                    field: state.billingAddress.state,
                    error: validationErrors[.state] ?? nil
                )
            )

            newState = newState.copyWithBillingAddress(newBillingAddress)

            return newState
        }

        // Check if any field has validation errors
        let hasErrors = validationErrors.values.contains { $0 != nil }

        if hasErrors {
            logger.error(message: "❌ Form validation found errors")
            for (field, error) in validationErrors where error != nil {
                logger.error(message: "❌ Field \(field.rawValue) error: \(error!.message)")
            }
        } else {
            logger.debug(message: "✅ Form validation successful")
        }

        return !hasErrors
    }

    private func updateFieldWithError(field: InputFieldState, error: ValidationError?) -> InputFieldState {
        return InputFieldState(
            value: field.value,
            validationError: error,
            isVisible: field.isVisible,
            isRequired: field.isRequired,
            isLast: field.isLast
        )
    }

    // Helper method for formatted surcharge
    private func getFormattedSurchargeOrNull(_ network: CardNetwork) -> String? {
        // Implementation would depend on your surcharge calculation logic
        return nil
    }

    deinit {
        logger.debug(message: "🗑️ CardViewModel deallocated")
        stateContinuation?.finish()
    }
}

// Helper types remain the same as in original file
// MARK: - Helper Types

struct Country {
    let code: String
    let name: String
    let flag: String
}

@available(iOS 15.0, *)
struct PrimerComponentsButton: View {
    let text: String
    let isLoading: Bool
    let isEnabled: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle())
                        .padding(.trailing, 8)
                }
                Text(text)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(isEnabled ? Color.blue : Color.gray)
            .foregroundColor(.white)
            .cornerRadius(8)
        }
        .disabled(!isEnabled)
    }
}

@available(iOS 15.0, *)
struct CountryPickerField: View {
    let label: String
    let selectedCountry: String
    let onCountrySelected: (Country) -> Void
    let validationError: String?

    @State private var isShowingPicker = false

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)

            Button(action: { isShowingPicker = true }) {
                HStack {
                    Text(selectedCountry.isEmpty ? "Select a country" : selectedCountry)
                        .foregroundColor(selectedCountry.isEmpty ? .gray : .primary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }

            if let validationError = validationError {
                Text(validationError)
                    .font(.caption)
                    .foregroundColor(.red)
            }
        }
        .sheet(isPresented: $isShowingPicker) {
            CountryPickerView(selectedCountry: selectedCountry) { country in
                onCountrySelected(country)
                isShowingPicker = false
            }
        }
    }
}

@available(iOS 15.0, *)
struct CountryPickerView: View {
    let selectedCountry: String
    let onCountrySelected: (Country) -> Void
    @Environment(\.dismiss) private var dismiss

    // Sample countries - in a real app, this would come from a repository
    private let countries = [
        Country(code: "US", name: "United States", flag: "🇺🇸"),
        Country(code: "CA", name: "Canada", flag: "🇨🇦"),
        Country(code: "GB", name: "United Kingdom", flag: "🇬🇧"),
        Country(code: "AU", name: "Australia", flag: "🇦🇺"),
        Country(code: "DE", name: "Germany", flag: "🇩🇪")
    ]

    @State private var searchText = ""

    var filteredCountries: [Country] {
        if searchText.isEmpty {
            return countries
        } else {
            return countries.filter {
                $0.name.lowercased().contains(searchText.lowercased())
            }
        }
    }

    var body: some View {
        NavigationView {
            List {
                ForEach(filteredCountries, id: \.code) { country in
                    Button(action: { onCountrySelected(country) }) {
                        HStack {
                            Text(country.flag)
                                .padding(.trailing, 8)
                            Text(country.name)
                            Spacer()
                            if country.name == selectedCountry {
                                Image(systemName: "checkmark")
                                    .foregroundColor(.blue)
                            }
                        }
                    }
                    .foregroundColor(.primary)
                }
            }
            .searchable(text: $searchText, prompt: "Search countries")
            .navigationTitle("Select Country")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        // Just dismiss without selection
                        searchText = ""
                        dismiss()
                    }
                }
            }
        }
    }
}

// swiftlint:enable file_length
