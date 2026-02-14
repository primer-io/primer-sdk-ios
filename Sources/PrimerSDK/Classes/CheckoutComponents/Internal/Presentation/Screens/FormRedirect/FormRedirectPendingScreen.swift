//
//  FormRedirectPendingScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct FormRedirectPendingScreen: View {

    // MARK: - Properties

    @ObservedObject private var scope: DefaultFormRedirectScope
    private let currentState: FormRedirectState

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(scope: DefaultFormRedirectScope, state: FormRedirectState) {
        self.scope = scope
        self.currentState = state
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            makeHeaderView()

            VStack(spacing: PrimerSpacing.xlarge(tokens: tokens)) {
                Spacer()

                makePaymentMethodIcon()

                Text(CheckoutComponentsStrings.formRedirectPendingTitle)
                    .font(PrimerFont.titleLarge(tokens: tokens))
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
                    .multilineTextAlignment(.center)

                Text(currentState.pendingMessage ?? CheckoutComponentsStrings.formRedirectPendingMessage)
                    .font(PrimerFont.bodyLarge(tokens: tokens))
                    .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, PrimerSpacing.xlarge(tokens: tokens))
                    .accessibilityIdentifier(AccessibilityIdentifiers.FormRedirect.pendingMessage)

                ProgressView()
                    .progressViewStyle(
                        CircularProgressViewStyle(tint: CheckoutColors.borderFocus(tokens: tokens))
                    )
                    .scaleEffect(PrimerScale.large)
                    .accessibilityIdentifier(AccessibilityIdentifiers.FormRedirect.loadingIndicator)
                    .accessibility(
                        config: AccessibilityConfiguration(
                            identifier: AccessibilityIdentifiers.FormRedirect.loadingIndicator,
                            label: CheckoutComponentsStrings.a11yLoading
                        )
                    )

                Spacer()
            }
            .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        }
        .background(CheckoutColors.screenBackground(tokens: tokens))
        .accessibilityIdentifier(AccessibilityIdentifiers.FormRedirect.pendingScreen)
        .onAppear {
            announceScreenChange()
        }
    }

    // MARK: - Header

    private func makeHeaderView() -> some View {
        HStack {
            Spacer()

            Button(action: scope.onCancel) {
                Text(CheckoutComponentsStrings.cancelButton)
                    .font(PrimerFont.titleLarge(tokens: tokens))
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            }
            .accessibilityIdentifier(AccessibilityIdentifiers.FormRedirect.cancelButton)
            .accessibility(
                config: AccessibilityConfiguration(
                    identifier: AccessibilityIdentifiers.FormRedirect.cancelButton,
                    label: CheckoutComponentsStrings.a11yCancel,
                    traits: [.isButton]
                )
            )
        }
        .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
        .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
    }

    // MARK: - Payment Method Icon

    @ViewBuilder
    private func makePaymentMethodIcon() -> some View {
        if let icon = PrimerPaymentMethodType(rawValue: scope.paymentMethodType)?.icon {
            Image(uiImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: PrimerIconSize.paymentMethodLargeWidth, height: PrimerIconSize.paymentMethodLargeHeight)
        }
    }

    // MARK: - Accessibility

    private func announceScreenChange() {
        let announcement = "\(CheckoutComponentsStrings.formRedirectPendingTitle). \(currentState.pendingMessage ?? CheckoutComponentsStrings.formRedirectPendingMessage)"
        UIAccessibility.post(notification: .screenChanged, argument: announcement)
    }
}

// MARK: - Preview

#if DEBUG
@available(iOS 15.0, *)
struct FormRedirectPendingScreen_Previews: PreviewProvider {
    static var previews: some View {
        Text("Form Redirect Pending Screen Preview")
    }
}
#endif
