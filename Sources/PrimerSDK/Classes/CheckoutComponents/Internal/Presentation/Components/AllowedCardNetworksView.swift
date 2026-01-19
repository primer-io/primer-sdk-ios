//
//  AllowedCardNetworksView.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct AllowedCardNetworksView: View, LogReporter {

    // MARK: - Properties

    let allowedCardNetworks: [CardNetwork]

    // MARK: - Environment

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

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
            .accessibilityHidden(true)
        }
    }

}
