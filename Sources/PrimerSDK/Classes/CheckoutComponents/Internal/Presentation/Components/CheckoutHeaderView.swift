//
//  CheckoutHeaderView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct CheckoutHeaderView: View {
  let showBackButton: Bool
  let onBack: () -> Void
  let rightButton: RightButtonConfig?

  @Environment(\.designTokens) private var tokens

  struct RightButtonConfig {
    let title: String
    let icon: String?
    let action: () -> Void
    let accessibilityIdentifier: String
    let accessibilityLabel: String

    static func closeButton(
      identifier: String = AccessibilityIdentifiers.Common.closeButton,
      action: @escaping () -> Void
    ) -> RightButtonConfig {
      RightButtonConfig(
        title: CheckoutComponentsStrings.cancelButton,
        icon: nil,
        action: action,
        accessibilityIdentifier: identifier,
        accessibilityLabel: CheckoutComponentsStrings.a11yCancel
      )
    }

    static func editButton(action: @escaping () -> Void) -> RightButtonConfig {
      RightButtonConfig(
        title: CheckoutComponentsStrings.editButton,
        icon: "pencil",
        action: action,
        accessibilityIdentifier: AccessibilityIdentifiers.Common.editButton,
        accessibilityLabel: CheckoutComponentsStrings.editButton
      )
    }

    static func doneButton(action: @escaping () -> Void) -> RightButtonConfig {
      RightButtonConfig(
        title: CheckoutComponentsStrings.doneButton,
        icon: "checkmark",
        action: action,
        accessibilityIdentifier: AccessibilityIdentifiers.Common.doneButton,
        accessibilityLabel: CheckoutComponentsStrings.doneButton
      )
    }
  }

  init(
    showBackButton: Bool = true,
    onBack: @escaping () -> Void,
    rightButton: RightButtonConfig? = nil
  ) {
    self.showBackButton = showBackButton
    self.onBack = onBack
    self.rightButton = rightButton
  }

  var body: some View {
    HStack {
      if showBackButton {
        makeBackButtonView()
      }

      Spacer()

      if let rightButton {
        CheckoutHeaderButton(config: rightButton)
      }
    }
    .padding(.horizontal, PrimerSpacing.large(tokens: tokens))
    .padding(.vertical, PrimerSpacing.medium(tokens: tokens))
  }

  private func makeBackButtonView() -> some View {
    Button(action: onBack) {
      HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
        Image(systemName: RTLIcon.backChevron)
          .foregroundColor(CheckoutColors.iconPrimary(tokens: tokens))
        Text(CheckoutComponentsStrings.backButton)
      }
      .font(PrimerFont.bodyMedium(tokens: tokens))
      .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
    }
    .accessibility(
      config: AccessibilityConfiguration(
        identifier: AccessibilityIdentifiers.Common.backButton,
        label: CheckoutComponentsStrings.a11yBack,
        traits: [.isButton]
      ))
  }
}
