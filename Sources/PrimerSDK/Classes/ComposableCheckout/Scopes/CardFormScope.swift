//
//  CardFormScope.swift
//
//
//  Created on 17.06.2025.
//

import SwiftUI
import Combine

/// Card form scope that provides access to card input state and validation.
/// This matches Android's CardFormScope interface exactly.
@available(iOS 15.0, *)
public protocol CardFormScope: ObservableObject {

    /// Reactive state stream for card form
    var state: AnyPublisher<CardFormState, Never> { get }

    // MARK: - Update Methods (match Android exactly)

    func updateCardNumber(_ cardNumber: String)
    func updateCvv(_ cvv: String)
    func updateExpiryDate(_ expiryDate: String)
    func updateCardholderName(_ cardholderName: String)
    func updatePostalCode(_ postalCode: String)
    func updateCountryCode(_ countryCode: String)
    func updateCity(_ city: String)
    func updateState(_ state: String)
    func updateAddressLine1(_ addressLine1: String)
    func updateAddressLine2(_ addressLine2: String)
    func updatePhoneNumber(_ phoneNumber: String)
    func updateFirstName(_ firstName: String)
    func updateLastName(_ lastName: String)
    func updateRetailOutlet(_ retailOutlet: String)
    func updateOtpCode(_ otpCode: String)

    /// Submit the card form
    func submit()
}

// MARK: - Extension Functions (matches Android's companion object)

@available(iOS 15.0, *)
public extension CardFormScope {

    /// Submit button component
    // swiftlint:disable identifier_name
    @ViewBuilder
    func PrimerSubmitButton(
        modifier: PrimerModifier = PrimerModifier(),
        text: String = "Submit"
    ) -> some View {
        SubmitButtonWrapper(scope: self, modifier: modifier, text: text)
    }

    /// Card number input component
    @ViewBuilder
    func PrimerCardNumberInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        CardNumberInputWrapper(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// CVV input component
    @ViewBuilder
    func PrimerCvvInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        CVVInputWrapper(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// Expiry date input component
    @ViewBuilder
    func PrimerExpiryDateInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        ExpiryDateInputWrapper(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// Cardholder name input component
    @ViewBuilder
    func PrimerCardholderNameInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        CardholderNameInputWrapper(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// Postal code input component
    @ViewBuilder
    func PrimerPostalCodeInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        PostalCodeInputView(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// Country code input component
    @ViewBuilder
    func PrimerCountryCodeInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        CountryCodeInputView(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// City input component
    @ViewBuilder
    func PrimerCityInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        CityInputView(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// State input component
    @ViewBuilder
    func PrimerStateInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        StateInputView(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// Address line 1 input component
    @ViewBuilder
    func PrimerAddressLine1Input(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        AddressLine1InputView(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// Address line 2 input component
    @ViewBuilder
    func PrimerAddressLine2Input(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        AddressLine2InputView(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// Phone number input component
    @ViewBuilder
    func PrimerPhoneNumberInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        PhoneNumberInputView(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// First name input component
    @ViewBuilder
    func PrimerFirstNameInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        FirstNameInputView(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// Last name input component
    @ViewBuilder
    func PrimerLastNameInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        LastNameInputView(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// Retail outlet input component
    @ViewBuilder
    func PrimerRetailOutletInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        RetailOutletInputView(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// OTP code input component
    @ViewBuilder
    func PrimerOtpCodeInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil
    ) -> some View {
        OtpCodeInputView(scope: self, modifier: modifier, label: label, placeholder: placeholder)
    }

    /// Composite card details form (card number, cvv, expiry, cardholder name)
    @ViewBuilder
    func PrimerCardDetails(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        VStack(spacing: 16) {
            PrimerCardNumberInput()

            HStack(spacing: 12) {
                PrimerExpiryDateInput()
                PrimerCvvInput()
            }

            PrimerCardholderNameInput()
        }
        .primerModifier(modifier)
    }

    /// Composite billing address form (all address fields)
    @ViewBuilder
    func PrimerBillingAddress(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        BillingAddressFormView(scope: self, modifier: modifier)
    }
    // swiftlint:enable identifier_name
}

// Note: State models are now defined in Models/States/ directory

// MARK: - Default Implementation (Temporary)

/// Temporary default implementation for testing
@available(iOS 15.0, *)
internal class DefaultCardFormScope: CardFormScope, LogReporter {

    @Published private var _state: CardFormState = .initial

    public var state: AnyPublisher<CardFormState, Never> {
        $_state.eraseToAnyPublisher()
    }

    // MARK: - Field Updates

    public func updateCardNumber(_ cardNumber: String) {
        logger.debug(message: "💳 [DefaultCardFormScope] Updating card number")
        updateField(.cardNumber, value: cardNumber)
    }

    public func updateCvv(_ cvv: String) {
        logger.debug(message: "🔒 [DefaultCardFormScope] Updating CVV")
        updateField(.cvv, value: cvv)
    }

    public func updateExpiryDate(_ expiryDate: String) {
        logger.debug(message: "📅 [DefaultCardFormScope] Updating expiry date")
        updateField(.expiryDate, value: expiryDate)
    }

    public func updateCardholderName(_ cardholderName: String) {
        logger.debug(message: "👤 [DefaultCardFormScope] Updating cardholder name")
        updateField(.cardholderName, value: cardholderName)
    }

    public func updatePostalCode(_ postalCode: String) {
        updateField(.postalCode, value: postalCode)
    }

    public func updateCountryCode(_ countryCode: String) {
        updateField(.countryCode, value: countryCode)
    }

    public func updateCity(_ city: String) {
        updateField(.city, value: city)
    }

    public func updateState(_ state: String) {
        updateField(.state, value: state)
    }

    public func updateAddressLine1(_ addressLine1: String) {
        updateField(.addressLine1, value: addressLine1)
    }

    public func updateAddressLine2(_ addressLine2: String) {
        updateField(.addressLine2, value: addressLine2)
    }

    public func updatePhoneNumber(_ phoneNumber: String) {
        updateField(.phoneNumber, value: phoneNumber)
    }

    public func updateFirstName(_ firstName: String) {
        updateField(.firstName, value: firstName)
    }

    public func updateLastName(_ lastName: String) {
        updateField(.lastName, value: lastName)
    }

    public func updateRetailOutlet(_ retailOutlet: String) {
        updateField(.retailOutlet, value: retailOutlet)
    }

    public func updateOtpCode(_ otpCode: String) {
        updateField(.otpCode, value: otpCode)
    }

    public func submit() {
        logger.debug(message: "🚀 [DefaultCardFormScope] Submitting form")

        _state = CardFormState(
            inputFields: _state.inputFields,
            fieldErrors: _state.fieldErrors,
            isLoading: true,
            isSubmitEnabled: false
        )

        // Simulate submission
        Task {
            try await Task.sleep(nanoseconds: 2_000_000_000) // 2 seconds
            await MainActor.run {
                logger.info(message: "✅ [DefaultCardFormScope] Form submitted successfully")
                // TODO: Handle successful submission
            }
        }
    }

    // MARK: - Private Methods

    private func updateField(_ elementType: ComposableInputElementType, value: String) {
        var updatedFields = _state.inputFields
        updatedFields[elementType] = value

        _state = CardFormState(
            inputFields: updatedFields,
            fieldErrors: _state.fieldErrors,
            isLoading: _state.isLoading,
            isSubmitEnabled: hasRequiredFields(updatedFields)
        )
    }

    private func hasRequiredFields(_ fields: [ComposableInputElementType: String]) -> Bool {
        let cardNumber = fields[.cardNumber] ?? ""
        let cvv = fields[.cvv] ?? ""
        let expiryDate = fields[.expiryDate] ?? ""

        return !cardNumber.isEmpty && !cvv.isEmpty && !expiryDate.isEmpty
    }
}

// MARK: - Forward Declarations for UI Components

// These will be implemented in Phase 5 using existing components

@available(iOS 15.0, *)
internal struct SubmitButtonView: View {
    let scope: any CardFormScope
    let text: String

    var body: some View {
        Text("Submit Button Placeholder: \(text)")
    }
}

@available(iOS 15.0, *)
internal struct CardNumberInputView: View {
    let scope: any CardFormScope

    var body: some View {
        Text("Card Number Input Placeholder")
    }
}

@available(iOS 15.0, *)
internal struct CvvInputView: View {
    let scope: any CardFormScope

    var body: some View {
        Text("CVV Input Placeholder")
    }
}

@available(iOS 15.0, *)
internal struct ExpiryDateInputView: View {
    let scope: any CardFormScope

    var body: some View {
        Text("Expiry Date Input Placeholder")
    }
}

@available(iOS 15.0, *)
internal struct CardholderNameInputView: View {
    let scope: any CardFormScope

    var body: some View {
        Text("Cardholder Name Input Placeholder")
    }
}

@available(iOS 15.0, *)
internal struct PostalCodeInputView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?

    var body: some View {
        Text("Postal Code Input Placeholder")
            .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct CountryCodeInputView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?

    var body: some View {
        Text("Country Code Input Placeholder")
            .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct CityInputView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?

    var body: some View {
        Text("City Input Placeholder")
            .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct StateInputView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?

    var body: some View {
        Text("State Input Placeholder")
            .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct AddressLine1InputView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?

    var body: some View {
        Text("Address Line 1 Input Placeholder")
            .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct AddressLine2InputView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?

    var body: some View {
        Text("Address Line 2 Input Placeholder")
            .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct PhoneNumberInputView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?

    var body: some View {
        Text("Phone Number Input Placeholder")
            .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct FirstNameInputView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?

    var body: some View {
        Text("First Name Input Placeholder")
            .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct LastNameInputView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?

    var body: some View {
        Text("Last Name Input Placeholder")
            .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct RetailOutletInputView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?

    var body: some View {
        Text("Retail Outlet Input Placeholder")
            .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct OtpCodeInputView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?

    var body: some View {
        Text("OTP Code Input Placeholder")
            .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct CardDetailsFormView: View {
    let scope: any CardFormScope

    var body: some View {
        VStack {
            Text("Card Details Form Placeholder")
            Text("Will use existing CardNumberInputField, CVVInputField, etc.")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}

@available(iOS 15.0, *)
internal struct BillingAddressFormView: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier

    var body: some View {
        VStack {
            Text("Billing Address Form Placeholder")
            Text("Will use existing address input components")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .primerModifier(modifier)
    }
}
