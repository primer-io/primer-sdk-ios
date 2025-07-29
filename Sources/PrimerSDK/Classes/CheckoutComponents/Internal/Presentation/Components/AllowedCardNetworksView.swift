//
//  AllowedCardNetworksView.swift
//  PrimerSDK - CheckoutComponents
//
//  Created by Boris on 16.7.25.
//

import SwiftUI

/// A SwiftUI component that displays a row of allowed card network badges
/// as per Figma design requirements.
@available(iOS 15.0, *)
internal struct AllowedCardNetworksView: View, LogReporter {

    // MARK: - Properties

    /// The array of allowed card networks to display
    let allowedCardNetworks: [CardNetwork]

    // MARK: - Environment

    @Environment(\.designTokens) private var tokens

    // MARK: - Initialization

    /// Creates a new AllowedCardNetworksView with the specified card networks
    /// - Parameter allowedCardNetworks: The array of card networks to display as badges
    internal init(allowedCardNetworks: [CardNetwork]) {
        self.allowedCardNetworks = allowedCardNetworks
    }

    // MARK: - Body

    var body: some View {
        if !allowedCardNetworks.isEmpty {
            HStack(spacing: FigmaDesignConstants.cardBadgeSpacing) {
                ForEach(allowedCardNetworks, id: \.self) { network in
                    CardNetworkBadge(network: network)
                }
                Spacer()
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

}

/// Individual card network badge component
@available(iOS 15.0, *)
private struct CardNetworkBadge: View, LogReporter {

    // MARK: - Properties

    let network: CardNetwork

    // MARK: - Environment

    @Environment(\.designTokens) private var tokens

    // MARK: - Body

    var body: some View {
        Group {
            if let icon = network.icon {
                // Use actual network icon
                Image(uiImage: icon)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: FigmaDesignConstants.cardBadgeWidth, height: FigmaDesignConstants.cardBadgeHeight)
                    .padding(2)
                    .cornerRadius(FigmaDesignConstants.cardBadgeRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: FigmaDesignConstants.cardBadgeRadius)
                            .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                    )
            } else {
                // Fallback for networks without icons
                Text(network.displayName.prefix(2).uppercased())
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.primary)
                    .frame(width: FigmaDesignConstants.cardBadgeWidth, height: FigmaDesignConstants.cardBadgeHeight)
                    .cornerRadius(FigmaDesignConstants.cardBadgeRadius)
                    .overlay(
                        RoundedRectangle(cornerRadius: FigmaDesignConstants.cardBadgeRadius)
                            .stroke(Color.black.opacity(0.1), lineWidth: 0.5)
                    )
            }
        }
    }
}

// MARK: - Preview Support

#if DEBUG
@available(iOS 15.0, *)
struct AllowedCardNetworksView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            // Example with common card networks
            AllowedCardNetworksView(allowedCardNetworks: [
                .visa,
                .masterCard,
                .amex,
                .discover,
                .diners,
                .unionpay,
                .mir,
                .maestro,
                .jcb
            ])
            .padding()
            .background(Color.white)
            .cornerRadius(8)

            // Example with fewer networks
            AllowedCardNetworksView(allowedCardNetworks: [
                .visa,
                .masterCard,
                .amex
            ])
            .padding()
            .background(Color.white)
            .cornerRadius(8)
        }
        .padding()
        .background(Color(.systemGray6))
        .previewLayout(.sizeThatFits)
    }
}
#endif
