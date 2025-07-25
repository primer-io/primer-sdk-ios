//
//  StructuredCardFormState.swift
//  PrimerSDK - CheckoutComponents
//
//  Created for Android parity refactoring
//

import Foundation

// MARK: - Field Configuration

/// Defines which fields are required for the card form
/// Matches Android's dynamic field configuration approach
@available(iOS 15.0, *)
public struct CardFormConfiguration: Equatable {
    /// List of card-specific fields (card number, CVV, expiry, cardholder name)
    public let cardFields: [PrimerInputElementType]

    /// List of billing address fields (when billing address collection is enabled)
    public let billingFields: [PrimerInputElementType]

    /// Determines if billing address collection is required
    public let requiresBillingAddress: Bool

    /// Default card form configuration
    public static let `default` = CardFormConfiguration(
        cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
        billingFields: [],
        requiresBillingAddress: false
    )

    /// Configuration with billing address enabled
    public static let withBillingAddress = CardFormConfiguration(
        cardFields: [.cardNumber, .expiryDate, .cvv, .cardholderName],
        billingFields: [.countryCode, .addressLine1, .postalCode, .state, .firstName, .lastName],
        requiresBillingAddress: true
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

/// Represents a validation error for a specific field
/// Matches Android's SyncValidationError structure
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
/// Matches Android's Map<PrimerInputElementType, String> approach
@available(iOS 15.0, *)
public struct FormData: Equatable {
    private var data: [PrimerInputElementType: String] = [:]

    public init() {}

    public init(_ data: [PrimerInputElementType: String]) {
        self.data = data
    }

    /// Get value for a specific field type
    public subscript(fieldType: PrimerInputElementType) -> String {
        get { data[fieldType] ?? "" }
        set { data[fieldType] = newValue }
    }

    /// Get all data as dictionary
    public var dictionary: [PrimerInputElementType: String] {
        data
    }

    /// Check if field has non-empty value
    public func hasValue(for fieldType: PrimerInputElementType) -> Bool {
        !self[fieldType].isEmpty
    }

    /// Clear value for specific field
    public mutating func clearValue(for fieldType: PrimerInputElementType) {
        data[fieldType] = ""
    }

    /// Clear all values
    public mutating func clearAll() {
        data.removeAll()
    }

    /// Get values for specific field types
    public func values(for fieldTypes: [PrimerInputElementType]) -> [PrimerInputElementType: String] {
        fieldTypes.reduce(into: [:]) { result, fieldType in
            result[fieldType] = self[fieldType]
        }
    }
}

// MARK: - Country Information

/// Enhanced country information to match Android's PrimerCountry
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

// MARK: - New Structured State

/// Structured card form state matching Android's approach
/// This is now the primary state structure for card forms
@available(iOS 15.0, *)
public struct StructuredCardFormState: Equatable {

    // MARK: - Core Configuration

    /// Dynamic field configuration (replaces hardcoded fields)
    public var configuration: CardFormConfiguration

    /// Type-safe form data map (replaces individual String properties)
    public var data: FormData

    /// Field-specific validation errors (replaces single error string)
    public var fieldErrors: [FieldError]

    // MARK: - Loading and Validation States

    /// Indicates if form is being submitted
    public var isLoading: Bool

    /// Overall form validation state
    public var isValid: Bool

    // MARK: - Selection States

    /// Currently selected country for billing address
    public var selectedCountry: PrimerCountry?

    /// Currently selected card network (for co-badged cards)
    public var selectedNetwork: PrimerCardNetwork?

    /// Available card networks detected from card number
    public var availableNetworks: [PrimerCardNetwork]

    // MARK: - Additional Information

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
        self.surchargeAmount = surchargeAmount
    }

    // MARK: - Convenience Properties

    /// All fields that should be displayed (card + billing if enabled)
    public var displayFields: [PrimerInputElementType] {
        configuration.allFields
    }

    /// Check if specific field has an error
    public func hasError(for fieldType: PrimerInputElementType) -> Bool {
        fieldErrors.contains { $0.fieldType == fieldType }
    }

    /// Get error message for specific field
    public func errorMessage(for fieldType: PrimerInputElementType) -> String? {
        fieldErrors.first { $0.fieldType == fieldType }?.message
    }

    /// Add or update error for specific field
    public mutating func setError(_ message: String, for fieldType: PrimerInputElementType, errorCode: String? = nil) {
        // Remove existing error for this field
        fieldErrors.removeAll { $0.fieldType == fieldType }
        // Add new error
        fieldErrors.append(FieldError(fieldType: fieldType, message: message, errorCode: errorCode))
    }

    /// Clear error for specific field
    public mutating func clearError(for fieldType: PrimerInputElementType) {
        fieldErrors.removeAll { $0.fieldType == fieldType }
    }

    /// Clear all errors
    public mutating func clearAllErrors() {
        fieldErrors.removeAll()
    }

    /// Check if co-badged card selection is needed
    public var needsNetworkSelection: Bool {
        availableNetworks.count > 1 && selectedNetwork == nil
    }
}
