//
//  PrimerFormRedirectState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
public struct PrimerFormFieldState: Equatable, Identifiable {

    public enum FieldType: String, Equatable, Sendable {
        case otpCode
        case phoneNumber
    }

    public enum KeyboardType: Equatable, Sendable {
        case numberPad
        case phonePad
        case `default`
    }

    public let fieldType: FieldType
    public let placeholder: String
    public let label: String
    public let helperText: String?
    public let keyboardType: KeyboardType
    public let maxLength: Int?
    public internal(set) var value: String
    public internal(set) var isValid: Bool
    public internal(set) var errorMessage: String?
    public internal(set) var countryCodePrefix: String?
    public internal(set) var dialCode: String?

    public var id: String { fieldType.rawValue }

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

@available(iOS 15.0, *)
extension PrimerFormFieldState {

    static func blikOtpField() -> PrimerFormFieldState {
        PrimerFormFieldState(
            fieldType: .otpCode,
            placeholder: CheckoutComponentsStrings.blikOtpPlaceholder,
            label: CheckoutComponentsStrings.blikOtpLabel,
            helperText: CheckoutComponentsStrings.blikOtpHelper,
            maxLength: 6
        )
    }

    static func mbwayPhoneField(countryCodePrefix: String, dialCode: String) -> PrimerFormFieldState {
        PrimerFormFieldState(
            fieldType: .phoneNumber,
            placeholder: "",
            label: CheckoutComponentsStrings.phoneNumberLabel,
            countryCodePrefix: countryCodePrefix,
            dialCode: dialCode
        )
    }
}

/// Flow: `ready` -> `submitting` -> `awaitingExternalCompletion` -> `success` | `failure`
@available(iOS 15.0, *)
public struct PrimerFormRedirectState: Equatable {

    public enum Status: Equatable {
        case ready
        case submitting
        case awaitingExternalCompletion
        case success
        case failure(String)
    }

    public internal(set) var status: Status
    public internal(set) var fields: [PrimerFormFieldState]
    public internal(set) var pendingMessage: String?
    public internal(set) var surchargeAmount: String?

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

@available(iOS 15.0, *)
extension PrimerFormRedirectState {

    public var isSubmitEnabled: Bool {
        !fields.isEmpty && fields.allSatisfy(\.isValid)
    }

    public var otpField: PrimerFormFieldState? {
        fields.first { $0.fieldType == .otpCode }
    }

    public var phoneField: PrimerFormFieldState? {
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
