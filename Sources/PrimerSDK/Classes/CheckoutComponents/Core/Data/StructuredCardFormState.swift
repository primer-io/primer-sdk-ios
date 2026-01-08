//
//  StructuredCardFormState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

// MARK: - Field Configuration

/// Defines which fields are required for the card form
@available(iOS 15.0, *)
public struct CardFormConfiguration: Equatable {
    /// List of card-specific fields (card number, CVV, expiry, cardholder name)
    public let cardFields: [PrimerInputElementType]

    /// List of billing address fields (when billing address collection is enabled)
    public let billingFields: [PrimerInputElementType]

    public let requiresBillingAddress: Bool

    public static let `default` = CardFormConfiguration(
        cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
        billingFields: [],
        requiresBillingAddress: false
    )

    public init(
        cardFields: [PrimerInputElementType],
        billingFields: [PrimerInputElementType] = [],
        requiresBillingAddress: Bool = false
    ) {
        self.cardFields = cardFields
        self.billingFields = billingFields
        self.requiresBillingAddress = requiresBillingAddress
    }

    /// All fields combined (card + billing)
    public var allFields: [PrimerInputElementType] {
        cardFields + billingFields
    }
}

// MARK: - Field Error

@available(iOS 15.0, *)
public struct FieldError: Equatable, Identifiable {
    public let id = UUID()
    public let fieldType: PrimerInputElementType
    public let message: String
    public let errorCode: String?

    public init(
        fieldType: PrimerInputElementType,
        message: String,
        errorCode: String? = nil
    ) {
        self.fieldType = fieldType
        self.message = message
        self.errorCode = errorCode
    }
}

// MARK: - Form Data

/// Type-safe container for form field data
@available(iOS 15.0, *)
public struct FormData: Equatable {
    private var data: [PrimerInputElementType: String] = [:]

    public init() {}

    public init(_ data: [PrimerInputElementType: String]) {
        self.data = data
    }

    public subscript(fieldType: PrimerInputElementType) -> String {
        get { data[fieldType] ?? "" }
        set { data[fieldType] = newValue }
    }

    public var dictionary: [PrimerInputElementType: String] {
        data
    }
}

// MARK: - Country Information

@available(iOS 15.0, *)
public struct PrimerCountry: Equatable, Identifiable {
    public let id = UUID()
    public let code: String
    public let name: String
    public let flag: String?
    public let dialCode: String?

    public init(code: String, name: String, flag: String? = nil, dialCode: String? = nil) {
        self.code = code
        self.name = name
        self.flag = flag
        self.dialCode = dialCode
    }
}

// MARK: - Structured State

@available(iOS 15.0, *)
public struct StructuredCardFormState: Equatable {

    // MARK: - Core Configuration

    /// Dynamic field configuration
    public var configuration: CardFormConfiguration

    /// Type-safe form data map
    public var data: FormData

    /// Field-specific validation errors
    public var fieldErrors: [FieldError]

    // MARK: - Loading and Validation States

    public var isLoading: Bool

    public var isValid: Bool

    // MARK: - Selection States

    public var selectedCountry: PrimerCountry?

    /// Currently selected card network (for co-badged cards)
    public var selectedNetwork: PrimerCardNetwork?

    /// Available card networks detected from card number
    public var availableNetworks: [PrimerCardNetwork]

    // MARK: - Additional Information

    /// Surcharge amount in smallest currency unit (e.g., cents)
    public var surchargeAmountRaw: Int?

    /// Surcharge amount to display (formatted string)
    public var surchargeAmount: String?

    // MARK: - Initialization

    public init(
        configuration: CardFormConfiguration = .default,
        data: FormData = FormData(),
        fieldErrors: [FieldError] = [],
        isLoading: Bool = false,
        isValid: Bool = false,
        selectedCountry: PrimerCountry? = nil,
        selectedNetwork: PrimerCardNetwork? = nil,
        availableNetworks: [PrimerCardNetwork] = [],
        surchargeAmountRaw: Int? = nil,
        surchargeAmount: String? = nil
    ) {
        self.configuration = configuration
        self.data = data
        self.fieldErrors = fieldErrors
        self.isLoading = isLoading
        self.isValid = isValid
        self.selectedCountry = selectedCountry
        self.selectedNetwork = selectedNetwork
        self.availableNetworks = availableNetworks
        self.surchargeAmountRaw = surchargeAmountRaw
        self.surchargeAmount = surchargeAmount
    }

    // MARK: - Convenience Properties

    /// All fields that should be displayed (card + billing if enabled)
    public var displayFields: [PrimerInputElementType] {
        configuration.allFields
    }

    public func hasError(for fieldType: PrimerInputElementType) -> Bool {
        fieldErrors.contains { $0.fieldType == fieldType }
    }

    public func errorMessage(for fieldType: PrimerInputElementType) -> String? {
        fieldErrors.first { $0.fieldType == fieldType }?.message
    }

    public mutating func setError(_ message: String, for fieldType: PrimerInputElementType, errorCode: String? = nil) {
        fieldErrors.removeAll { $0.fieldType == fieldType }
        fieldErrors.append(FieldError(fieldType: fieldType, message: message, errorCode: errorCode))
    }

    public mutating func clearError(for fieldType: PrimerInputElementType) {
        fieldErrors.removeAll { $0.fieldType == fieldType }
    }
}
