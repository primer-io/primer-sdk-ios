//
//  CardNetworkSelector.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

/// A SwiftUI component for selecting between co-badged card networks using a segmented control
@available(iOS 15.0, *)
struct CardNetworkSelector: View {
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
        HStack(spacing: 0) {
            HStack(spacing: 0) {
                ForEach(Array(availableNetworks.enumerated()), id: \.element.rawValue) { index, network in
                    NetworkButton(
                        network: network,
                        isSelected: selectedNetwork == network,
                        isFirst: index == 0,
                        isLast: index == availableNetworks.count - 1,
                        tokens: tokens
                    ) {
                        selectedNetwork = network
                        onNetworkSelected?(network)
                    }
                    .id(network.rawValue)

                    // Add divider between items (but not after the last one)
                    if index < availableNetworks.count - 1 {
                        Rectangle()
                            .fill(baseBorderColor)
                            .frame(width: PrimerBorderWidth.standard, height: PrimerCardNetworkSelector.buttonFrameHeight)
                    }
                }
            }
        }

        .padding(PrimerBorderWidth.standard)
        .overlay(
            RoundedRectangle(cornerRadius: PrimerRadius.small(tokens: tokens))
                .strokeBorder(baseBorderColor, lineWidth: PrimerBorderWidth.standard)
        )
        .overlay(
            GeometryReader { _ in
                if let selectedIndex = availableNetworks.firstIndex(of: selectedNetwork) {
                    let xOffset = getOffset(selectedIndex: selectedIndex)

                    RoundedCorners(
                        topLeft: selectedIndex == 0 ? PrimerRadius.small(tokens: tokens) : 0,
                        topRight: selectedIndex == availableNetworks.count - 1 ? PrimerRadius.small(tokens: tokens) : 0,
                        bottomLeft: selectedIndex == 0 ? PrimerRadius.small(tokens: tokens) : 0,
                        bottomRight: selectedIndex == availableNetworks.count - 1 ? PrimerRadius.small(tokens: tokens) : 0
                    )
                    .strokeBorder(selectedBorderColor, lineWidth: PrimerBorderWidth.standard)
                    .frame(width: buttonWidth, height: PrimerCardNetworkSelector.selectedBorderHeight)
                    .offset(x: xOffset)
                }
            }
        )
    }

    func getOffset(selectedIndex: Int) -> CGFloat {
        guard selectedIndex > 0 else { return 0 }
        return CGFloat(selectedIndex) * (PrimerCardNetworkSelector.buttonFrameWidth + borderWidth)
    }

    private var borderWidth: CGFloat {
        PrimerBorderWidth.standard
    }

    private var buttonWidth: CGFloat {
        PrimerCardNetworkSelector.buttonTotalWidth
    }

    private var selectedBorderColor: Color {
        CheckoutColors.gray700(tokens: tokens)
    }

    private var baseBorderColor: Color {
        CheckoutColors.gray300(tokens: tokens)
    }
}

#if DEBUG

// MARK: - Preview

@available(iOS 15.0, *)
#Preview("Light Mode - 2 Networks") {
    VStack(spacing: 20) {
        Text("Co-badged Card Networks")
            .font(.headline)

        CardNetworkSelector(
            availableNetworks: [.visa, .cartesBancaires],
            selectedNetwork: .constant(.visa),
            onNetworkSelected: { network in
                print("Selected: \(network.displayName)")
            }
        )
        .padding()
    }
    .environment(\.designTokens, MockDesignTokens.light)
}

@available(iOS 15.0, *)
#Preview("Dark Mode - 2 Networks") {
    VStack(spacing: 20) {
        Text("Co-badged Card Networks")
            .font(.headline)
            .foregroundColor(.white)

        CardNetworkSelector(
            availableNetworks: [.visa, .cartesBancaires],
            selectedNetwork: .constant(.cartesBancaires),
            onNetworkSelected: { network in
                print("Selected: \(network.displayName)")
            }
        )
        .padding()
    }
    .background(Color.black)
    .environment(\.designTokens, MockDesignTokens.dark)
    .preferredColorScheme(.dark)
}

@available(iOS 15.0, *)
#Preview("Light Mode - 3 Networks") {
    VStack(spacing: 20) {
        Text("Multiple Networks")
            .font(.headline)

        CardNetworkSelector(
            availableNetworks: [.visa, .masterCard, .cartesBancaires],
            selectedNetwork: .constant(.masterCard),
            onNetworkSelected: { network in
                print("Selected: \(network.displayName)")
            }
        )
        .padding()
    }
    .environment(\.designTokens, MockDesignTokens.light)
}

@available(iOS 15.0, *)
#Preview("Light Mode - 5 Networks") {
    VStack(spacing: 20) {
        Text("Five Networks")
            .font(.headline)

        CardNetworkSelector(
            availableNetworks: [.visa, .masterCard, .cartesBancaires, .amex, .discover],
            selectedNetwork: .constant(.cartesBancaires),
            onNetworkSelected: { network in
                print("Selected: \(network.displayName)")
            }
        )
        .padding()
    }
    .environment(\.designTokens, MockDesignTokens.light)
}
#endif
