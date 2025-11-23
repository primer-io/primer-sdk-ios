//
//  CardNetworkBadge.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A reusable SwiftUI component that displays a card network badge
/// with either an icon or abbreviated text.
///
/// The badge features:
/// - Card network icon (if available) or abbreviated text (first 2 characters)
/// - Consistent sizing based on design tokens
/// - Border and corner radius styling
/// - Design token-driven colors and typography
///
/// Usage:
/// ```swift
/// CardNetworkBadge(network: .visa)
/// CardNetworkBadge(network: .masterCard)
/// ```
@available(iOS 15.0, *)
struct CardNetworkBadge: View, LogReporter {
    // MARK: - Properties

    /// The card network to display in the badge
    let network: CardNetwork

    /// Optional custom width (defaults to PrimerSize.large)
    let width: CGFloat?

    /// Optional custom height (defaults to PrimerSize.small)
    let height: CGFloat?

    // MARK: - Environment

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    init(network: CardNetwork, width: CGFloat? = nil, height: CGFloat? = nil) {
        self.network = network
        self.width = width
        self.height = height
    }

    // MARK: - Computed Properties

    private var badgeWidth: CGFloat {
        width ?? PrimerCardNetworkSelector.badgeWidth
    }

    private var badgeHeight: CGFloat {
        height ?? PrimerCardNetworkSelector.badgeHeight
    }

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        if let icon = network.icon {
            Image(uiImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: badgeWidth, height: badgeHeight)
                .cornerRadius(PrimerRadius.xsmall(tokens: tokens))
        } else {
            Text(network.displayName.prefix(2).uppercased())
                .font(PrimerFont.smallBadge(tokens: tokens))
                .foregroundColor(CheckoutColors.primary(tokens: tokens))
                .frame(width: badgeWidth, height: badgeHeight)
                .overlay(
                    RoundedRectangle(cornerRadius: PrimerRadius.xsmall(tokens: tokens))
                        .stroke(CheckoutColors.borderDefault(tokens: tokens), lineWidth: PrimerBorderWidth.thin)
                )
        }
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 15.0, *)
#Preview("Light Mode") {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            CardNetworkBadge(network: .visa)
            CardNetworkBadge(network: .masterCard)
            CardNetworkBadge(network: .amex)
            CardNetworkBadge(network: .discover)
        }

        HStack(spacing: 8) {
            CardNetworkBadge(network: .cartesBancaires)
            CardNetworkBadge(network: .diners)
            CardNetworkBadge(network: .jcb)
            CardNetworkBadge(network: .unknown)
        }
    }
    .padding()
    .environment(\.designTokens, MockDesignTokens.light)
}

@available(iOS 15.0, *)
#Preview("Dark Mode") {
    VStack(spacing: 16) {
        HStack(spacing: 8) {
            CardNetworkBadge(network: .visa)
            CardNetworkBadge(network: .masterCard)
            CardNetworkBadge(network: .amex)
            CardNetworkBadge(network: .discover)
        }

        HStack(spacing: 8) {
            CardNetworkBadge(network: .cartesBancaires)
            CardNetworkBadge(network: .diners)
            CardNetworkBadge(network: .jcb)
            CardNetworkBadge(network: .unknown)
        }
    }
    .padding()
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .preferredColorScheme(.dark)
}
#endif
