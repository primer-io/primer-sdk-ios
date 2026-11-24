//
//  ProcessingScreen.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct ProcessingScreen: View {
  @Environment(\.designTokens) private var tokens
  @Environment(\.bridgeController) private var bridgeController

  private let minimumHeight: CGFloat = 246
  private let verticalPadding: CGFloat = 48
  private let horizontalPadding: CGFloat = 32

  var body: some View {
    VStack(spacing: PrimerSpacing.small(tokens: tokens)) {
      ProgressView()
        .progressViewStyle(
          CircularProgressViewStyle(tint: CheckoutColors.loader(tokens: tokens))
        )
        .scaleEffect(PrimerScale.large)
        .frame(width: PrimerComponentHeight.progressIndicator, height: PrimerComponentHeight.progressIndicator)
        .accessibility(
          config: AccessibilityConfiguration(
            identifier: AccessibilityIdentifiers.Common.loadingIndicator,
            label: CheckoutComponentsStrings.a11yProcessingPayment
          ))

      VStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
        Text(CheckoutComponentsStrings.processingPayment)
          .primerTypography(.bodyLarge, tokens: tokens)
          .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
        Text(CheckoutComponentsStrings.processingPleaseWait)
          .primerTypography(.bodyMedium, tokens: tokens)
          .foregroundColor(CheckoutColors.textSecondary(tokens: tokens))
      }
      .multilineTextAlignment(.center)
    }
    .padding(.horizontal, horizontalPadding)
    .padding(.vertical, verticalPadding)
    .frame(maxWidth: .infinity, minHeight: minimumHeight)
    .background(CheckoutColors.background(tokens: tokens))
    .onAppear {
      bridgeController?.invalidateContentSize()
    }
  }
}
