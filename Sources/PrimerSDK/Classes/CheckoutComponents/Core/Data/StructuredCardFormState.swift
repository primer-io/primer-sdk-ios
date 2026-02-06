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

/// Represents a validation error for a specific form field.
///
/// `FieldError` provides detailed error information for individual fields,
/// allowing you to display targeted error messages and programmatically
/// handle validation failures.
///
/// Example usage:
/// ```swift
/// for error in formState.fieldErrors {
///     print("Field \(error.fieldType.displayName): \(error.message)")
///     if let code = error.errorCode {
///         handleErrorCode(code)
///     }
/// }
/// ```
@available(iOS 15.0, *)
public struct FieldError: Equatable, Identifiable {
  /// Unique identifier for this error instance.
  public let id = UUID()

  /// The type of field that has the error.
  public let fieldType: PrimerInputElementType

  /// Human-readable error message to display to the user.
  public let message: String

  /// Machine-readable error code for programmatic handling.
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

/// Represents a country for billing address and locale selection.
///
/// `PrimerCountry` provides country information including the ISO code,
/// display name, flag emoji, and dial code for phone number formatting.
///
/// Example usage:
/// ```swift
/// if let country = formState.selectedCountry {
///     print("Selected: \(country.flag ?? "") \(country.name) (\(country.code))")
/// }
/// ```
@available(iOS 15.0, *)
public struct PrimerCountry: Equatable, Identifiable {
  /// Unique identifier for this country instance.
  public let id = UUID()

  /// ISO 3166-1 alpha-2 country code (e.g., "US", "GB", "DE").
  public let code: String

  /// Localized country name for display.
  public let name: String

  /// Flag emoji for the country (e.g., "🇺🇸").
  public let flag: String?

  /// International dialing code (e.g., "+1" for US).
  public let dialCode: String?

  public init(code: String, name: String, flag: String? = nil, dialCode: String? = nil) {
    self.code = code
    self.name = name
    self.flag = flag
    self.dialCode = dialCode
  }
}

// MARK: - Structured State

/// The complete state of the card payment form including field values, validation, and network selection.
///
/// `StructuredCardFormState` provides a comprehensive view of the card form's current state,
/// including:
/// - Form configuration (which fields are required)
/// - Current field values
/// - Validation errors
/// - Loading and validity states
/// - Co-badged card network information
/// - Surcharge amounts
///
/// Observe this state through `PrimerCardFormScope.state` to react to form changes:
/// ```swift
/// for await state in cardFormScope.state {
///     // Check overall form validity
///     submitButton.isEnabled = state.isValid
///
///     // Display field-specific errors
///     for error in state.fieldErrors {
///         showError(error.message, for: error.fieldType)
///     }
///
///     // Handle co-badged cards
///     if state.availableNetworks.count > 1 {
///         showNetworkSelector(state.availableNetworks)
///     }
///
///     // Show surcharge if applicable
///     if let surcharge = state.surchargeAmount {
///         showSurchargeLabel(surcharge)
///     }
/// }
/// ```
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

  // MARK: - BIN Data

  /// Enriched BIN data including issuer info, first digits, and status
  public var binData: PrimerBinData?

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
    surchargeAmount: String? = nil,
    binData: PrimerBinData? = nil
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
    self.binData = binData
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

  public mutating func setError(
    _ message: String, for fieldType: PrimerInputElementType, errorCode: String? = nil
  ) {
    fieldErrors.removeAll { $0.fieldType == fieldType }
    fieldErrors.append(FieldError(fieldType: fieldType, message: message, errorCode: errorCode))
  }

  public mutating func clearError(for fieldType: PrimerInputElementType) {
    fieldErrors.removeAll { $0.fieldType == fieldType }
  }
}
