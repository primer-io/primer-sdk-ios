//
//  FormRedirectScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct FormRedirectScreen: View {

    // MARK: - Properties

    @ObservedObject private var scope: DefaultFormRedirectScope
    private let currentState: PrimerFormRedirectState

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(scope: DefaultFormRedirectScope, state: PrimerFormRedirectState) {
        self.scope = scope
        currentState = state
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
        .onAppear(perform: scope.start)
    }

    // MARK: - Header

    private func makeHeaderView() -> some View {
        CheckoutHeaderView(
            showBackButton: scope.presentationContext.shouldShowBackButton,
            onBack: scope.onBack,
            rightButton: .closeButton(action: scope.cancel)
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
        PrimerCheckoutButton(
            scope.submitButtonText ?? defaultSubmitButtonText,
            isEnabled: currentState.isSubmitEnabled,
            isLoading: currentState.isLoading,
            accessibilityConfiguration: AccessibilityConfiguration(
                identifier: AccessibilityIdentifiers.FormRedirect.submitButton,
                label: CheckoutComponentsStrings.a11ySubmitButtonLabel,
                hint: currentState.isSubmitEnabled ? nil : CheckoutComponentsStrings.a11ySubmitButtonHint,
                traits: [.isButton]
            ),
            action: scope.submit
        )
    }
}

// MARK: - Form Field View

@available(iOS 15.0, *)
private struct FormFieldView: View {

    let field: PrimerFormFieldState
    let onValueChanged: (String) -> Void
    let onSubmit: () -> Void

    @Environment(\.designTokens) private var tokens
    @FocusState private var hasKeyboardFocus: Bool
    @State private var isFocused = false

    var body: some View {
        VStack(alignment: .leading, spacing: PrimerSpacing.small(tokens: tokens)) {
            PrimerInputFieldContainer(
                label: field.label,
                text: valueBinding,
                isValid: .constant(field.errorMessage == nil),
                errorMessage: .constant(field.errorMessage),
                isFocused: $isFocused,
                textFieldBuilder: makeInputField
            )
            .accessibility(
                config: AccessibilityConfiguration(
                    identifier: accessibilityIdentifier,
                    label: accessibilityLabel,
                    hint: accessibilityHint,
                    traits: []
                ),
                combinesChildren: false
            )

            if field.errorMessage == nil, let helperText = field.helperText {
                Text(helperText)
                    .primerTypography(.caption, tokens: tokens)
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
            }
        }
    }

    private var valueBinding: Binding<String> {
        Binding(get: { field.value }, set: onValueChanged)
    }

    private func makeInputField() -> some View {
        HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
            if let prefix = field.countryCodePrefix, field.fieldType == .phoneNumber {
                Text(prefix)
                    .primerTypography(.bodyLarge, tokens: tokens)
                    .foregroundColor(CheckoutColors.inputText(tokens: tokens))
                    .accessibilityIdentifier(AccessibilityIdentifiers.FormRedirect.phonePrefix)
            }

            TextField(field.placeholder, text: valueBinding)
                .primerFieldTypography(.bodyLarge, tokens: tokens)
                .foregroundColor(CheckoutColors.inputText(tokens: tokens))
                .keyboardType(field.keyboardType.uiKeyboardType)
                .textContentType(field.fieldType.textContentType)
                .focused($hasKeyboardFocus)
                .onSubmit(onSubmit)
                .onChange(of: hasKeyboardFocus) { isFocused = $0 }
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
private extension PrimerFormFieldState.KeyboardType {
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
private extension PrimerFormFieldState.FieldType {
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
