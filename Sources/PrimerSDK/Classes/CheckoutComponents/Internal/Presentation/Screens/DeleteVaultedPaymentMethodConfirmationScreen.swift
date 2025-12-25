//
//  DeleteVaultedPaymentMethodConfirmationScreen.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// Screen displaying a confirmation dialog for deleting a vaulted payment method
@available(iOS 15.0, *)
struct DeleteVaultedPaymentMethodConfirmationScreen: View, LogReporter {
    let vaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
    let navigator: CheckoutNavigator
    let scope: DefaultPaymentMethodSelectionScope

    @Environment(\.designTokens) private var tokens

    @State private var isDeleting: Bool = false

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            makeHeader()
            makePaymentMethodCard()
            makeConfirmationSection()
            Spacer()
        }
        .background(CheckoutColors.background(tokens: tokens))
    }

    // MARK: - Header

    private func makeHeader() -> some View {
        CheckoutHeaderView(
            showBackButton: true,
            onBack: { navigator.navigateBack() },
            rightButton: .doneButton(action: { navigator.navigateBack() })
        )
    }

    // MARK: - Payment Method Card (Read-only)

    private func makePaymentMethodCard() -> some View {
        VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
            // Title
            HStack {
                Text(CheckoutComponentsStrings.allSavedPaymentMethods)
                    .font(PrimerFont.titleXLarge(tokens: tokens))
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                Spacer()
            }

            // Card display (non-interactive, reusing VaultedPaymentMethodCard)
            VaultedPaymentMethodCard(
                vaultedPaymentMethod: vaultedPaymentMethod
            )
        }
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .padding(.bottom, PrimerSpacing.large(tokens: tokens))
    }

    // MARK: - Confirmation Section

    private func makeConfirmationSection() -> some View {
        VStack(alignment: .leading, spacing: PrimerSpacing.small(tokens: tokens)) {
            Text(CheckoutComponentsStrings.deletePaymentMethodConfirmation)
                .font(PrimerFont.bodySmall(tokens: tokens))
                .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))

            HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
                makeCancelButton()
                makeDeleteButton()
            }
        }
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    }

    // MARK: - Cancel Button

    private func makeCancelButton() -> some View {
        Button(action: { navigator.navigateBack() }) {
            Text(CheckoutComponentsStrings.cancelButton)
                .font(PrimerFont.titleLarge(tokens: tokens))
                .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                .frame(maxWidth: .infinity)
                .padding(PrimerSpacing.medium(tokens: tokens))
                .background(
                    RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
                        .fill(CheckoutColors.background(tokens: tokens))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
                        .stroke(
                            CheckoutColors.borderDefault(tokens: tokens),
                            lineWidth: PrimerBorderWidth.standard
                        )
                )
        }
        .buttonStyle(PlainButtonStyle())
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Common.cancelButton,
            label: CheckoutComponentsStrings.a11yCancel,
            traits: [.isButton]
        ))
    }

    // MARK: - Delete Button

    private func makeDeleteButton() -> some View {
        Button(action: handleDelete) {
            Group {
                if isDeleting {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: CheckoutColors.background(tokens: tokens)))
                } else {
                    Text(CheckoutComponentsStrings.deleteButton)
                        .font(PrimerFont.titleLarge(tokens: tokens))
                }
            }
            .foregroundColor(CheckoutColors.background(tokens: tokens))
            .frame(maxWidth: .infinity)
            .padding(PrimerSpacing.medium(tokens: tokens))
            .background(
                RoundedRectangle(cornerRadius: PrimerRadius.medium(tokens: tokens))
                    .fill(CheckoutColors.borderFocus(tokens: tokens))
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isDeleting)
        .accessibility(config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Common.deleteButton,
            label: CheckoutComponentsStrings.a11yDelete,
            traits: [.isButton]
        ))
    }

    // MARK: - Actions

    private func handleDelete() {
        guard !isDeleting else { return }

        isDeleting = true

        Task {
            do {
                try await scope.deleteVaultedPaymentMethod(vaultedPaymentMethod)
                logger.info(message: "[Vault] Successfully deleted payment method from confirmation screen")
            } catch {
                logger.error(message: "[Vault] Failed to delete payment method: \(error.localizedDescription)")
            }

            isDeleting = false
            navigator.navigateBack()
        }
    }
}
