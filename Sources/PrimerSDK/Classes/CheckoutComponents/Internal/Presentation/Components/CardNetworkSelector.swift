//
//  CardNetworkSelector.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 23.6.25.
//

import SwiftUI

/// A SwiftUI component for selecting between co-badged card networks
@available(iOS 15.0, *)
internal struct CardNetworkSelector: View {
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
            }) {
                HStack {
                    if let icon = selectedNetwork.icon {
                        Image(uiImage: icon)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 24)
                    }

                    Text(selectedNetwork.displayName)
                        .font(.body)
                        .foregroundColor(.primary)

                    Spacer()

                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(tokens?.primerColorGray100 ?? Color(.systemGray6))
                .cornerRadius(8)
            }

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
                            }) {
                                HStack {
                                    if let icon = network.icon {
                                        Image(uiImage: icon)
                                            .resizable()
                                            .aspectRatio(contentMode: .fit)
                                            .frame(height: 24)
                                    }

                                    Text(network.displayName)
                                        .font(.body)
                                        .foregroundColor(.primary)

                                    Spacer()
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color.clear)
                            }
                            .buttonStyle(PlainButtonStyle())

                            if network != availableNetworks.last {
                                Divider()
                                    .padding(.horizontal, 12)
                            }
                        }
                    }
                }
                .background(tokens?.primerColorGray100 ?? Color(.systemGray5))
                .cornerRadius(8)
                .shadow(color: Color.black.opacity(0.1), radius: 4, x: 0, y: 2)
                .padding(.top, 4)
            }
        }
    }
}

/// Preview provider for SwiftUI previews
@available(iOS 15.0, *)
struct CardNetworkSelector_Previews: PreviewProvider {
    static var previews: some View {
        VStack {
            CardNetworkSelector(
                availableNetworks: [.cartesBancaires, .visa],
                selectedNetwork: .constant(.cartesBancaires),
                onNetworkSelected: nil
            )
            .padding()
        }
    }
}
