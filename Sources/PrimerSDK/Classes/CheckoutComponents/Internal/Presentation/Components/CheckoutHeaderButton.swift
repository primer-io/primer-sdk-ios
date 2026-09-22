//
//  CheckoutHeaderButton.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// The trailing control in a checkout header: Cancel, Edit or Done.
///
/// `CheckoutHeaderView` draws it, and so do the screens that lay out their own header row, so one
/// token moves every one of them. Cancel used to be three different colours across twelve screens.
@available(iOS 15.0, *)
struct CheckoutHeaderButton: View {
  let config: CheckoutHeaderView.RightButtonConfig

  @Environment(\.designTokens) private var tokens

  var body: some View {
    Button(action: config.action) {
      HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
        if let icon = config.icon {
          Image(systemName: icon)
            .font(PrimerFont.caption(tokens: tokens))
        }
        Text(config.title)
          .primerTypography(.titleLarge, tokens: tokens)
      }
      .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
    }
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: config.accessibilityIdentifier,
        label: config.accessibilityLabel,
        traits: [.isButton]
      ))
  }
}
