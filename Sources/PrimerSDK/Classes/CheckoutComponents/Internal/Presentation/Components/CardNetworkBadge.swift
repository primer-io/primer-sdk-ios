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

    // MARK: - Environment

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    @ViewBuilder
    var body: some View {
        if let icon = network.icon {
            Image(uiImage: icon)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width: PrimerSize.large(tokens: tokens), height: PrimerSize.small(tokens: tokens))
                .cornerRadius(PrimerRadius.xsmall(tokens: tokens))
        } else {
            Text(network.displayName.prefix(2).uppercased())
                .font(PrimerFont.smallBadge(tokens: tokens))
                .foregroundColor(CheckoutColors.primary(tokens: tokens))
                .frame(width: PrimerSize.large(tokens: tokens), height: PrimerSize.small(tokens: tokens))
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
    struct CardNetworkBadge_Previews: PreviewProvider {
        static var previews: some View {
            Group {
                // Light mode
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
                .previewDisplayName("Light Mode")

                // Dark mode
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
                .previewDisplayName("Dark Mode")
            }
        }
    }
#endif
