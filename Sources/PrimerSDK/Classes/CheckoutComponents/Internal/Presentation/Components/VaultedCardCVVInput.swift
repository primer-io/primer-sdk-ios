//
//  VaultedCardCVVInput.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Inline CVV input component for vaulted card payments.
/// Shows a lock icon, instruction text, and CVV text field.
@available(iOS 15.0, *)
struct VaultedCardCVVInput: View {
    // MARK: - Properties

    @Binding var cvv: String
    @Binding var isValid: Bool
    @Binding var errorMessage: String?

    let cardNetwork: CardNetwork
    let onCvvChange: (String) -> Void

    @Environment(\.designTokens) private var tokens
    @FocusState private var isFocused: Bool

    // MARK: - Computed Properties

    private var expectedCvvLength: Int {
        cardNetwork.validation?.code.length ?? 3
    }

    private var cvvPlaceholder: String {
        String(repeating: CheckoutComponentsStrings.cvvPlaceholderDigit, count: expectedCvvLength)
    }

    /// Custom binding that filters input to digits only and limits length
    private var filteredCvvBinding: Binding<String> {
        Binding(
            get: { cvv },
            set: { newValue in
                let filtered = String(newValue.filter(\.isNumber).prefix(expectedCvvLength))
                // Only update if the filtered value is different to avoid unnecessary updates
                if cvv != filtered {
                    cvv = filtered
                }
                onCvvChange(filtered)
            }
        )
    }

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: PrimerSpacing.small(tokens: tokens)) {
            makeCvvInputRow()
            errorMessage.map(makeErrorLabel)
        }
        .onAppear {
            DispatchQueue.main.asyncAfter(deadline: .now() + PrimerAnimationDuration.focusDelay) {
                isFocused = true
            }
        }
    }

    // MARK: - CVV Input Row

    private func makeCvvInputRow() -> some View {
        HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
            HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                Image(systemName: "lock.fill")
                    .font(PrimerFont.bodySmall(tokens: tokens))
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))

                Text(CheckoutComponentsStrings.cvvRecaptureInstruction)
                    .font(PrimerFont.bodySmall(tokens: tokens))
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .accessibility(config: AccessibilityConfiguration(
                identifier: AccessibilityIdentifiers.Vault.cvvSecurityLabel,
                label: CheckoutComponentsStrings.cvvRecaptureInstruction,
                traits: []
            ))

            Spacer()

            makeCvvTextField()
        }
    }

    // MARK: - CVV Text Field

    private func makeCvvTextField() -> some View {
        TextField(cvvPlaceholder, text: filteredCvvBinding)
            .keyboardType(.numberPad)
            .textContentType(.oneTimeCode)
            .focused($isFocused)
            .multilineTextAlignment(.leading)
            .font(PrimerFont.bodyLarge(tokens: tokens))
            .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            .padding(.horizontal, PrimerSpacing.medium(tokens: tokens))
            .frame(width: PrimerComponentWidth.cvvFieldMax, height: PrimerSize.xxlarge(tokens: tokens))
            .background(
                RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
                    .fill(CheckoutColors.background(tokens: tokens))
            )
            .overlay(
                RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
                    .stroke(cvvBorderColor, lineWidth: isFocused ? PrimerBorderWidth.selected : PrimerBorderWidth.standard)
            )
            .accessibility(config: AccessibilityConfiguration(
                identifier: AccessibilityIdentifiers.Vault.cvvField,
                label: CheckoutComponentsStrings.a11yVaultCVVLabel,
                hint: CheckoutComponentsStrings.a11yVaultCVVHint(length: expectedCvvLength),
                traits: []
            ))
    }

    // MARK: - Error Label

    private func makeErrorLabel(_ message: String) -> some View {
        Text(message)
            .font(PrimerFont.bodySmall(tokens: tokens))
            .foregroundColor(CheckoutColors.textNegative(tokens: tokens))
    }

    // MARK: - Helpers

    private var cvvBorderColor: Color {
        if errorMessage != nil {
            return CheckoutColors.borderError(tokens: tokens)
        } else if isFocused {
            return CheckoutColors.borderFocus(tokens: tokens)
        } else {
            return CheckoutColors.borderDefault(tokens: tokens)
        }
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 17.0, *)
#Preview("CVV Input - Empty") {
    VaultedCardCVVInput(
        cvv: .constant(""),
        isValid: .constant(false),
        errorMessage: .constant(nil),
        cardNetwork: .visa,
        onCvvChange: { _ in }
    )
    .padding()
}

@available(iOS 17.0, *)
#Preview("CVV Input - Valid") {
    VaultedCardCVVInput(
        cvv: .constant("123"),
        isValid: .constant(true),
        errorMessage: .constant(nil),
        cardNetwork: .visa,
        onCvvChange: { _ in }
    )
    .padding()
}

@available(iOS 17.0, *)
#Preview("CVV Input - Error") {
    VaultedCardCVVInput(
        cvv: .constant("12"),
        isValid: .constant(false),
        errorMessage: .constant("Please enter a valid CVV"),
        cardNetwork: .visa,
        onCvvChange: { _ in }
    )
    .padding()
}

@available(iOS 17.0, *)
#Preview("CVV Input - AMEX (4 digits)") {
    VaultedCardCVVInput(
        cvv: .constant(""),
        isValid: .constant(false),
        errorMessage: .constant(nil),
        cardNetwork: .amex,
        onCvvChange: { _ in }
    )
    .padding()
}
#endif
