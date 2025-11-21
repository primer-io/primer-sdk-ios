//
//  InlineCardNetworkSelector+Button.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Inline Card Network Button

@available(iOS 15.0, *)
struct InlineCardNetworkButton: View {
    let network: CardNetwork
    let isSelected: Bool
    let isFirst: Bool
    let isLast: Bool
    let tokens: DesignTokens?
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            CardNetworkBadge(
                network: network,
                width: PrimerCardNetworkSelector.badgeWidth,
                height: PrimerCardNetworkSelector.badgeHeight
            )
            .frame(
                width: PrimerCardNetworkSelector.buttonFrameWidth,
                height: PrimerCardNetworkSelector.buttonFrameHeight,
                alignment: .center
            )
            .background(backgroundColor)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier(AccessibilityIdentifiers.CardForm.inlineNetworkSelectorButton(network.rawValue))
        .accessibilityLabel(network.displayName)
        .accessibilityHint(isSelected ? nil : CheckoutComponentsStrings.a11yInlineNetworkButtonHint)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    private var backgroundColor: Color {
        isSelected
        ? CheckoutColors.gray100(tokens: tokens)
        : CheckoutColors.background(tokens: tokens)
    }
}

#if DEBUG
// MARK: - Preview
@available(iOS 15.0, *)
#Preview("Selected Button") {
    HStack(spacing: 0) {
        InlineCardNetworkButton(
            network: .visa,
            isSelected: true,
            isFirst: true,
            isLast: false,
            tokens: MockDesignTokens.light,
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
            isFirst: false,
            isLast: false,
            tokens: MockDesignTokens.light,
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
            InlineCardNetworkButton(network: .visa, isSelected: true, isFirst: true, isLast: false, tokens: MockDesignTokens.light, onTap: {})
            InlineCardNetworkButton(network: .masterCard, isSelected: false, isFirst: false, isLast: false, tokens: MockDesignTokens.light, onTap: {})
            InlineCardNetworkButton(network: .amex, isSelected: false, isFirst: false, isLast: true, tokens: MockDesignTokens.light, onTap: {})
        }

        HStack(spacing: 0) {
            InlineCardNetworkButton(network: .visa, isSelected: false, isFirst: true, isLast: false, tokens: MockDesignTokens.light, onTap: {})
            InlineCardNetworkButton(network: .masterCard, isSelected: true, isFirst: false, isLast: false, tokens: MockDesignTokens.light, onTap: {})
            InlineCardNetworkButton(network: .amex, isSelected: false, isFirst: false, isLast: true, tokens: MockDesignTokens.light, onTap: {})
        }
    }
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
}
#endif
