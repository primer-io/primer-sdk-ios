//
//  AllowedCardNetworksView.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A SwiftUI component that displays a row of allowed card network badges
/// as per Figma design requirements.
@available(iOS 15.0, *)
struct AllowedCardNetworksView: View, LogReporter {

    // MARK: - Properties

    /// The array of allowed card networks to display
    let allowedCardNetworks: [CardNetwork]

    // MARK: - Environment

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    /// Creates a new AllowedCardNetworksView with the specified card networks
    /// - Parameter allowedCardNetworks: The array of card networks to display as badges
    init(allowedCardNetworks: [CardNetwork]) {
        self.allowedCardNetworks = allowedCardNetworks
    }

    // MARK: - Body

    var body: some View {
        if !allowedCardNetworks.isEmpty {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                    ForEach(allowedCardNetworks, id: \.self) { network in
                        CardNetworkBadge(network: network)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

}
