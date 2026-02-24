//
//  PrimerFormRedirectState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Form Field State

/// Represents the state of a single form field in a form redirect payment method.
///
/// Each field has a type (OTP code or phone number), a current value, validation state,
/// and display metadata (label, placeholder, helper text).
@available(iOS 15.0, *)
public struct PrimerFormFieldState: Equatable, Identifiable {

    /// The type of form field.
    public enum FieldType: String, Equatable, Sendable {
        /// OTP code field (e.g., BLIK 6-digit code).
        case otpCode
        /// Phone number field (e.g., MBWay phone number).
        case phoneNumber
    }

    /// The keyboard type to display for this field.
    public enum KeyboardType: Equatable, Sendable {
        /// Numeric keypad (digits only).
        case numberPad
        /// Phone-style keypad with + and #.
        case phonePad
        /// Standard keyboard.
        case `default`
    }

    /// Unique identifier derived from the field type.
    public var id: String { fieldType.rawValue }

    /// The type of this form field.
    public let fieldType: FieldType

    /// The current text value entered by the user.
    public var value: String

    /// Whether the current value passes validation.
    public var isValid: Bool

    /// Validation error message, if the field is invalid.
    public var errorMessage: String?

    /// Placeholder text (e.g., "000000").
    public let placeholder: String

    /// Display label for the field.
    public let label: String

    /// Optional helper text displayed below the field.
    public let helperText: String?

    /// The keyboard type to use for input.
    public let keyboardType: KeyboardType

    /// Maximum character length, or `nil` for unlimited.
    public let maxLength: Int?

    /// Display prefix for phone fields (e.g., "🇵🇹 +351").
    public var countryCodePrefix: String?

    /// Dial code for session info (e.g., "+351").
    public var dialCode: String?

    public init(
        fieldType: FieldType,
        value: String = "",
        isValid: Bool = false,
        errorMessage: String? = nil,
        placeholder: String,
        label: String,
        helperText: String? = nil,
        keyboardType: KeyboardType = .numberPad,
        maxLength: Int? = nil,
        countryCodePrefix: String? = nil,
        dialCode: String? = nil
    ) {
        self.fieldType = fieldType
        self.value = value
        self.isValid = isValid
        self.errorMessage = errorMessage
        self.placeholder = placeholder
        self.label = label
        self.helperText = helperText
        self.keyboardType = keyboardType
        self.maxLength = maxLength
        self.countryCodePrefix = countryCodePrefix
        self.dialCode = dialCode
    }
}

// MARK: - Factory Methods

@available(iOS 15.0, *)
extension PrimerFormFieldState {

    static func blikOtpField() -> PrimerFormFieldState {
        PrimerFormFieldState(
            fieldType: .otpCode,
            value: "",
            isValid: false,
            placeholder: CheckoutComponentsStrings.blikOtpPlaceholder,
            label: CheckoutComponentsStrings.blikOtpLabel,
            helperText: CheckoutComponentsStrings.blikOtpHelper,
            keyboardType: .numberPad,
            maxLength: 6
        )
    }

    /// - Parameters:
    ///   - countryCodePrefix: Display prefix (e.g., "🇵🇹 +351")
    ///   - dialCode: Dial code for session info (e.g., "+351")
    static func mbwayPhoneField(countryCodePrefix: String, dialCode: String) -> PrimerFormFieldState {
        PrimerFormFieldState(
            fieldType: .phoneNumber,
            value: "",
            isValid: false,
            placeholder: "",
            label: CheckoutComponentsStrings.phoneNumberLabel,
            helperText: nil,
            keyboardType: .numberPad,
            maxLength: nil,
            countryCodePrefix: countryCodePrefix,
            dialCode: dialCode
        )
    }
}

// MARK: - Form Redirect State

/// State for form-based redirect payment methods (e.g., BLIK, MBWay).
///
/// Tracks the form fields, validation, and payment lifecycle from form entry through
/// external completion to a terminal result.
///
/// ## Flow
/// ```
/// ready → submitting → awaitingExternalCompletion → success | failure
/// ```
@available(iOS 15.0, *)
public struct PrimerFormRedirectState: Equatable {

    /// The current status of the form redirect payment flow.
    public enum Status: Equatable {
        /// Form is ready for user input.
        case ready
        /// Payment is being submitted (tokenization in progress).
        case submitting
        /// Waiting for the user to complete payment in an external app.
        case awaitingExternalCompletion
        /// Payment completed successfully.
        case success
        /// Payment failed with the given error message.
        case failure(String)
    }

    /// Current payment status.
    public var status: Status

    /// The form fields for this payment method.
    public var fields: [PrimerFormFieldState]

    /// Whether all fields are valid and the form can be submitted.
    /// Derived from field validity: all fields must be non-empty and valid.
    public var isSubmitEnabled: Bool {
        !fields.isEmpty && fields.allSatisfy(\.isValid)
    }

    /// Message to display while awaiting external completion (e.g., "Confirm payment in your banking app").
    public var pendingMessage: String?

    /// Formatted surcharge amount for this payment method, if applicable.
    public var surchargeAmount: String?

    public init(
        status: Status = .ready,
        fields: [PrimerFormFieldState] = [],
        pendingMessage: String? = nil,
        surchargeAmount: String? = nil
    ) {
        self.status = status
        self.fields = fields
        self.pendingMessage = pendingMessage
        self.surchargeAmount = surchargeAmount
    }
}

// MARK: - Convenience Accessors

@available(iOS 15.0, *)
extension PrimerFormRedirectState {

    /// The OTP code field, if present (used by BLIK).
    public var otpField: PrimerFormFieldState? {
        fields.first { $0.fieldType == .otpCode }
    }

    /// The phone number field, if present (used by MBWay).
    public var phoneField: PrimerFormFieldState? {
        fields.first { $0.fieldType == .phoneNumber }
    }

    /// Whether the payment is currently being submitted.
    public var isLoading: Bool {
        status == .submitting
    }

    /// Whether the payment has reached a terminal state (success or failure).
    public var isTerminal: Bool {
        switch status {
        case .success, .failure:
            true
        default:
            false
        }
    }
}
