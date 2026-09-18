//
//  InlineCardNetworkSelector+Button.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
struct InlineCardNetworkButton: View {
  let network: CardNetwork
  let isSelected: Bool
  let onTap: () -> Void

  var body: some View {
    Button(action: onTap) {
      CardNetworkBadge(network: network)
        .frame(
          width: PrimerCardNetworkSelector.buttonFrameWidth,
          height: PrimerCardNetworkSelector.buttonFrameHeight,
          alignment: .center
        )
        .contentShape(Rectangle())
    }
    .buttonStyle(PlainButtonStyle())
    .accessibilityIdentifier(
      AccessibilityIdentifiers.CardForm.inlineNetworkSelectorButton(forNetwork: network.rawValue)
    )
    .accessibilityLabel(network.displayName)
    .accessibilityHint(isSelected ? "" : CheckoutComponentsStrings.a11yInlineNetworkButtonHint)
    .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
  }
}

#if DEBUG
  @available(iOS 15.0, *)
  #Preview("Selected Button") {
    HStack(spacing: 0) {
      InlineCardNetworkButton(
        network: .visa,
        isSelected: true,
        onTap: {}
      )
    }
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
  }

  @available(iOS 15.0, *)
  #Preview("Unselected Button") {
    HStack(spacing: 0) {
      InlineCardNetworkButton(
        network: .masterCard,
        isSelected: false,
        onTap: {}
      )
    }
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
  }

  @available(iOS 15.0, *)
  #Preview("All Button States") {
    VStack(spacing: 20) {
      HStack(spacing: 0) {
        InlineCardNetworkButton(
          network: .visa, isSelected: true, onTap: {})
        InlineCardNetworkButton(
          network: .masterCard, isSelected: false, onTap: {})
        InlineCardNetworkButton(
          network: .amex, isSelected: false, onTap: {})
      }

      HStack(spacing: 0) {
        InlineCardNetworkButton(
          network: .visa, isSelected: false, onTap: {})
        InlineCardNetworkButton(
          network: .masterCard, isSelected: true, onTap: {})
        InlineCardNetworkButton(
          network: .amex, isSelected: false, onTap: {})
      }
    }
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
  }
#endif
