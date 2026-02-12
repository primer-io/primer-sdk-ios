//
//  PrimerCardValidationModels.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@objc
public protocol PrimerValidationState {}

@objc
public protocol PrimerPaymentMethodMetadata {}

@objc
public enum PrimerCardValidationSource: Int {
    case local
    case localFallback
    case remote
}

@objc
public final class PrimerCardNumberEntryState: NSObject, PrimerValidationState {
    public let cardNumber: String

    init(cardNumber: String) {
        self.cardNumber = cardNumber
    }
}

/// Represents a detected card network with display information and merchant allowance status.
///
/// `PrimerCardNetwork` wraps a `CardNetwork` enum value with additional context useful
/// for UI display, including the human-readable name and whether the merchant supports
/// this network for payments.
///
/// This class is used in co-badged card scenarios where multiple networks are detected
/// and the user may need to select which network to use.
///
/// Example usage:
/// ```swift
/// let networks = metadata.selectableCardNetworks?.items ?? []
/// for network in networks {
///     print("\(network.displayName) - Allowed: \(network.allowed)")
/// }
/// ```
@objc
public final class PrimerCardNetwork: NSObject {
    public let displayName: String
    public let network: CardNetwork
    public let issuerCountryCode: String?
    public let issuerName: String?
    public let accountFundingType: String?
    public let prepaidReloadableIndicator: String?
    public let productUsageType: String?
    public let productCode: String?
    public let productName: String?
    public let issuerCurrencyCode: String?
    public let regionalRestriction: String?
    public let accountNumberType: String?

    public var allowed: Bool {
        [CardNetwork].allowedCardNetworks.contains(network)
    }

    init(displayName: String,
         network: CardNetwork,
         issuerCountryCode: String? = nil,
         issuerName: String? = nil,
         accountFundingType: String? = nil,
         prepaidReloadableIndicator: String? = nil,
         productUsageType: String? = nil,
         productCode: String? = nil,
         productName: String? = nil,
         issuerCurrencyCode: String? = nil,
         regionalRestriction: String? = nil,
         accountNumberType: String? = nil) {
        self.displayName = displayName
        self.network = network
        self.issuerCountryCode = issuerCountryCode
        self.issuerName = issuerName
        self.accountFundingType = accountFundingType
        self.prepaidReloadableIndicator = prepaidReloadableIndicator
        self.productUsageType = productUsageType
        self.productCode = productCode
        self.productName = productName
        self.issuerCurrencyCode = issuerCurrencyCode
        self.regionalRestriction = regionalRestriction
        self.accountNumberType = accountNumberType
    }

    convenience init(network: CardNetwork) {
        self.init(
            displayName: network.displayName,
            network: network
        )
    }

    convenience init?(network: CardNetwork?) {
        guard let network = network else { return nil }
        self.init(network: network)
    }

    override public var description: String {
        "PrimerCardNetwork(displayName: \(displayName), network: \(network), allowed: \(allowed))"
    }
}

@objc
public final class PrimerCardNetworksMetadata: NSObject {
    public let items: [PrimerCardNetwork]
    public let preferred: PrimerCardNetwork?

    init(items: [PrimerCardNetwork], preferred: PrimerCardNetwork?) {
        self.items = items
        self.preferred = preferred
    }
}

@objc
public final class PrimerCardNumberEntryMetadata: NSObject, PrimerPaymentMethodMetadata {

    public let source: PrimerCardValidationSource

    public let selectableCardNetworks: PrimerCardNetworksMetadata?

    public let detectedCardNetworks: PrimerCardNetworksMetadata

    /// The automatically selected card network for co-badged cards with selection-disallowed networks (e.g., EFTPOS)
    /// This is set when a co-badged card contains a network that disallows user selection
    public let autoSelectedCardNetwork: PrimerCardNetwork?

    init(source: PrimerCardValidationSource,
         selectableCardNetworks: [PrimerCardNetwork]?,
         detectedCardNetworks: [PrimerCardNetwork],
         autoSelectedCardNetwork: PrimerCardNetwork? = nil) {
        self.source = source

        if source == .remote, let selectableCardNetworks = selectableCardNetworks, !selectableCardNetworks.isEmpty {
            self.selectableCardNetworks = PrimerCardNetworksMetadata(
                items: selectableCardNetworks,
                preferred: selectableCardNetworks.first
            )
        } else {
            self.selectableCardNetworks = nil
        }

        let preferredNetwork = [CardNetwork].allowedCardNetworks.first {
            detectedCardNetworks.map(\.network).contains($0)
        }
        self.detectedCardNetworks = PrimerCardNetworksMetadata(
            items: detectedCardNetworks,
            preferred: PrimerCardNetwork(network: preferredNetwork)
        )

        self.autoSelectedCardNetwork = autoSelectedCardNetwork
    }
}
