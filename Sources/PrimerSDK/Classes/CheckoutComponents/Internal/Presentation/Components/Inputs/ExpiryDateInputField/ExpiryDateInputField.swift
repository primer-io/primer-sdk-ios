//
//  ExpiryDateInputField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct ExpiryDateInputField: View, LogReporter {
  // MARK: - Public Properties

  let label: String?
  let placeholder: String
  let scope: any PrimerCardFormScope
  let styling: PrimerFieldStyling?

  // MARK: - Private Properties

  @Environment(\.diContainer) private var container
  @State private var validationService: ValidationService?
  @State private var expiryDate: String = ""
  @State private var month: String = ""
  @State private var year: String = ""
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
      text: $expiryDate,
      isValid: $isValid,
      errorMessage: $errorMessage,
      isFocused: $isFocused
    ) {
      if let validationService = validationService {
        ExpiryDateTextField(
          expiryDate: $expiryDate,
          month: $month,
          year: $year,
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
        TextField(placeholder, text: $expiryDate)
          .keyboardType(.numberPad)
          .disabled(true)
      }
    }
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.CardForm.expiryField,
        label: CheckoutComponentsStrings.a11yExpiryLabel,
        hint: CheckoutComponentsStrings.a11yExpiryHint,
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
      logger.error(message: "DIContainer not available for ExpiryDateInputField")
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
    ExpiryDateInputField(
      label: "Expiry Date",
      placeholder: "MM / YY",
      scope: MockCardFormScope()
    )
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }

  @available(iOS 15.0, *)
  #Preview("Dark Mode") {
    ExpiryDateInputField(
      label: "Expiry Date",
      placeholder: "MM / YY",
      scope: MockCardFormScope()
    )
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
  }
#endif
