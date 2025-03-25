//
//  CardViewModel.swift
//
//
//  Created by Boris on 24.3.25..
//

// swiftlint:disable all

import Foundation
import SwiftUI

@available(iOS 15.0, *)
@MainActor
class CardViewModel: ObservableObject, CardPaymentMethodScope {
    // MARK: - Properties

    @Published private var uiState: CardPaymentUiState = .empty
    private var stateContinuation: AsyncStream<CardPaymentUiState?>.Continuation?

    private let cardValidator: CardValidator
    private let billingAddressValidator: BillingAddressValidator

    // MARK: - Initialization

    init(
        cardValidator: CardValidator = DefaultCardValidator(),
        billingAddressValidator: BillingAddressValidator = DefaultBillingAddressValidator()
    ) {
        self.cardValidator = cardValidator
        self.billingAddressValidator = billingAddressValidator
    }

    // MARK: - PrimerPaymentMethodScope Implementation

    func state() -> AsyncStream<CardPaymentUiState?> {
        return AsyncStream { continuation in
            self.stateContinuation = continuation
            continuation.yield(uiState)
        }
    }

    // Add this method to CardViewModel
    func submit() {
        // Call the async version
        Task {
            do {
                _ = try await submit()
            } catch {
                // Handle the error - maybe update UI state or log
                print("Payment submission failed: \(error.localizedDescription)")
            }
        }
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

                // Validate all fields
                let isValid = await validateAllFields()

                if isValid {
                    // Process payment
                    do {
                        // Simulate network call
                        try await Task.sleep(nanoseconds: 2 * 1_000_000_000)

                        let result = PaymentResult(
                            transactionId: UUID().uuidString,
                            amount: Decimal(100),
                            currency: "USD"
                        )

                        // Reset processing state
                        updateState { state in
                            var newState = state
                            newState.isProcessing = false
                            return newState
                        }

                        continuation.resume(returning: result)
                    } catch {
                        updateState { state in
                            var newState = state
                            newState.isProcessing = false
                            return newState
                        }

                        continuation.resume(throwing: ComponentsPrimerError.paymentProcessingError(error))
                    }
                } else {
                    // Invalid form
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
        updateState { _ in .empty }
    }

    // MARK: - Card Field Update Methods

    func updateCardNumber(_ value: String) {
        let sanitized = value.replacingOccurrences(of: " ", with: "")
        let error = cardValidator.validateCardNumber(sanitized)

        updateState { state in
            var newState = state
            newState.cardData.cardNumber = InputFieldState(
                value: sanitized,
                validationError: error,
                isVisible: state.cardData.cardNumber.isVisible,
                isRequired: state.cardData.cardNumber.isRequired,
                isLast: state.cardData.cardNumber.isLast
            )

            // Update card network based on card number
            let network = CardNetwork(cardNumber: sanitized)
            if network != .unknown {
                newState.cardNetworkData.selectedNetwork = network
            }

            return newState
        }
    }

    // Method to update cardholder name
    func updateCardholderName(_ value: String) {
        let error = cardValidator.validateCardholderName(value)

        updateState { state in
            var newState = state
            newState.cardData.cardholderName = InputFieldState(
                value: value,
                validationError: error,
                isVisible: state.cardData.cardholderName.isVisible,
                isRequired: state.cardData.cardholderName.isRequired,
                isLast: state.cardData.cardholderName.isLast
            )
            return newState
        }
    }

    // Method to update CVV
    func updateCvv(_ value: String) {
        let network = uiState.cardNetworkData.selectedNetwork ?? .unknown
        let error = cardValidator.validateCvv(value, cardNetwork: network)

        updateState { state in
            var newState = state
            newState.cardData.cvv = InputFieldState(
                value: value,
                validationError: error,
                isVisible: state.cardData.cvv.isVisible,
                isRequired: state.cardData.cvv.isRequired,
                isLast: state.cardData.cvv.isLast
            )
            return newState
        }
    }

    // Method to update expiry month
    func updateExpiryMonth(_ value: String) {
        // Extract current year from the expiry value
        let components = uiState.cardData.expiration.value.components(separatedBy: "/")
        let currentYear = components.count > 1 ? components[1] : ""

        // Create a new expiry string with updated month
        let newExpiryValue = "\(value)/\(currentYear)"
        updateExpirationValue(newExpiryValue)
    }

    // Method to update expiry year
    func updateExpiryYear(_ value: String) {
        // Extract current month from the expiry value
        let components = uiState.cardData.expiration.value.components(separatedBy: "/")
        let currentMonth = components.count > 0 ? components[0] : ""

        // Create a new expiry string with updated year
        let newExpiryValue = "\(currentMonth)/\(value)"
        updateExpirationValue(newExpiryValue)
    }

    // Helper method to update the expiration value
    private func updateExpirationValue(_ value: String) {
        // Extract month and year for validation
        let components = value.components(separatedBy: "/")
        let month = components.count > 0 ? components[0] : ""
        let year = components.count > 1 ? components[1] : ""

        let error = cardValidator.validateExpiration(month: month, year: year)

        updateState { state in
            var newState = state
            newState.cardData.expiration = InputFieldState(
                value: value,
                validationError: error,
                isVisible: state.cardData.expiration.isVisible,
                isRequired: state.cardData.expiration.isRequired,
                isLast: state.cardData.expiration.isLast
            )
            return newState
        }
    }

    // Method to update card network
    func updateCardNetwork(_ network: CardNetwork) async {
        updateState { state in
            var newState = state
            newState.cardNetworkData.selectedNetwork = network
            newState.surcharge = getFormattedSurchargeOrNull(network)
            return newState
        }
    }

    // Helper method for formatted surcharge - you should have something similar already
    private func getFormattedSurchargeOrNull(_ network: CardNetwork) -> String? {
        // Implementation would depend on your surcharge calculation logic
        // This is a placeholder
        return nil
    }

    // MARK: - CardPaymentMethodScope Component Methods

    func PrimerCardholderNameField(modifier: Any, label: String?) -> any View {
        return CardholderNameInputField(
            label: label ?? "Cardholder Name",
            placeholder: "John Doe",
            onValidationChange: { isValid in
                // Handle validation change
            }
        )
    }

    func PrimerCardNumberField(modifier: Any, label: String?) -> any View {
        return CardNumberInputField(
            label: label ?? "Card Number",
            placeholder: "1234 5678 9012 3456",
            onCardNetworkChange: { network in
                // Handle card network change
            },
            onValidationChange: { isValid in
                // Handle validation change
            }
        )
    }

    func PrimerCvvField(modifier: Any, label: String?) -> any View {
        return CVVInputField(
            label: label ?? "CVV",
            placeholder: "123",
            cardNetwork: uiState.cardNetworkData.selectedNetwork ?? .unknown,
            onValidationChange: { isValid in
                // Handle validation change
            }
        )
    }

    func PrimerCardExpirationField(modifier: Any, label: String?) -> any View {
        return ExpiryDateInputField(
            label: label ?? "Expiry Date",
            placeholder: "MM/YY",
            onValidationChange: { isValid in
                // Handle validation change
            },
            onMonthChange: { month in
                // Handle month change
            },
            onYearChange: { year in
                // Handle year change
            }
        )
    }

    // MARK: - Billing Address Field Components

    func PrimerCountryField(modifier: Any, label: String?) -> any View {
        // Only show if configured to be visible
        guard uiState.billingAddress.country.isVisible else {
            return EmptyView()
        }

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
        // Only show if configured to be visible
        guard uiState.billingAddress.firstName.isVisible else {
            return EmptyView()
        }

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
        // Only show if configured to be visible
        guard uiState.billingAddress.lastName.isVisible else {
            return EmptyView()
        }

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
        // Only show if configured to be visible
        guard uiState.billingAddress.addressLine1.isVisible else {
            return EmptyView()
        }

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
        // Only show if configured to be visible
        guard uiState.billingAddress.addressLine2.isVisible else {
            return EmptyView()
        }

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
        // Only show if configured to be visible
        guard uiState.billingAddress.postalCode.isVisible else {
            return EmptyView()
        }

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
        // Only show if configured to be visible
        guard uiState.billingAddress.city.isVisible else {
            return EmptyView()
        }

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
        // Only show if configured to be visible
        guard uiState.billingAddress.state.isVisible else {
            return EmptyView()
        }

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
            action: {
                Task {
                    do {
                        // Explicitly discard the result with _ =
                        _ = try await self.submit()
                        // Or handle the result:
                        // let result = try await self.submit()
                        // print("Payment successful: \(result.transactionId)")
                    } catch {
                        // Handle error
                        print("Payment failed: \(error)")
                    }
                }
            }
        )
    }

    // MARK: - Update Methods for Billing Address Fields

    func updateCountry(_ country: Country) {
        updateState { state in
            var newState = state
            newState.billingAddress.country = InputFieldState(
                value: country.name,
                validationError: nil,
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
            value: value
        )
    }

    func updateLastName(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.lastName,
            value: value
        )
    }

    func updateAddressLine1(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.addressLine1,
            value: value
        )
    }

    func updateAddressLine2(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.addressLine2,
            value: value
        )
    }

    func updatePostalCode(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.postalCode,
            value: value
        )
    }

    func updateCity(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.city,
            value: value
        )
    }

    func updateState(_ value: String) {
        updateBillingFieldState(
            keyPath: \CardPaymentUiState.BillingAddress.state,
            value: value
        )
    }

    // MARK: - Helper Methods

    private func updateState(_ transform: (CardPaymentUiState) -> CardPaymentUiState) {
        uiState = transform(uiState)
        stateContinuation?.yield(uiState)
    }

    private func updateBillingFieldState(keyPath: KeyPath<CardPaymentUiState.BillingAddress, InputFieldState>, value: String) {
        updateState { state in
            var newState = state

            // Create a new billing address with the updated field
            let currentBillingAddress = state.billingAddress
            var updatedFields: [KeyPath<CardPaymentUiState.BillingAddress, InputFieldState>: InputFieldState] = [:]

            // Update the specific field
            let currentField = currentBillingAddress[keyPath: keyPath]
            let updatedField = InputFieldState(
                value: value,
                validationError: nil,
                isVisible: currentField.isVisible,
                isRequired: currentField.isRequired,
                isLast: currentField.isLast
            )
            updatedFields[keyPath] = updatedField

            // Create a new billing address with the updated field
            let newBillingAddress = createUpdatedBillingAddress(
                currentBillingAddress: currentBillingAddress,
                updatedFields: updatedFields
            )

            // Run validation if needed
            let validatedBillingAddress = validateBillingAddressIfNeeded(
                billingAddress: newBillingAddress,
                field: keyPath,
                value: value
            )

            // Update the state with the new billing address
            newState = newState.copyWithBillingAddress(validatedBillingAddress)

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

    // Helper to validate a field if needed
    private func validateBillingAddressIfNeeded(
        billingAddress: CardPaymentUiState.BillingAddress,
        field: KeyPath<CardPaymentUiState.BillingAddress, InputFieldState>,
        value: String
    ) -> CardPaymentUiState.BillingAddress {

        let currentField = billingAddress[keyPath: field]

        // Only validate required fields with empty values
        if value.isEmpty && currentField.isRequired {
            let validator = DefaultBillingAddressValidator()
            let inputType = billingAddressFieldToInputElementType(field)

            let validationErrors = validator.getValidatedBillingAddress(
                billingAddress: [inputType: value]
            )

            if let error = validationErrors[inputType] {
                var updatedFields: [KeyPath<CardPaymentUiState.BillingAddress, InputFieldState>: InputFieldState] = [:]

                updatedFields[field] = InputFieldState(
                    value: value,
                    validationError: error,
                    isVisible: currentField.isVisible,
                    isRequired: currentField.isRequired,
                    isLast: currentField.isLast
                )

                return createUpdatedBillingAddress(
                    currentBillingAddress: billingAddress,
                    updatedFields: updatedFields
                )
            }
        }

        return billingAddress
    }

    // Fixed method to convert KeyPath to PrimerInputElementType
    private func billingAddressFieldToInputElementType(_ keyPath: KeyPath<CardPaymentUiState.BillingAddress, InputFieldState>) -> PrimerInputElementType {
        if keyPath == \CardPaymentUiState.BillingAddress.country {
            return .countryCode
        } else if keyPath == \CardPaymentUiState.BillingAddress.firstName {
            return .firstName
        } else if keyPath == \CardPaymentUiState.BillingAddress.lastName {
            return .lastName
        } else if keyPath == \CardPaymentUiState.BillingAddress.addressLine1 {
            return .addressLine1
        } else if keyPath == \CardPaymentUiState.BillingAddress.addressLine2 {
            return .addressLine2
        } else if keyPath == \CardPaymentUiState.BillingAddress.city {
            return .city
        } else if keyPath == \CardPaymentUiState.BillingAddress.postalCode {
            return .postalCode
        } else if keyPath == \CardPaymentUiState.BillingAddress.state {
            return .state
        } else {
            return .unknown // Fallback to unknown
        }
    }


    private func keyPathToInputElementType(_ keyPath: WritableKeyPath<CardPaymentUiState.BillingAddress, InputFieldState>) -> PrimerInputElementType {
        switch keyPath {
        case \CardPaymentUiState.BillingAddress.country:
            return .countryCode
        case \CardPaymentUiState.BillingAddress.firstName:
            return .firstName
        case \CardPaymentUiState.BillingAddress.lastName:
            return .lastName
        case \CardPaymentUiState.BillingAddress.addressLine1:
            return .addressLine1
        case \CardPaymentUiState.BillingAddress.addressLine2:
            return .addressLine2
        case \CardPaymentUiState.BillingAddress.city:
            return .city
        case \CardPaymentUiState.BillingAddress.postalCode:
            return .postalCode
        case \CardPaymentUiState.BillingAddress.state:
            return .state
        default:
            return .all
        }
    }

    private func validateAllFields() async -> Bool {
        var isValid = true

        // Validate card data
        let cardNumberError = cardValidator.validateCardNumber(uiState.cardData.cardNumber.value)
        if cardNumberError != nil {
            isValid = false
        }

        // Extract month and year from expiration
        let components = uiState.cardData.expiration.value.components(separatedBy: "/")
        let month = components.count > 0 ? components[0] : ""
        let year = components.count > 1 ? components[1] : ""

        let expirationError = cardValidator.validateExpiration(month: month, year: year)
        if expirationError != nil {
            isValid = false
        }

        let network = CardNetwork(cardNumber: uiState.cardData.cardNumber.value.replacingOccurrences(of: " ", with: ""))
        let cvvError = cardValidator.validateCvv(uiState.cardData.cvv.value, cardNetwork: network)
        if cvvError != nil {
            isValid = false
        }

        let cardholderNameError = cardValidator.validateCardholderName(uiState.cardData.cardholderName.value)
        if cardholderNameError != nil {
            isValid = false
        }

        // Validate billing address fields (only required ones)
        let billingAddressMap: [PrimerInputElementType: String?] = [
            .countryCode: uiState.billingAddress.country.isRequired ? uiState.billingAddress.country.value : nil,
            .firstName: uiState.billingAddress.firstName.isRequired ? uiState.billingAddress.firstName.value : nil,
            .lastName: uiState.billingAddress.lastName.isRequired ? uiState.billingAddress.lastName.value : nil,
            .addressLine1: uiState.billingAddress.addressLine1.isRequired ? uiState.billingAddress.addressLine1.value : nil,
            .city: uiState.billingAddress.city.isRequired ? uiState.billingAddress.city.value : nil,
            .postalCode: uiState.billingAddress.postalCode.isRequired ? uiState.billingAddress.postalCode.value : nil,
            .state: uiState.billingAddress.state.isRequired ? uiState.billingAddress.state.value : nil
        ]

        let billingAddressErrors = billingAddressValidator.getValidatedBillingAddress(billingAddress: billingAddressMap)
        if billingAddressErrors.values.contains(where: { $0 != nil }) {
            isValid = false
        }

        return isValid
    }
}

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
// swiftlint:enable all
