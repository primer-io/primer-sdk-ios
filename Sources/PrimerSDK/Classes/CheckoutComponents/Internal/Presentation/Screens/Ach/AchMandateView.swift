//
//  AchMandateView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct AchMandateView: View, LogReporter {
  let scope: any PrimerAchScope
  let achState: AchState

  @Environment(\.designTokens) private var tokens

  var body: some View {
    VStack(spacing: PrimerSpacing.large(tokens: tokens)) {
      Text(CheckoutComponentsStrings.achMandateTitle)
        .font(PrimerFont.titleLarge(tokens: tokens))
        .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        .multilineTextAlignment(.center)
        .accessibilityIdentifier(AccessibilityIdentifiers.Ach.mandateTitle)

      ScrollView {
        Text(achState.mandateText ?? "")
          .font(PrimerFont.bodyMedium(tokens: tokens))
          .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
          .multilineTextAlignment(.leading)
          .padding(PrimerSpacing.medium(tokens: tokens))
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(
            RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
              .fill(CheckoutColors.gray100(tokens: tokens))
          )
      }
      .frame(maxHeight: Layout.mandateTextMaxHeight)
      .accessibilityIdentifier(AccessibilityIdentifiers.Ach.mandateTextContainer)
      .accessibilityLabel(achState.mandateText ?? "")

      Spacer()
        .frame(height: PrimerSpacing.medium(tokens: tokens))

      VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
        makeAcceptButton()
        makeDeclineButton()
      }
    }
    .padding(.top, PrimerSpacing.large(tokens: tokens))
    .accessibilityIdentifier(AccessibilityIdentifiers.Ach.mandateContainer)
  }

  // MARK: - Accept Button

  private func makeAcceptButton() -> some View {
    Button(action: scope.acceptMandate) {
      Text(CheckoutComponentsStrings.achMandateAcceptButton)
        .font(PrimerFont.body(tokens: tokens))
        .foregroundColor(CheckoutColors.white(tokens: tokens))
        .frame(maxWidth: .infinity)
        .padding(.vertical, PrimerSpacing.large(tokens: tokens))
        .background(CheckoutColors.textPrimary(tokens: tokens))
        .cornerRadius(PrimerRadius.small(tokens: tokens))
    }
    .accessibilityIdentifier(AccessibilityIdentifiers.Ach.mandateAcceptButton)
    .accessibilityLabel(CheckoutComponentsStrings.achMandateAcceptButton)
    .accessibilityHint(CheckoutComponentsStrings.a11yAchMandateAcceptHint)
  }

  // MARK: - Decline Button

  private func makeDeclineButton() -> some View {
    Button(action: scope.declineMandate) {
      Text(CheckoutComponentsStrings.achMandateDeclineButton)
        .font(PrimerFont.body(tokens: tokens))
        .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
        .frame(maxWidth: .infinity)
        .padding(.vertical, PrimerSpacing.large(tokens: tokens))
        .background(
          RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
            .stroke(CheckoutColors.borderDefault(tokens: tokens), lineWidth: 1)
        )
    }
    .accessibilityIdentifier(AccessibilityIdentifiers.Ach.mandateDeclineButton)
    .accessibilityLabel(CheckoutComponentsStrings.achMandateDeclineButton)
    .accessibilityHint(CheckoutComponentsStrings.a11yAchMandateDeclineHint)
  }

  // MARK: - Layout Constants

  private enum Layout {
    static let mandateTextMaxHeight: CGFloat = 300
  }
}
