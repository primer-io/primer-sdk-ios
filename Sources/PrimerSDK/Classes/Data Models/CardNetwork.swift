//
//  CardNetwork.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_body_length

import Foundation
import PassKit
@_spi(PrimerInternal) import PrimerFoundation
import UIKit
@_spi(PrimerInternal) import PrimerCore

extension CardNetwork {

    public var displayName: String {
        if let displayName = self.validation?.niceType {
            return displayName
        }

        switch self {
        case .bancontact:
            return "Bancontact"
        case .cartesBancaires:
            return "Cartes Bancaires"
        case .eftpos:
            return "EFTPOS"
        default:
            return "Unknown"
        }
    }

    public var icon: UIImage? {
        switch self {
        case .amex: .amexColored
        case .bancontact: .bancontact
        case .cartesBancaires: .cartesBancairesColored
        case .discover: .discoverColored
        case .jcb: .jcb
        case .masterCard: .masterCardColored
        case .visa: .visaColored
        case .eftpos: .eftposColored
        case .diners, .elo, .hiper, .hipercard, .maestro, .mir, .unionpay, .unknown: .genericCard
        }
    }

    public var traits: PrimerCardNetworkTraits? {
        validation.map {
            PrimerCardNetworkTraits(
                cardNetwork: self,
                displayName: $0.niceType,
                panLengths: $0.lengths,
                gapPattern: $0.gaps,
                cvvLength: $0.code.length,
                cvvLabel: $0.code.name
            )
        }
    }

    var surcharge: Int? {
        guard let options = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.paymentMethod?.options,
              !options.isEmpty else { return nil }

        for paymentMethodOption in options {
            guard let type = paymentMethodOption["type"] as? String,
                  type == PrimerPaymentMethodType.paymentCard.rawValue
            else { continue }

            guard let networks = paymentMethodOption["networks"] as? [[String: Any]]
            else { continue }

            guard let tmpNetwork = networks
                .filter({ $0["type"] as? String == self.rawValue.uppercased() })
                .first
            else { continue }
            guard let surcharge = tmpNetwork["surcharge"] as? Int else { continue }
            guard surcharge > 0 else { continue }
            return surcharge
        }

        return nil
    }

    /// Determines whether this card network allows user selection in co-badged scenarios
    /// Returns false for local networks (like EFTPOS) that should auto-route
    var allowsUserSelection: Bool {
        ![CardNetwork].selectionDisallowedCardNetworks.contains(self)
    }

    var assetName: String {
        rawValue.lowercased().filter(\.isLetter)
    }

    public init(cardNetworkStr: String) {
        self = .unknown

        let stringValue = cardNetworkStr.uppercased()

        if ["DINERS", "DINERSCLUB"].contains(stringValue) {
            self = .diners
            return
        }

        if "CARTESBANCAIRES" == stringValue {
            self = .cartesBancaires
            return
        }

        if let cardNetwork = CardNetwork(rawValue: stringValue) {
            self = cardNetwork
        }
    }
}

extension [CardNetwork]: @retroactive LogReporter {

    /// A list of card networks that the merchant supports
    static var allowedCardNetworks: Self {
        let session = PrimerAPIConfiguration.current?.clientSession
        guard let networkStrings = session?.paymentMethod?.orderedAllowedCardNetworks
        else {
            logger.warn(message: "Expected allowed networks to be present in client session")
            return []
        }
        return networkStrings.compactMap { CardNetwork(rawValue: $0) }
    }

    /// A set of card networks that disallow user selection in co-badged scenarios
    /// When detected, the first network from merchant's orderedAllowedCardNetworks will be auto-selected
    /// instead of showing a dropdown selector
    static var selectionDisallowedCardNetworks: Set<CardNetwork> {
        [.eftpos]
    }

    /// A list of all card networks, used by default when a merchant does not specify the networks they support
    /// Also used to configure suppoted networks for Apple Pay
    static var allCardNetworks: Self {
        Element.allCases
    }
}
// swiftlint:enable type_body_length
