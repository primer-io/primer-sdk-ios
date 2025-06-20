//
//  CardNetworkIconsView.swift
//  PrimerSDK
//
//  Created by Claude Code on 25.03.2025.
//

import SwiftUI

@available(iOS 15.0, *)
internal struct CardNetworkIconsView: View {
    let animationConfig: CardPaymentAnimationConfiguration

    @Environment(\.designTokens) private var tokens
    @State private var isVisible = false

    init(animationConfig: CardPaymentAnimationConfiguration = .default) {
        self.animationConfig = animationConfig
    }

    // Card networks data with system symbol names and colors
    private let cardNetworks: [(String, String, Color)] = [
        ("creditcard", CardPaymentLocalizable.mastercardName, Color.red),
        ("creditcard.fill", CardPaymentLocalizable.visaCardName, Color.blue),
        ("creditcard.trianglebadge.exclamationmark", CardPaymentLocalizable.cbName, Color.green),
        ("creditcard.and.123", CardPaymentLocalizable.discoverName, Color.orange),
        ("person.crop.circle.dashed", CardPaymentLocalizable.dinersName, Color.purple)
    ]

    var body: some View {
        HStack(spacing: CardPaymentDesign.cardNetworkIconsSpacing(from: tokens)) {
            ForEach(Array(cardNetworks.enumerated()), id: \.offset) { index, cardNetwork in
                let (systemName, accessibilityLabel, iconColor) = cardNetwork

                ZStack {
                    // Background circle
                    Circle()
                        .fill(tokens?.primerColorGray100 ?? Color.gray.opacity(0.1))
                        .frame(
                            width: CardPaymentDesign.cardNetworkIconSize(from: tokens),
                            height: CardPaymentDesign.cardNetworkIconSize(from: tokens)
                        )

                    // Card network icon
                    Image(systemName: systemName)
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(iconColor.opacity(0.8))
                }
                .scaleEffect(isVisible ? 1.0 : CardPaymentAnimationConfig.iconEntranceScale)
                .opacity(isVisible ? 1.0 : 0.0)
                .animation(
                    animationConfig.entranceAnimation()?.delay(
                        CardPaymentAnimationConfig.iconEntranceDelay(for: index)
                    ),
                    value: isVisible
                )
                .accessibilityIdentifier("card_payment_card_network_\(index)")
                .accessibilityLabel(accessibilityLabel)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("card_payment_card_networks_container")
        .accessibilityLabel(CardPaymentLocalizable.cardNetworkIconsDescription)
        .onAppear {
            if animationConfig.enableEntranceAnimations {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isVisible = true
                }
            } else {
                isVisible = true
            }
        }
    }
}

// MARK: - Alternative implementation with actual card logos (for when assets are available)
@available(iOS 15.0, *)
internal struct CardNetworkIconsViewWithAssets: View {
    let animationConfig: CardPaymentAnimationConfiguration

    @Environment(\.designTokens) private var tokens
    @State private var isVisible = false

    init(animationConfig: CardPaymentAnimationConfiguration = .default) {
        self.animationConfig = animationConfig
    }

    // Card networks data with asset names (would be used when actual assets are available)
    private let cardNetworks: [(String, String)] = [
        ("mastercard_logo", CardPaymentLocalizable.mastercardName),
        ("visa_logo", CardPaymentLocalizable.visaCardName),
        ("cb_logo", CardPaymentLocalizable.cbName),
        ("discover_logo", CardPaymentLocalizable.discoverName),
        ("diners_logo", CardPaymentLocalizable.dinersName)
    ]

    var body: some View {
        HStack(spacing: CardPaymentDesign.cardNetworkIconsSpacing(from: tokens)) {
            ForEach(Array(cardNetworks.enumerated()), id: \.offset) { index, cardNetwork in
                let (assetName, accessibilityLabel) = cardNetwork

                // Placeholder for actual card network logos
                RoundedRectangle(cornerRadius: CardPaymentDesign.cardNetworkIconCornerRadius(from: tokens))
                    .fill(tokens?.primerColorGray200 ?? Color.gray.opacity(0.2))
                    .frame(
                        width: CardPaymentDesign.cardNetworkIconSize(from: tokens),
                        height: CardPaymentDesign.cardNetworkIconSize(from: tokens) * 0.6
                    )
                    .overlay(
                        // This would be replaced with:
                        // Image(assetName, bundle: .primerSDK)
                        Text(String(accessibilityLabel.prefix(2)))
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(tokens?.primerColorTextSecondary ?? .secondary)
                    )
                    .scaleEffect(isVisible ? 1.0 : CardPaymentAnimationConfig.iconEntranceScale)
                    .opacity(isVisible ? 1.0 : 0.0)
                    .animation(
                        animationConfig.entranceAnimation()?.delay(
                            CardPaymentAnimationConfig.iconEntranceDelay(for: index)
                        ),
                        value: isVisible
                    )
                    .accessibilityIdentifier("card_payment_card_network_\(index)")
                    .accessibilityLabel(accessibilityLabel)
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("card_payment_card_networks_container")
        .accessibilityLabel(CardPaymentLocalizable.cardNetworkIconsDescription)
        .onAppear {
            if animationConfig.enableEntranceAnimations {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isVisible = true
                }
            } else {
                isVisible = true
            }
        }
    }
}

// MARK: - Card Network Type for Dynamic Display
@available(iOS 15.0, *)
internal enum CardNetworkType: String, CaseIterable {
    case visa
    case mastercard
    case amex
    case discover
    case dinersClub
    case cb
    case unknown

    var displayName: String {
        switch self {
        case .visa: return CardPaymentLocalizable.visaCardName
        case .mastercard: return CardPaymentLocalizable.mastercardName
        case .amex: return CardPaymentLocalizable.amexName
        case .discover: return CardPaymentLocalizable.discoverName
        case .dinersClub: return CardPaymentLocalizable.dinersName
        case .cb: return CardPaymentLocalizable.cbName
        case .unknown: return CardPaymentLocalizable.unknownCardName
        }
    }

    var systemIconName: String {
        switch self {
        case .visa: return "creditcard.fill"
        case .mastercard: return "creditcard"
        case .amex: return "creditcard.trianglebadge.exclamationmark"
        case .discover: return "creditcard.and.123"
        case .dinersClub: return "person.crop.circle.dashed"
        case .cb: return "creditcard.trianglebadge.exclamationmark"
        case .unknown: return "creditcard"
        }
    }

    var brandColor: Color {
        switch self {
        case .visa: return Color.blue
        case .mastercard: return Color.red
        case .amex: return Color.blue
        case .discover: return Color.orange
        case .dinersClub: return Color.purple
        case .cb: return Color.green
        case .unknown: return Color.gray
        }
    }
}

// MARK: - Dynamic Card Network Icons View (shows detected network prominently)
@available(iOS 15.0, *)
internal struct DynamicCardNetworkIconsView: View {
    let detectedNetwork: CardNetworkType?
    let animationConfig: CardPaymentAnimationConfiguration

    @Environment(\.designTokens) private var tokens
    @State private var isVisible = false

    init(
        detectedNetwork: CardNetworkType? = nil,
        animationConfig: CardPaymentAnimationConfiguration = .default
    ) {
        self.detectedNetwork = detectedNetwork
        self.animationConfig = animationConfig
    }

    var body: some View {
        HStack(spacing: CardPaymentDesign.cardNetworkIconsSpacing(from: tokens)) {
            ForEach(Array(CardNetworkType.allCases.enumerated()), id: \.offset) { index, network in
                let isDetected = network == detectedNetwork
                let iconSize = CardPaymentDesign.cardNetworkIconSize(from: tokens)

                ZStack {
                    // Background
                    Circle()
                        .fill(isDetected ?
                                (tokens?.primerColorBrand ?? Color.blue).opacity(0.1) :
                                (tokens?.primerColorGray100 ?? Color.gray.opacity(0.1))
                        )
                        .frame(width: iconSize, height: iconSize)

                    // Icon
                    Image(systemName: network.systemIconName)
                        .font(.system(size: 14, weight: isDetected ? .semibold : .medium))
                        .foregroundColor(isDetected ?
                                            (tokens?.primerColorBrand ?? network.brandColor) :
                                            network.brandColor.opacity(0.6)
                        )
                }
                .scaleEffect(isDetected ? 1.1 : 1.0)
                .scaleEffect(isVisible ? 1.0 : CardPaymentAnimationConfig.iconEntranceScale)
                .opacity(isVisible ? (isDetected ? 1.0 : 0.7) : 0.0)
                .animation(
                    animationConfig.entranceAnimation()?.delay(
                        CardPaymentAnimationConfig.iconEntranceDelay(for: index)
                    ),
                    value: isVisible
                )
                .animation(animationConfig.fieldFocusAnimation(), value: detectedNetwork)
                .accessibilityIdentifier("card_payment_card_network_\(network.rawValue)")
                .accessibilityLabel(network.displayName)
                .accessibilityHint(isDetected ? "Currently detected card type" : "Supported card type")
            }
        }
        .accessibilityElement(children: .combine)
        .accessibilityIdentifier("card_payment_card_networks_container")
        .accessibilityLabel(CardPaymentLocalizable.cardNetworkIconsDescription)
        .onAppear {
            if animationConfig.enableEntranceAnimations {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isVisible = true
                }
            } else {
                isVisible = true
            }
        }
    }
}

// MARK: - Preview Provider
@available(iOS 15.0, *)
struct CardNetworkIconsView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 40) {
            VStack {
                Text("System Icons")
                    .font(.headline)
                CardNetworkIconsView()
            }

            VStack {
                Text("Asset Placeholders")
                    .font(.headline)
                CardNetworkIconsViewWithAssets()
            }

            VStack {
                Text("Dynamic (Visa Detected)")
                    .font(.headline)
                DynamicCardNetworkIconsView(detectedNetwork: .visa)
            }

            VStack {
                Text("No Animations")
                    .font(.headline)
                CardNetworkIconsView(animationConfig: .disabled)
            }
        }
        .padding()
        .previewDisplayName("Card Network Icons")
    }
}
