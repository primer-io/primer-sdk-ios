//
//  InlineCardNetworkSelector+Button.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - Inline Card Network Button

@available(iOS 15.0, *)
struct InlineCardNetworkButton: View {
    // MARK: - Properties

    let network: CardNetwork
    let isSelected: Bool
    let tokens: DesignTokens?
    let onTap: () -> Void

    // MARK: - Body

    var body: some View {
        Button(action: onTap) {
            CardNetworkBadge(network: network)
                .frame(
                    width: PrimerCardNetworkSelector.buttonFrameWidth,
                    height: PrimerCardNetworkSelector.buttonFrameHeight,
                    alignment: .center
                )
                .background(backgroundColor)
        }
        .buttonStyle(PlainButtonStyle())
        .accessibilityIdentifier(AccessibilityIdentifiers.CardForm.inlineNetworkSelectorButton(forNetwork: network.rawValue))
        .accessibilityLabel(network.displayName)
        .accessibilityHint(isSelected ? "" : CheckoutComponentsStrings.a11yInlineNetworkButtonHint)
        .accessibilityAddTraits(isSelected ? [.isButton, .isSelected] : [.isButton])
    }

    // MARK: - Private Properties

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
            InlineCardNetworkButton(network: .visa, isSelected: true, tokens: MockDesignTokens.light, onTap: {})
            InlineCardNetworkButton(network: .masterCard, isSelected: false, tokens: MockDesignTokens.light, onTap: {})
            InlineCardNetworkButton(network: .amex, isSelected: false, tokens: MockDesignTokens.light, onTap: {})
        }

        HStack(spacing: 0) {
            InlineCardNetworkButton(network: .visa, isSelected: false, tokens: MockDesignTokens.light, onTap: {})
            InlineCardNetworkButton(network: .masterCard, isSelected: true, tokens: MockDesignTokens.light, onTap: {})
            InlineCardNetworkButton(network: .amex, isSelected: false, tokens: MockDesignTokens.light, onTap: {})
        }
    }
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
}
#endif
