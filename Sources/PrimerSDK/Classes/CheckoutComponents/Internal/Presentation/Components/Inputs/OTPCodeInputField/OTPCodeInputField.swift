//
//  OTPCodeInputField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct OTPCodeInputField: View, LogReporter {
  let label: String?
  let placeholder: String
  let expectedLength: Int
  let scope: (any PrimerCardFormScope)?
  let onOTPCodeChange: ((String) -> Void)?
  let onValidationChange: ((Bool) -> Void)?

  // MARK: - Private Properties

  @Environment(\.diContainer) private var container
  @State private var validationService: ValidationService?
  @State private var otpCode: String = ""
  @State private var isValid: Bool = false
  @State private var errorMessage: String?
  @State private var isFocused: Bool = false
  @Environment(\.designTokens) private var tokens

  private var fieldFont: Font { PrimerFont.bodyLarge(tokens: tokens) }

  // MARK: - Initialization

  init(
    label: String?,
    placeholder: String,
    scope: any PrimerCardFormScope
  ) {
    self.label = label
    self.placeholder = placeholder
    expectedLength = 6
    self.scope = scope
    onOTPCodeChange = nil
    onValidationChange = nil
  }

  init(
    label: String?,
    placeholder: String,
    expectedLength: Int,
    onOTPCodeChange: ((String) -> Void)? = nil,
    onValidationChange: ((Bool) -> Void)? = nil
  ) {
    self.label = label
    self.placeholder = placeholder
    self.expectedLength = expectedLength
    scope = nil
    self.onOTPCodeChange = onOTPCodeChange
    self.onValidationChange = onValidationChange
  }

  // MARK: - Body

  var body: some View {
    PrimerInputFieldContainer(
      label: label,
      text: $otpCode,
      isValid: $isValid,
      errorMessage: $errorMessage,
      isFocused: $isFocused
    ) {
      TextField(
        "",
        text: $otpCode,
        prompt: Text(placeholder)
          .font(fieldFont)
          .foregroundColor(CheckoutColors.textPlaceholder(tokens: tokens))
      )
      .font(fieldFont)
      .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
      .keyboardType(.numberPad)
      .textContentType(.oneTimeCode)
      .frame(height: PrimerSize.xxlarge(tokens: tokens))
      .onChange(of: otpCode) { newValue in
        if newValue.count > expectedLength {
          otpCode = String(newValue.prefix(expectedLength))
        } else {
          if let scope {
            scope.updateOtpCode(newValue)
          } else {
            onOTPCodeChange?(newValue)
          }
          validateOTPCode()
        }
      }
    }
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.FormRedirect.otpField,
        label: label ?? "OTP Code",
        hint: CheckoutComponentsStrings.a11yOtpFieldHint
      ),
      combinesChildren: false
    )
    .onAppear {
      setupValidationService()
    }
  }

  private func setupValidationService() {
    guard let container else {
      logger.error(message: "DIContainer not available for OTPCodeInputField")
      return
    }

    do {
      validationService = try container.resolveSync(ValidationService.self)
    } catch {
      logger.error(message: "Failed to resolve ValidationService: \(error)")
    }
  }

  @MainActor
  private func validateOTPCode() {
    let result = OTPCodeRule(expectedLength: expectedLength).validate(otpCode)
    isValid = result.isValid
    onValidationChange?(result.isValid)
    // Feed OTP validity into the form's submit gate (no-op unless OTP is a configured field).
    (scope as? (any CardFormFieldScopeInternal))?.updateValidationStateIfNeeded(for: .otp, isValid: result.isValid)

    // Never show errors while the code is empty or still being typed; only once it reaches full length.
    guard otpCode.count >= expectedLength else {
      errorMessage = nil
      scope?.clearFieldError(.otp)
      return
    }

    errorMessage = result.errorMessage

    guard let scope else { return }
    if result.isValid {
      scope.clearFieldError(.otp)
    } else if let message = result.errorMessage {
      scope.setFieldError(.otp, message: message, errorCode: result.errorCode)
    }
  }
}

#if DEBUG
  // MARK: - Preview
  @available(iOS 15.0, *)
  #Preview("Light Mode") {
    OTPCodeInputField(
      label: "Enter OTP Code",
      placeholder: "000000",
      scope: MockCardFormScope()
    )
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
    .environment(\.diContainer, MockDIContainer())
  }

  @available(iOS 15.0, *)
  #Preview("Dark Mode") {
    OTPCodeInputField(
      label: "Enter OTP Code",
      placeholder: "000000",
      scope: MockCardFormScope()
    )
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .environment(\.diContainer, MockDIContainer())
    .preferredColorScheme(.dark)
  }
#endif
