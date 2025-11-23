//
//  DropdownCardNetworkSelector.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A dropdown-style card network selector for co-badged cards.
/// Displays the selected network badge with a chevron, and shows a menu on tap.
@available(iOS 15.0, *)
struct DropdownCardNetworkSelector: View {
    // MARK: - Properties

    /// Available card networks to choose from
    let availableNetworks: [CardNetwork]

    /// Currently selected network
    @Binding var selectedNetwork: CardNetwork

    /// Callback when network is selected
    let onNetworkSelected: ((CardNetwork) -> Void)?

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        Menu {
            ForEach(availableNetworks, id: \.rawValue) { network in
                Button {
                    selectedNetwork = network
                    onNetworkSelected?(network)
                } label: {
                    Label {
                        Text(network.displayName)
                    } icon: {
                        if let icon = network.icon {
                            Image(uiImage: icon)
                        }
                    }
                }
            }
        } label: {
            HStack(spacing: PrimerSpacing.xsmall(tokens: tokens)) {
                CardNetworkBadge(
                    network: selectedNetwork,
                    width: PrimerCardNetworkSelector.badgeWidth,
                    height: PrimerCardNetworkSelector.badgeHeight
                )

                Image(systemName: "chevron.down")
                    .font(.system(size: 10, weight: .medium))
                    .frame(width: 20, height: 20, alignment: .center)
                    .foregroundColor(CheckoutColors.textPrimary(tokens: tokens))
            }
            .contentShape(Rectangle())
        }
        .accessibilityIdentifier(AccessibilityIdentifiers.CardForm.dropdownNetworkSelectorButton)
        .accessibilityLabel(CheckoutComponentsStrings.a11yDropdownNetworkSelectorLabel)
        .accessibilityHint(CheckoutComponentsStrings.a11yDropdownNetworkSelectorHint)
    }
}

// MARK: - Previews

#if DEBUG
@available(iOS 15.0, *)
private struct DropdownCardNetworkSelectorPreviewWrapper: View {
    let networks: [CardNetwork]
    @State private var selected: CardNetwork

    init(networks: [CardNetwork]) {
        self.networks = networks
        _selected = State(initialValue: networks.first ?? .unknown)
    }

    var body: some View {
        DropdownCardNetworkSelector(
            availableNetworks: networks,
            selectedNetwork: $selected,
            onNetworkSelected: { network in
                print("Selected: \(network.displayName)")
            }
        )
    }
}

@available(iOS 15.0, *)
#Preview("Light Mode - Two Networks") {
    DropdownCardNetworkSelectorPreviewWrapper(networks: [.visa, .masterCard])
        .padding()
        .environment(\.designTokens, MockDesignTokens.light)
}

@available(iOS 15.0, *)
#Preview("Dark Mode - Two Networks") {
    DropdownCardNetworkSelectorPreviewWrapper(networks: [.visa, .masterCard])
        .padding()
        .background(Color.black)
        .environment(\.designTokens, MockDesignTokens.dark)
        .preferredColorScheme(.dark)
}

@available(iOS 15.0, *)
#Preview("Light Mode - Three Networks") {
    DropdownCardNetworkSelectorPreviewWrapper(networks: [.visa, .masterCard, .cartesBancaires])
        .padding()
        .environment(\.designTokens, MockDesignTokens.light)
}
#endif
