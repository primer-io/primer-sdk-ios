//
//  CityInputField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct CityInputField: View, LogReporter {
  // MARK: - Public Properties

  let label: String?
  let placeholder: String
  let scope: any PrimerCardFormScope
  let styling: PrimerFieldStyling?

  // MARK: - Private Properties

  @Environment(\.diContainer) private var container
  @State private var validationService: ValidationService?
  @State private var city: String = ""
  @State private var isValid: Bool = false
  @State private var errorMessage: String?
  @State private var isFocused: Bool = false
  @Environment(\.designTokens) private var tokens

  // MARK: - Initialization

  init(
    label: String?,
    placeholder: String,
    scope: any PrimerCardFormScope,
    styling: PrimerFieldStyling? = nil
  ) {
    self.label = label
    self.placeholder = placeholder
    self.scope = scope
    self.styling = styling
  }

  // MARK: - Body

  var body: some View {
    PrimerInputFieldContainer(
      label: label,
      styling: styling,
      text: $city,
      isValid: $isValid,
      errorMessage: $errorMessage,
      isFocused: $isFocused
    ) {
      if let validationService = validationService {
        CityTextField(
          city: $city,
          isValid: $isValid,
          errorMessage: $errorMessage,
          isFocused: $isFocused,
          placeholder: placeholder,
          styling: styling,
          validationService: validationService,
          scope: scope,
          tokens: tokens
        )
      } else {
        // Fallback view while loading validation service
        TextField(placeholder, text: $city)
          .autocapitalization(.words)
          .disabled(true)
      }
    }
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.CardForm.billingAddressField("city"),
        label: label ?? "City",
        hint: CheckoutComponentsStrings.a11yBillingAddressCityHint,
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
      logger.error(message: "DIContainer not available for CityInputField")
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
    CityInputField(
      label: "City",
      placeholder: "Enter city",
      scope: MockCardFormScope()
    )
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }

  @available(iOS 15.0, *)
  #Preview("Dark Mode") {
    CityInputField(
      label: "City",
      placeholder: "Enter city",
      scope: MockCardFormScope()
    )
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
  }
#endif
