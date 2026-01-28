//
//  OTPCodeInputField.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct OTPCodeInputField: View, LogReporter {
  // MARK: - Public Properties

  let label: String?
  let placeholder: String
  let expectedLength: Int
  let scope: (any PrimerCardFormScope)?
  let onOTPCodeChange: ((String) -> Void)?
  let onValidationChange: ((Bool) -> Void)?
  let styling: PrimerFieldStyling?

  // MARK: - Private Properties

  @Environment(\.diContainer) private var container
  @State private var validationService: ValidationService?
  @State private var otpCode: String = ""
  @State private var isValid: Bool = false
  @State private var errorMessage: String?
  @State private var isFocused: Bool = false
  @Environment(\.designTokens) private var tokens

  private var fieldFont: Font {
    styling?.resolvedFont(tokens: tokens) ?? PrimerFont.bodyLarge(tokens: tokens)
  }

  // MARK: - Initialization

  init(
    label: String?,
    placeholder: String,
    scope: any PrimerCardFormScope,
    styling: PrimerFieldStyling? = nil
  ) {
    self.label = label
    self.placeholder = placeholder
    self.expectedLength = 6
    self.scope = scope
    self.styling = styling
    self.onOTPCodeChange = nil
    self.onValidationChange = nil
  }

  init(
    label: String?,
    placeholder: String,
    expectedLength: Int,
    styling: PrimerFieldStyling? = nil,
    onOTPCodeChange: ((String) -> Void)? = nil,
    onValidationChange: ((Bool) -> Void)? = nil
  ) {
    self.label = label
    self.placeholder = placeholder
    self.expectedLength = expectedLength
    self.scope = nil
    self.styling = styling
    self.onOTPCodeChange = onOTPCodeChange
    self.onValidationChange = onValidationChange
  }

  // MARK: - Body

  var body: some View {
    PrimerInputFieldContainer(
      label: label,
      styling: styling,
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
          .foregroundColor(
            styling?.placeholderColor ?? CheckoutColors.textPlaceholder(tokens: tokens))
      )
      .font(fieldFont)
      .foregroundColor(styling?.textColor ?? CheckoutColors.textPrimary(tokens: tokens))
      .keyboardType(.numberPad)
      .textContentType(.oneTimeCode)
      .frame(height: PrimerSize.xxlarge(tokens: tokens))
      .onChange(of: otpCode) { newValue in
        if newValue.count > expectedLength {
          otpCode = String(newValue.prefix(expectedLength))
        } else {
          if let scope = scope {
            scope.updateOtpCode(newValue)
          } else {
            onOTPCodeChange?(newValue)
          }
          validateOTPCode()
        }
      }
    }
    .onAppear {
      setupValidationService()
    }
  }

  private func setupValidationService() {
    guard let container = container else {
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
    // Use OTPCodeRule with expected length
    let otpRule = OTPCodeRule(expectedLength: expectedLength)
    let result = otpRule.validate(otpCode)

    isValid = result.isValid
    errorMessage = result.errorMessage
    onValidationChange?(result.isValid)

    if let scope = scope {
      if result.isValid {
        scope.clearFieldError(.otp)
      } else if let message = result.errorMessage {
        scope.setFieldError(.otp, message: message, errorCode: result.errorCode)
      }
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
