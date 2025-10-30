//
//  CardNetworkSelector.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A SwiftUI component for selecting between co-badged card networks
@available(iOS 15.0, *)
struct CardNetworkSelector: View {
    // MARK: - Properties

    /// Available card networks to choose from
    let availableNetworks: [CardNetwork]

    /// Currently selected network
    @Binding var selectedNetwork: CardNetwork

    /// Callback when network is selected
    let onNetworkSelected: ((CardNetwork) -> Void)?

    @State private var isExpanded = false
    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Selected network button
            Button(action: {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            }, label: {
                HStack {
                    CardNetworkBadge(network: selectedNetwork)

                    Text(selectedNetwork.displayName)
                        .font(PrimerFont.body(tokens: tokens))
                        .foregroundColor(PrimerCheckoutColors.primary(tokens: tokens))

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(PrimerCheckoutColors.secondary(tokens: tokens))
                        .font(PrimerFont.caption(tokens: tokens))
                }
                .padding(.horizontal, PrimerSpacing.medium(tokens: tokens))
                .padding(.vertical, PrimerSpacing.small(tokens: tokens))
                .background(PrimerCheckoutColors.gray100(tokens: tokens))
                .cornerRadius(PrimerRadius.small(tokens: tokens))
            })

            // Dropdown list
            if isExpanded {
                VStack(spacing: 0) {
                    ForEach(availableNetworks, id: \.rawValue) { network in
                        if network != selectedNetwork {
                            Button(action: {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    selectedNetwork = network
                                    isExpanded = false
                                    onNetworkSelected?(network)
                                }
                            }, label: {
                                HStack {
                                    CardNetworkBadge(network: network)

                                    Text(network.displayName)
                                        .font(PrimerFont.body(tokens: tokens))
                                        .foregroundColor(PrimerCheckoutColors.primary(tokens: tokens))

                                    Spacer()
                                }
                                .padding(.horizontal, PrimerSpacing.medium(tokens: tokens))
                                .padding(.vertical, PrimerSpacing.small(tokens: tokens))
                                .background(PrimerCheckoutColors.clear(tokens: tokens))
                            })
                            .buttonStyle(PlainButtonStyle())

                            if network != availableNetworks.last {
                                Divider()
                                    .padding(.horizontal, PrimerSpacing.medium(tokens: tokens))
                            }
                        }
                    }
                }
                .background(PrimerCheckoutColors.gray100(tokens: tokens))
                .cornerRadius(PrimerRadius.small(tokens: tokens))
                .shadow(
                    color: PrimerCheckoutColors.borderDefault(tokens: tokens),
                    radius: PrimerRadius.small(tokens: tokens),
                    x: 0,
                    y: PrimerSpacing.xxsmall(tokens: tokens)
                )
                .padding(.top, PrimerSpacing.xsmall(tokens: tokens))
            }
        }
    }
}
