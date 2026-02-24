//
//  FormRedirectScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct FormRedirectScreen: View {

    // MARK: - Properties

    @ObservedObject private var scope: DefaultFormRedirectScope
    private let currentState: FormRedirectState

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(scope: DefaultFormRedirectScope, state: FormRedirectState) {
        self.scope = scope
        self.currentState = state
    }

    // MARK: - Computed Properties

    private var paymentMethodIcon: UIImage? {
        PrimerPaymentMethodType(rawValue: scope.paymentMethodType)?.icon
    }

    private var defaultSubmitButtonText: String {
        switch scope.paymentMethodType {
        case PrimerPaymentMethodType.adyenBlik.rawValue:
            CheckoutComponentsStrings.payWithBlik
        case PrimerPaymentMethodType.adyenMBWay.rawValue:
            CheckoutComponentsStrings.payWithMBWay
        default:
            CheckoutComponentsStrings.payButton
        }
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            makeHeaderView()

            ScrollView {
                VStack(spacing: PrimerSpacing.xlarge(tokens: tokens)) {
                    makePaymentMethodHeader()
                    makeFormSection()

                    Spacer()
                        .frame(height: PrimerSpacing.large(tokens: tokens))

                    makeSubmitButtonSection()
                }
                .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
                .padding(.top, PrimerSpacing.large(tokens: tokens))
            }
        }
        .background(CheckoutColors.screenBackground(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.FormRedirect.screen)
        .onAppear {
            scope.start()
        }
    }

    // MARK: - Header

    private func makeHeaderView() -> some View {
        CheckoutHeaderView(
            showBackButton: scope.presentationContext.shouldShowBackButton,
            onBack: scope.onBack,
            rightButton: .closeButton(action: scope.onCancel)
        )
    }

    // MARK: - Payment Method Header

    @ViewBuilder
    private func makePaymentMethodHeader() -> some View {
        if let icon = paymentMethodIcon {
            VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: PrimerIconSize.paymentMethodWidth, height: PrimerIconSize.paymentMethodHeight)
            }
            .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
        }
    }

    // MARK: - Form Section

    @ViewBuilder
    private func makeFormSection() -> some View {
        if let customFormSection = scope.formSection {
            AnyView(customFormSection(scope))
        } else {
            makeDefaultFormSection()
        }
    }

    private func makeDefaultFormSection() -> some View {
        VStack(spacing: PrimerSpacing.medium(tokens: tokens)) {
            ForEach(currentState.fields) { field in
                FormFieldView(
                    field: field,
                    onValueChanged: { value in
                        scope.updateField(field.fieldType, value: value)
                    },
                    onSubmit: scope.submit
                )
            }
        }
    }

    // MARK: - Submit Button Section

    @ViewBuilder
    private func makeSubmitButtonSection() -> some View {
        if let customButton = scope.submitButton {
            AnyView(customButton(scope))
        } else {
            makeDefaultSubmitButton()
        }
    }

    private func makeDefaultSubmitButton() -> some View {
        Button(action: scope.submit) {
            HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
                if currentState.isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                }

                Text(scope.submitButtonText ?? defaultSubmitButtonText)
                    .font(PrimerFont.bodyMedium(tokens: tokens))
            }
            .frame(maxWidth: .infinity)
            .frame(height: PrimerComponentHeight.button)
            .foregroundColor(CheckoutColors.buttonTextPrimary(tokens: tokens))
            .background(
                RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
                    .fill(currentState.isSubmitEnabled && !currentState.isLoading
                          ? CheckoutColors.buttonPrimary(tokens: tokens)
                          : CheckoutColors.buttonDisabled(tokens: tokens))
            )
        }
        .disabled(!currentState.isSubmitEnabled || currentState.isLoading)
        .accessibilityIdentifier(AccessibilityIdentifiers.FormRedirect.submitButton)
        .accessibility(
            config: AccessibilityConfiguration(
                identifier: AccessibilityIdentifiers.FormRedirect.submitButton,
                label: CheckoutComponentsStrings.a11ySubmitButtonLabel,
                hint: currentState.isSubmitEnabled ? nil : CheckoutComponentsStrings.a11ySubmitButtonHint,
                traits: [.isButton]
            )
        )
    }
}

// MARK: - Form Field View

@available(iOS 15.0, *)
private struct FormFieldView: View {

    let field: FormFieldState
    let onValueChanged: (String) -> Void
    let onSubmit: () -> Void

    @Environment(\.designTokens) private var tokens
    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: PrimerSpacing.small(tokens: tokens)) {
            Text(field.label)
                .font(PrimerFont.caption(tokens: tokens))
                .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))

            makeInputField()

            if let errorMessage = field.errorMessage {
                Text(errorMessage)
                    .font(PrimerFont.caption(tokens: tokens))
                    .foregroundColor(CheckoutColors.error(tokens: tokens))
            } else if let helperText = field.helperText {
                Text(helperText)
                    .font(PrimerFont.caption(tokens: tokens))
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            }
        }
    }

    private func makeInputField() -> some View {
        HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
            if let prefix = field.countryCodePrefix, field.fieldType == .phoneNumber {
                Text(prefix)
                    .font(PrimerFont.bodyLarge(tokens: tokens))
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                    .accessibilityIdentifier(AccessibilityIdentifiers.FormRedirect.phonePrefix)
            }

            TextField(field.placeholder, text: Binding(
                get: { field.value },
                set: { onValueChanged($0) }
            ))
            .font(PrimerFont.bodyLarge(tokens: tokens))
            .keyboardType(field.keyboardType.uiKeyboardType)
            .textContentType(field.fieldType.textContentType)
            .focused($isFocused)
            .onSubmit { onSubmit() }
            .accessibilityIdentifier(accessibilityIdentifier)
            .accessibility(
                config: AccessibilityConfiguration(
                    identifier: accessibilityIdentifier,
                    label: accessibilityLabel,
                    hint: accessibilityHint,
                    traits: []
                )
            )
        }
        .padding(.horizontal, PrimerSpacing.medium(tokens: tokens))
        .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
        .background(
            RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
                .stroke(borderColor, lineWidth: PrimerBorderWidth.standard)
                .background(
                    RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
                        .fill(CheckoutColors.inputBackground(tokens: tokens))
                )
        )
    }

    private var borderColor: Color {
        if field.errorMessage != nil {
            CheckoutColors.error(tokens: tokens)
        } else if isFocused {
            CheckoutColors.inputBorderFocused(tokens: tokens)
        } else {
            CheckoutColors.inputBorder(tokens: tokens)
        }
    }

    private var accessibilityIdentifier: String {
        switch field.fieldType {
        case .otpCode:
            AccessibilityIdentifiers.FormRedirect.otpField
        case .phoneNumber:
            AccessibilityIdentifiers.FormRedirect.phoneField
        }
    }

    private var accessibilityLabel: String {
        switch field.fieldType {
        case .otpCode:
            CheckoutComponentsStrings.a11yFormRedirectOtpLabel
        case .phoneNumber:
            CheckoutComponentsStrings.a11yFormRedirectPhoneLabel
        }
    }

    private var accessibilityHint: String {
        switch field.fieldType {
        case .otpCode:
            CheckoutComponentsStrings.a11yFormRedirectOtpHint
        case .phoneNumber:
            CheckoutComponentsStrings.a11yFormRedirectPhoneHint
        }
    }
}

// MARK: - Keyboard Type Extension

@available(iOS 15.0, *)
private extension FormFieldState.KeyboardType {
    var uiKeyboardType: UIKeyboardType {
        switch self {
        case .numberPad:
            .numberPad
        case .phonePad:
            .phonePad
        case .default:
            .default
        }
    }
}

// MARK: - Text Content Type Extension

@available(iOS 15.0, *)
private extension FormFieldState.FieldType {
    var textContentType: UITextContentType? {
        switch self {
        case .otpCode:
            .oneTimeCode
        case .phoneNumber:
            .telephoneNumber
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 15.0, *)
struct FormRedirectScreen_Previews: PreviewProvider {
    static var previews: some View {
        Text("Form Redirect Screen Preview")
    }
}
#endif
