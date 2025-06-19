//
//  CardFormScope.swift
//
//
//  Created on 17.06.2025.
//

import SwiftUI

/// Card form scope that provides access to card input state and validation.
/// This matches Android's CardFormScope interface exactly.
@available(iOS 15.0, *)
public protocol CardFormScope: ObservableObject {

    /// Reactive state stream for card form
    func state() -> AsyncStream<CardFormState>

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
        CardPaymentButton(
            enabled: true, // Will be bound to state.isSubmitEnabled
            isLoading: false, // Will be bound to state.isLoading
            amount: nil, // Can be passed in if needed
            action: {
                self.submit()
            }
        )
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }

    /// Card number input component
    @ViewBuilder
    func PrimerCardNumberInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        CardNumberInputField(
            label: InputLocalizable.cardNumberLabel,
            placeholder: InputLocalizable.cardNumberPlaceholder,
            onCardNumberChange: { newValue in
                self.updateCardNumber(newValue)
            },
            onCardNetworkChange: nil,  // Internal - not exposed
            onValidationChange: nil     // Internal - not exposed
        )
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }

    /// CVV input component
    @ViewBuilder
    func PrimerCvvInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        // Create a stateful wrapper that tracks card network
        CVVInputWithNetwork(scope: self, modifier: modifier)
    }

    /// Expiry date input component
    @ViewBuilder
    func PrimerExpiryDateInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        ExpiryDateInputField(
            label: InputLocalizable.expiryDateLabel,
            placeholder: InputLocalizable.expiryDatePlaceholder,
            onExpiryDateChange: { newValue in
                self.updateExpiryDate(newValue)
            }
        )
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }

    /// Cardholder name input component
    @ViewBuilder
    func PrimerCardholderNameInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        CardholderNameInputField(
            label: InputLocalizable.cardholderNameLabel,
            placeholder: InputLocalizable.cardholderNamePlaceholder,
            onCardholderNameChange: { newValue in
                self.updateCardholderName(newValue)
            }
        )
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }

    /// Postal code input component
    @ViewBuilder
    func PrimerPostalCodeInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        StatefulInputField(
            scope: self,
            elementType: .postalCode,
            label: InputLocalizable.postalCodeLabel,
            placeholder: InputLocalizable.postalCodePlaceholder,
            modifier: modifier
        )
    }

    /// Country code input component
    @ViewBuilder
    func PrimerCountryCodeInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        StatefulInputField(
            scope: self,
            elementType: .countryCode,
            label: InputLocalizable.countryCodeLabel,
            placeholder: InputLocalizable.countryCodePlaceholder,
            modifier: modifier
        )
    }

    /// City input component
    @ViewBuilder
    func PrimerCityInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        StatefulInputField(
            scope: self,
            elementType: .city,
            label: InputLocalizable.cityLabel,
            placeholder: InputLocalizable.cityPlaceholder,
            modifier: modifier
        )
    }

    /// State input component
    @ViewBuilder
    func PrimerStateInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        StatefulInputField(
            scope: self,
            elementType: .state,
            label: InputLocalizable.stateLabel,
            placeholder: InputLocalizable.statePlaceholder,
            modifier: modifier
        )
    }

    /// Address line 1 input component
    @ViewBuilder
    func PrimerAddressLine1Input(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        StatefulInputField(
            scope: self,
            elementType: .addressLine1,
            label: InputLocalizable.addressLine1Label,
            placeholder: InputLocalizable.addressLine1Placeholder,
            modifier: modifier
        )
    }

    /// Address line 2 input component
    @ViewBuilder
    func PrimerAddressLine2Input(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        StatefulInputField(
            scope: self,
            elementType: .addressLine2,
            label: InputLocalizable.addressLine2Label,
            placeholder: InputLocalizable.addressLine2Placeholder,
            modifier: modifier
        )
    }

    /// Phone number input component
    @ViewBuilder
    func PrimerPhoneNumberInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        StatefulInputField(
            scope: self,
            elementType: .phoneNumber,
            label: InputLocalizable.phoneNumberLabel,
            placeholder: InputLocalizable.phoneNumberPlaceholder,
            keyboardType: .phonePad,
            modifier: modifier
        )
    }

    /// First name input component
    @ViewBuilder
    func PrimerFirstNameInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        StatefulInputField(
            scope: self,
            elementType: .firstName,
            label: InputLocalizable.firstNameLabel,
            placeholder: InputLocalizable.firstNamePlaceholder,
            modifier: modifier
        )
    }

    /// Last name input component
    @ViewBuilder
    func PrimerLastNameInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        StatefulInputField(
            scope: self,
            elementType: .lastName,
            label: InputLocalizable.lastNameLabel,
            placeholder: InputLocalizable.lastNamePlaceholder,
            modifier: modifier
        )
    }

    /// Retail outlet input component
    @ViewBuilder
    func PrimerRetailOutletInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        StatefulInputField(
            scope: self,
            elementType: .retailOutlet,
            label: InputLocalizable.retailOutletLabel,
            placeholder: InputLocalizable.retailOutletPlaceholder,
            modifier: modifier
        )
    }

    /// OTP code input component
    @ViewBuilder
    func PrimerOtpCodeInput(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        StatefulInputField(
            scope: self,
            elementType: .otpCode,
            label: InputLocalizable.otpCodeLabel,
            placeholder: InputLocalizable.otpCodePlaceholder,
            keyboardType: .numberPad,
            modifier: modifier
        )
    }

    /// Composite card details form (card number, cvv, expiry, cardholder name)
    @ViewBuilder
    func PrimerCardDetails(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        CardDetailsComposite(scope: self, modifier: modifier)
    }

    /// Composite billing address form (all address fields)
    @ViewBuilder
    func PrimerBillingAddress(
        modifier: PrimerModifier = PrimerModifier()
    ) -> some View {
        BillingAddressComposite(scope: self, modifier: modifier)
    }
    // swiftlint:enable identifier_name
}

// Note: State models are now defined in Models/States/ directory

// MARK: - Default Implementation (Temporary)

/// Temporary default implementation for testing
@available(iOS 15.0, *)
internal class DefaultCardFormScope: CardFormScope, LogReporter {

    @Published private var _state: CardFormState = .initial

    public func state() -> AsyncStream<CardFormState> {
        PublishedAsyncStream.create(from: self, keyPath: \._state)
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
            isSubmitEnabled: false,
            cardNetwork: _state.cardNetwork,
            cardFields: _state.cardFields,
            billingFields: _state.billingFields
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
            isSubmitEnabled: hasRequiredFields(updatedFields),
            cardNetwork: _state.cardNetwork,
            cardFields: _state.cardFields,
            billingFields: _state.billingFields
        )
    }

    private func hasRequiredFields(_ fields: [ComposableInputElementType: String]) -> Bool {
        // Check all required card fields are filled
        let hasAllCardFields = _state.cardFields.allSatisfy { fieldType in
            let value = fields[fieldType] ?? ""
            return !value.isEmpty
        }

        // Check all required billing fields are filled
        let hasAllBillingFields = _state.billingFields.allSatisfy { fieldType in
            let value = fields[fieldType] ?? ""
            return !value.isEmpty
        }

        return hasAllCardFields && hasAllBillingFields
    }
}

// MARK: - State Wrapper Views

// Wrapper view for PrimerInputField that manages state
@available(iOS 15.0, *)
private struct StatefulInputField: View {
    let scope: any CardFormScope
    let elementType: ComposableInputElementType
    let label: String
    let placeholder: String
    let keyboardType: UIKeyboardType
    let modifier: PrimerModifier
    @State private var value: String = ""

    init(
        scope: any CardFormScope,
        elementType: ComposableInputElementType,
        label: String,
        placeholder: String,
        keyboardType: UIKeyboardType = .default,
        modifier: PrimerModifier = PrimerModifier()
    ) {
        self.scope = scope
        self.elementType = elementType
        self.label = label
        self.placeholder = placeholder
        self.keyboardType = keyboardType
        self.modifier = modifier
    }

    var body: some View {
        PrimerInputField(
            value: value,
            onValueChange: { newValue in
                value = newValue
                updateScope(newValue)
            },
            labelText: label,
            placeholderText: placeholder,
            keyboardType: keyboardType
        )
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
        .task {
            for await state in scope.state() {
                if let fieldValue = state.inputFields[elementType] {
                    value = fieldValue
                }
            }
        }
    }

    private func updateScope(_ newValue: String) {
        switch elementType {
        case .postalCode:
            scope.updatePostalCode(newValue)
        case .countryCode:
            scope.updateCountryCode(newValue)
        case .city:
            scope.updateCity(newValue)
        case .state:
            scope.updateState(newValue)
        case .addressLine1:
            scope.updateAddressLine1(newValue)
        case .addressLine2:
            scope.updateAddressLine2(newValue)
        case .phoneNumber:
            scope.updatePhoneNumber(newValue)
        case .firstName:
            scope.updateFirstName(newValue)
        case .lastName:
            scope.updateLastName(newValue)
        case .retailOutlet:
            scope.updateRetailOutlet(newValue)
        case .otpCode:
            scope.updateOtpCode(newValue)
        default:
            break
        }
    }
}

// MARK: - Composite Component Implementations

// Helper composite view for card details
@available(iOS 15.0, *)
private struct CardDetailsComposite: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    @State private var visibleFields: Set<ComposableInputElementType> = []

    var body: some View {
        VStack(spacing: 16) {
            // Always show card number
            AnyView(scope.PrimerCardNumberInput())

            HStack(spacing: 12) {
                // Show expiry if required
                if visibleFields.contains(.expiryDate) {
                    AnyView(scope.PrimerExpiryDateInput())
                }

                // Show CVV if required
                if visibleFields.contains(.cvv) {
                    AnyView(scope.PrimerCvvInput())
                }
            }

            // Show cardholder name if required
            if visibleFields.contains(.cardholderName) {
                AnyView(scope.PrimerCardholderNameInput())
            }
        }
        .task {
            for await state in scope.state() {
                // Update visible fields based on state
                visibleFields = Set(state.cardFields)
            }
        }
        .applyPrimerModifier(modifier)
    }
}

// Helper composite view for billing address
@available(iOS 15.0, *)
private struct BillingAddressComposite: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    @State private var visibleFields: Set<ComposableInputElementType> = []

    var body: some View {
        VStack(spacing: 16) {
            Text(InputLocalizable.billingAddressTitle)
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            // Show fields based on configuration
            if visibleFields.contains(.addressLine1) {
                AnyView(scope.PrimerAddressLine1Input())
            }

            if visibleFields.contains(.addressLine2) {
                AnyView(scope.PrimerAddressLine2Input())
            }

            HStack(spacing: 12) {
                if visibleFields.contains(.city) {
                    AnyView(scope.PrimerCityInput())
                }

                if visibleFields.contains(.state) {
                    AnyView(scope.PrimerStateInput())
                }
            }

            HStack(spacing: 12) {
                if visibleFields.contains(.postalCode) {
                    AnyView(scope.PrimerPostalCodeInput())
                }

                if visibleFields.contains(.countryCode) {
                    AnyView(scope.PrimerCountryCodeInput())
                }
            }
        }
        .task {
            for await state in scope.state() {
                // Update visible fields based on state
                visibleFields = Set(state.billingFields)
            }
        }
        .applyPrimerModifier(modifier)
    }
}

// Helper view to bridge state for CVV input with card network
@available(iOS 15.0, *)
private struct CVVInputWithNetwork: View {
    let scope: any CardFormScope
    let modifier: PrimerModifier
    @State private var cardNetwork: CardNetwork = .unknown

    var body: some View {
        CVVInputField(
            label: InputLocalizable.cvvLabel,
            placeholder: InputLocalizable.cvvPlaceholder,
            cardNetwork: cardNetwork,
            onCvvChange: { newValue in
                scope.updateCvv(newValue)
            }
        )
        .task {
            for await state in scope.state() {
                if let network = state.cardNetwork {
                    cardNetwork = network
                }
            }
        }
        .applyPrimerModifier(modifier)
        .withPrimerEnvironment()
    }
}
