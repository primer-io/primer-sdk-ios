//
//  DualBadgeDisplay.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A non-interactive SwiftUI component that displays multiple card network badges
/// side by side for co-badged cards when user selection is disallowed.
///
/// This component is used when one of the detected card networks (e.g., EFTPOS)
/// does not allow user selection. In this case, the merchant's preferred network
/// is auto-selected and this view simply displays all available networks
/// without any interaction capability.
///
/// Usage:
/// ```swift
/// DualBadgeDisplay(networks: [.visa, .eftpos])
/// ```
@available(iOS 15.0, *)
struct DualBadgeDisplay: View {
    // MARK: - Properties

    let networks: [CardNetwork]

    // MARK: - Private Properties

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        HStack(spacing: PrimerSpacing.small(tokens: tokens)) {
            ForEach(networks, id: \.self) { network in
                CardNetworkBadge(network: network)
            }
        }
        .allowsHitTesting(false)
    }
}

// MARK: - Previews

#if DEBUG
    @available(iOS 15.0, *)
    #Preview("Light Mode") {
        VStack(spacing: 16) {
            DualBadgeDisplay(networks: [.visa, .eftpos])
            DualBadgeDisplay(networks: [.masterCard, .eftpos])
        }
        .padding()
        .environment(\.designTokens, MockDesignTokens.light)
    }

    @available(iOS 15.0, *)
    #Preview("Dark Mode") {
        VStack(spacing: 16) {
            DualBadgeDisplay(networks: [.visa, .eftpos])
            DualBadgeDisplay(networks: [.masterCard, .eftpos])
        }
        .padding()
        .background(Color.black)
        .environment(\.designTokens, MockDesignTokens.dark)
        .preferredColorScheme(.dark)
    }
#endif
