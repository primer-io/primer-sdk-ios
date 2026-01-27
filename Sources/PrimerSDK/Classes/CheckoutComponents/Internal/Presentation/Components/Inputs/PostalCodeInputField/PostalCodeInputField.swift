//
//  PostalCodeInputField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import UIKit

@available(iOS 15.0, *)
struct PostalCodeInputField: View, LogReporter {
  // MARK: - Public Properties

  let label: String?
  let placeholder: String
  let countryCode: String?
  let scope: any PrimerCardFormScope
  let styling: PrimerFieldStyling?

  // MARK: - Private Properties

  @Environment(\.diContainer) private var container
  @State private var validationService: ValidationService?
  @State private var postalCode: String = ""
  @State private var isValid: Bool = false
  @State private var errorMessage: String?
  @State private var isFocused: Bool = false
  @Environment(\.designTokens) private var tokens

  // MARK: - Computed Properties

  private var keyboardTypeForCountry: UIKeyboardType {
    if countryCode == "US" {
      return .numberPad
    }
    return .default
  }

  // MARK: - Initialization

  init(
    label: String?,
    placeholder: String,
    countryCode: String? = nil,
    scope: any PrimerCardFormScope,
    styling: PrimerFieldStyling? = nil
  ) {
    self.label = label
    self.placeholder = placeholder
    self.countryCode = countryCode
    self.scope = scope
    self.styling = styling
  }

  // MARK: - Body

  var body: some View {
    PrimerInputFieldContainer(
      label: label,
      styling: styling,
      text: $postalCode,
      isValid: $isValid,
      errorMessage: $errorMessage,
      isFocused: $isFocused
    ) {
      if let validationService = validationService {
        PostalCodeTextField(
          postalCode: $postalCode,
          isValid: $isValid,
          errorMessage: $errorMessage,
          isFocused: $isFocused,
          placeholder: placeholder,
          countryCode: countryCode,
          keyboardType: keyboardTypeForCountry,
          styling: styling,
          validationService: validationService,
          scope: scope,
          tokens: tokens
        )
      } else {
        // Fallback view while loading validation service
        TextField(placeholder, text: $postalCode)
          .keyboardType(keyboardTypeForCountry)
          .autocapitalization(.allCharacters)
          .disabled(true)
      }
    }
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.CardForm.billingAddressField("postal_code"),
        label: label ?? "Postal code",
        hint: CheckoutComponentsStrings.a11yBillingAddressPostalCodeHint,
        value: errorMessage,
        traits: []
      )
    )
    .onAppear {
      setupValidationService()
    }
  }

  private func setupValidationService() {
    guard let container = container else {
      logger.error(message: "DIContainer not available for PostalCodeInputField")
      return
    }

    do {
      validationService = try container.resolveSync(ValidationService.self)
    } catch {
      logger.error(message: "Failed to resolve ValidationService: \(error)")
    }
  }
}

#if DEBUG
  // MARK: - Preview
  @available(iOS 15.0, *)
  #Preview("Light Mode") {
    PostalCodeInputField(
      label: "Postal Code",
      placeholder: "Enter postal code",
      scope: MockCardFormScope()
    )
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }

  @available(iOS 15.0, *)
  #Preview("Dark Mode") {
    PostalCodeInputField(
      label: "Postal Code",
      placeholder: "Enter postal code",
      scope: MockCardFormScope()
    )
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
  }
#endif
