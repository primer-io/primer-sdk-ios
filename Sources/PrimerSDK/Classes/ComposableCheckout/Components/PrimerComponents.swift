//
//  PrimerComponents.swift
//
//
//  Created on 18.06.2025.
//

import SwiftUI
import Combine

/// Direct component access functions that match Android's top-level component API.
/// These provide an alternative to scope-based access for easier migration from Android.
@available(iOS 15.0, *)
public struct PrimerComponents {

    // MARK: - Card Form Components

    // swiftlint:disable identifier_name
    // Note: Function names intentionally use uppercase to match Android's API exactly

    /// Card number input component with direct access
    /// Matches Android's @Composable fun PrimerCardNumberInput(modifier: Modifier)
    @ViewBuilder
    public static func PrimerCardNumberInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        CardNumberDirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// CVV input component with direct access
    /// Matches Android's @Composable fun PrimerCvvInput(modifier: Modifier)
    @ViewBuilder
    public static func PrimerCvvInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        CVVDirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// Expiry date input component with direct access
    /// Matches Android's @Composable fun PrimerExpiryDateInput(modifier: Modifier)
    @ViewBuilder
    public static func PrimerExpiryDateInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        ExpiryDateDirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// Cardholder name input component with direct access
    /// Matches Android's @Composable fun PrimerCardholderNameInput(modifier: Modifier)
    @ViewBuilder
    public static func PrimerCardholderNameInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        CardholderNameDirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// Submit button component with direct access
    /// Matches Android's @Composable fun PrimerSubmitButton(modifier: Modifier, text: String, enabled: Boolean, onClick: () -> Unit)
    @ViewBuilder
    public static func PrimerSubmitButton(
        modifier: PrimerModifier = PrimerModifier(),
        text: String = "Submit",
        enabled: Bool = true,
        loading: Bool = false,
        onClick: (() -> Void)? = nil
    ) -> some View {
        SubmitButtonDirect(
            modifier: modifier,
            text: text,
            enabled: enabled,
            loading: loading,
            onClick: onClick
        )
    }

    // MARK: - Composite Components

    /// Complete card details form with direct access
    /// Matches Android's @Composable fun PrimerCardDetails(modifier: Modifier)
    @ViewBuilder
    public static func PrimerCardDetails(
        modifier: PrimerModifier = PrimerModifier(),
        onCardNumberChange: ((String) -> Void)? = nil,
        onCvvChange: ((String) -> Void)? = nil,
        onExpiryDateChange: ((String) -> Void)? = nil,
        onCardholderNameChange: ((String) -> Void)? = nil
    ) -> some View {
        CardDetailsFormDirect(
            modifier: modifier,
            onCardNumberChange: onCardNumberChange,
            onCvvChange: onCvvChange,
            onExpiryDateChange: onExpiryDateChange,
            onCardholderNameChange: onCardholderNameChange
        )
    }

    // MARK: - Address Components

    /// Postal code input component with direct access
    @ViewBuilder
    public static func PrimerPostalCodeInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        PostalCodeDirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// Country code input component with direct access
    @ViewBuilder
    public static func PrimerCountryCodeInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        CountryCodeDirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// City input component with direct access
    @ViewBuilder
    public static func PrimerCityInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        CityDirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// State input component with direct access
    @ViewBuilder
    public static func PrimerStateInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        StateDirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// Address line 1 input component with direct access
    @ViewBuilder
    public static func PrimerAddressLine1Input(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        AddressLine1DirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// Address line 2 input component with direct access
    @ViewBuilder
    public static func PrimerAddressLine2Input(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        AddressLine2DirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// Phone number input component with direct access
    @ViewBuilder
    public static func PrimerPhoneNumberInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        PhoneNumberDirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// First name input component with direct access
    @ViewBuilder
    public static func PrimerFirstNameInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        FirstNameDirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// Last name input component with direct access
    @ViewBuilder
    public static func PrimerLastNameInput(
        modifier: PrimerModifier = PrimerModifier(),
        label: String? = nil,
        placeholder: String? = nil,
        onValueChange: ((String) -> Void)? = nil
    ) -> some View {
        LastNameDirectInput(
            modifier: modifier,
            label: label,
            placeholder: placeholder,
            onValueChange: onValueChange
        )
    }

    /// Complete billing address form with direct access
    /// Matches Android's @Composable fun PrimerBillingAddress(modifier: Modifier)
    @ViewBuilder
    public static func PrimerBillingAddress(
        modifier: PrimerModifier = PrimerModifier(),
        onAddressChange: ((PrimerBillingAddress) -> Void)? = nil
    ) -> some View {
        BillingAddressFormDirect(
            modifier: modifier,
            onAddressChange: onAddressChange
        )
    }

    // MARK: - Payment Method Components

    /// Payment method item component with direct access
    /// Matches Android's @Composable fun PrimerPaymentMethodItem(modifier: Modifier, paymentMethod: PaymentMethod)
    @ViewBuilder
    public static func PrimerPaymentMethodItem(
        modifier: PrimerModifier = PrimerModifier(),
        paymentMethod: PrimerComposablePaymentMethod,
        currency: ComposableCurrency? = nil,
        onSelect: (() -> Void)? = nil
    ) -> some View {
        PaymentMethodItemDirect(
            modifier: modifier,
            paymentMethod: paymentMethod,
            currency: currency,
            onSelect: onSelect
        )
    }

    /// Payment method selection screen with direct access
    /// Matches Android's @Composable fun PrimerPaymentMethodSelection(modifier: Modifier)
    @ViewBuilder
    public static func PrimerPaymentMethodSelection(
        modifier: PrimerModifier = PrimerModifier(),
        paymentMethods: [PrimerComposablePaymentMethod] = [],
        currency: ComposableCurrency? = nil,
        onPaymentMethodSelected: ((PrimerComposablePaymentMethod) -> Void)? = nil
    ) -> some View {
        PaymentMethodSelectionDirect(
            modifier: modifier,
            paymentMethods: paymentMethods,
            currency: currency,
            onPaymentMethodSelected: onPaymentMethodSelected
        )
    }
}

// MARK: - Supporting Data Models

@available(iOS 15.0, *)
public struct PrimerBillingAddress {
    public let addressLine1: String?
    public let addressLine2: String?
    public let city: String?
    public let state: String?
    public let postalCode: String?
    public let countryCode: String?

    public init(
        addressLine1: String? = nil,
        addressLine2: String? = nil,
        city: String? = nil,
        state: String? = nil,
        postalCode: String? = nil,
        countryCode: String? = nil
    ) {
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.city = city
        self.state = state
        self.postalCode = postalCode
        self.countryCode = countryCode
    }
}

// MARK: - Direct Component Implementations

// These are temporary implementations that will be updated to use the modifier system

@available(iOS 15.0, *)
internal struct CardNumberDirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "Card Number", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct CVVDirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            SecureField(placeholder ?? "CVV", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct ExpiryDateDirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "MM/YY", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .keyboardType(.numberPad)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct CardholderNameDirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "Cardholder Name", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.name)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct SubmitButtonDirect: View {
    let modifier: PrimerModifier
    let text: String
    let enabled: Bool
    let loading: Bool
    let onClick: (() -> Void)?

    var body: some View {
        Button(action: {
            onClick?()
        }) {
            HStack {
                if loading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(0.8)
                }

                Text(text)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(enabled ? Color.blue : Color.gray)
            .cornerRadius(8)
        }
        .disabled(!enabled || loading)
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct CardDetailsFormDirect: View {
    let modifier: PrimerModifier
    let onCardNumberChange: ((String) -> Void)?
    let onCvvChange: ((String) -> Void)?
    let onExpiryDateChange: ((String) -> Void)?
    let onCardholderNameChange: ((String) -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            PrimerComponents.PrimerCardNumberInput(
                label: "Card Number",
                onValueChange: onCardNumberChange
            )

            HStack(spacing: 12) {
                PrimerComponents.PrimerExpiryDateInput(
                    label: "Expiry Date",
                    onValueChange: onExpiryDateChange
                )

                PrimerComponents.PrimerCvvInput(
                    label: "CVV",
                    onValueChange: onCvvChange
                )
            }

            PrimerComponents.PrimerCardholderNameInput(
                label: "Cardholder Name",
                onValueChange: onCardholderNameChange
            )
        }
        .primerModifier(modifier)
    }
}

// MARK: - Additional Direct Input Components (Simplified implementations)

@available(iOS 15.0, *)
internal struct PostalCodeDirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "Postal Code", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.postalCode)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct CountryCodeDirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "Country Code", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.countryName)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct CityDirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "City", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.addressCity)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct StateDirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "State", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.addressState)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct AddressLine1DirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "Address Line 1", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.streetAddressLine1)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct AddressLine2DirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "Address Line 2", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.streetAddressLine2)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct PhoneNumberDirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "Phone Number", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.telephoneNumber)
                .keyboardType(.phonePad)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct FirstNameDirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "First Name", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.givenName)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct LastNameDirectInput: View {
    let modifier: PrimerModifier
    let label: String?
    let placeholder: String?
    let onValueChange: ((String) -> Void)?

    @State private var value: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if let label = label {
                Text(label)
                    .font(.subheadline)
                    .foregroundColor(.primary)
            }

            TextField(placeholder ?? "Last Name", text: $value)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .textContentType(.familyName)
                .onChange(of: value) { newValue in
                    onValueChange?(newValue)
                }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct BillingAddressFormDirect: View {
    let modifier: PrimerModifier
    let onAddressChange: ((PrimerBillingAddress) -> Void)?

    @State private var addressData = PrimerBillingAddress()

    var body: some View {
        VStack(spacing: 16) {
            Text("Billing Address")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)

            PrimerComponents.PrimerAddressLine1Input(
                label: "Address Line 1",
                onValueChange: { value in
                    addressData = PrimerBillingAddress(
                        addressLine1: value,
                        addressLine2: addressData.addressLine2,
                        city: addressData.city,
                        state: addressData.state,
                        postalCode: addressData.postalCode,
                        countryCode: addressData.countryCode
                    )
                    onAddressChange?(addressData)
                }
            )

            PrimerComponents.PrimerAddressLine2Input(
                label: "Address Line 2 (Optional)",
                onValueChange: { value in
                    addressData = PrimerBillingAddress(
                        addressLine1: addressData.addressLine1,
                        addressLine2: value,
                        city: addressData.city,
                        state: addressData.state,
                        postalCode: addressData.postalCode,
                        countryCode: addressData.countryCode
                    )
                    onAddressChange?(addressData)
                }
            )

            HStack(spacing: 12) {
                PrimerComponents.PrimerCityInput(
                    label: "City",
                    onValueChange: { value in
                        addressData = PrimerBillingAddress(
                            addressLine1: addressData.addressLine1,
                            addressLine2: addressData.addressLine2,
                            city: value,
                            state: addressData.state,
                            postalCode: addressData.postalCode,
                            countryCode: addressData.countryCode
                        )
                        onAddressChange?(addressData)
                    }
                )

                PrimerComponents.PrimerStateInput(
                    label: "State",
                    onValueChange: { value in
                        addressData = PrimerBillingAddress(
                            addressLine1: addressData.addressLine1,
                            addressLine2: addressData.addressLine2,
                            city: addressData.city,
                            state: value,
                            postalCode: addressData.postalCode,
                            countryCode: addressData.countryCode
                        )
                        onAddressChange?(addressData)
                    }
                )
            }

            HStack(spacing: 12) {
                PrimerComponents.PrimerPostalCodeInput(
                    label: "Postal Code",
                    onValueChange: { value in
                        addressData = PrimerBillingAddress(
                            addressLine1: addressData.addressLine1,
                            addressLine2: addressData.addressLine2,
                            city: addressData.city,
                            state: addressData.state,
                            postalCode: value,
                            countryCode: addressData.countryCode
                        )
                        onAddressChange?(addressData)
                    }
                )

                PrimerComponents.PrimerCountryCodeInput(
                    label: "Country",
                    onValueChange: { value in
                        addressData = PrimerBillingAddress(
                            addressLine1: addressData.addressLine1,
                            addressLine2: addressData.addressLine2,
                            city: addressData.city,
                            state: addressData.state,
                            postalCode: addressData.postalCode,
                            countryCode: value
                        )
                        onAddressChange?(addressData)
                    }
                )
            }
        }
        .primerModifier(modifier)
    }
}

@available(iOS 15.0, *)
internal struct PaymentMethodItemDirect: View {
    let modifier: PrimerModifier
    let paymentMethod: PrimerComposablePaymentMethod
    let currency: ComposableCurrency?
    let onSelect: (() -> Void)?

    var body: some View {
        Button(action: {
            onSelect?()
        }) {
            HStack {
                Image(systemName: iconForPaymentMethod(paymentMethod.paymentMethodType))
                    .font(.title2)
                    .foregroundColor(.blue)

                VStack(alignment: .leading, spacing: 4) {
                    Text(paymentMethod.paymentMethodName ?? paymentMethod.paymentMethodType)
                        .font(.headline)
                        .foregroundColor(.primary)

                    if let surcharge = paymentMethod.surcharge {
                        Text("+ \(surcharge.amount) \(currency?.code ?? "")")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
            .background(Color(.systemBackground))
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(PlainButtonStyle())
        .primerModifier(modifier)
    }

    private func iconForPaymentMethod(_ type: String) -> String {
        switch type {
        case "PAYMENT_CARD":
            return "creditcard.fill"
        case "APPLE_PAY":
            return "applelogo"
        case "PAYPAL":
            return "p.circle.fill"
        default:
            return "creditcard"
        }
    }
}

@available(iOS 15.0, *)
internal struct PaymentMethodSelectionDirect: View {
    let modifier: PrimerModifier
    let paymentMethods: [PrimerComposablePaymentMethod]
    let currency: ComposableCurrency?
    let onPaymentMethodSelected: ((PrimerComposablePaymentMethod) -> Void)?

    var body: some View {
        VStack(spacing: 16) {
            Text("Select Payment Method")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)

            LazyVStack(spacing: 12) {
                ForEach(paymentMethods, id: \.paymentMethodType) { method in
                    PrimerComponents.PrimerPaymentMethodItem(
                        paymentMethod: method,
                        currency: currency,
                        onSelect: {
                            onPaymentMethodSelected?(method)
                        }
                    )
                }
            }
        }
        .primerModifier(modifier)
    }

    // swiftlint:enable identifier_name
}
