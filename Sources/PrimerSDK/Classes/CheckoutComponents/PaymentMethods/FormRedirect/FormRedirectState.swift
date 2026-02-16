//
//  FormRedirectState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Form Field State

@available(iOS 15.0, *)
public struct FormFieldState: Equatable, Identifiable {

    public enum FieldType: String, Equatable, Sendable {
        case otpCode
        case phoneNumber
    }

    public enum KeyboardType: Equatable, Sendable {
        case numberPad
        case phonePad
        case `default`
    }

    public var id: String { fieldType.rawValue }

    public let fieldType: FieldType
    public var value: String
    public var isValid: Bool
    public var errorMessage: String?

    /// Placeholder text (e.g., "000000")
    public let placeholder: String
    public let label: String
    public let helperText: String?
    public let keyboardType: KeyboardType

    /// nil means unlimited
    public let maxLength: Int?

    /// Display prefix for phone fields (e.g., "🇵🇹 +351")
    public var countryCodePrefix: String?

    /// Dial code for session info (e.g., "+351")
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
extension FormFieldState {

    static func blikOtpField() -> FormFieldState {
        FormFieldState(
            fieldType: .otpCode,
            value: "",
            isValid: false,
            placeholder: "000000",
            label: "6 digit code",
            helperText: "Open your banking app and generate a BLIK code.",
            keyboardType: .numberPad,
            maxLength: 6
        )
    }

    /// - Parameters:
    ///   - countryCodePrefix: Display prefix (e.g., "🇵🇹 +351")
    ///   - dialCode: Dial code for session info (e.g., "+351")
    static func mbwayPhoneField(countryCodePrefix: String, dialCode: String) -> FormFieldState {
        FormFieldState(
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

@available(iOS 15.0, *)
public struct FormRedirectState: Equatable {

    public enum Status: Equatable {
        case ready
        case submitting
        case awaitingExternalCompletion
        case success
        case failure(String)
    }

    public var status: Status
    public var fields: [FormFieldState]

    /// Derived from field validity: all fields must be non-empty and valid
    public var isSubmitEnabled: Bool {
        !fields.isEmpty && fields.allSatisfy(\.isValid)
    }

    public var pendingMessage: String?
    public var surchargeAmount: String?

    public init(
        status: Status = .ready,
        fields: [FormFieldState] = [],
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
extension FormRedirectState {

    public var otpField: FormFieldState? {
        fields.first { $0.fieldType == .otpCode }
    }

    public var phoneField: FormFieldState? {
        fields.first { $0.fieldType == .phoneNumber }
    }

    public var isLoading: Bool {
        status == .submitting
    }

    public var isTerminal: Bool {
        switch status {
        case .success, .failure:
            true
        default:
            false
        }
    }
}
