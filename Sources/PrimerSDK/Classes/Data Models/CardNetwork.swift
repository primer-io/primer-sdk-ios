//
//  CardNetwork.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_body_length

import Foundation
import PassKit
import UIKit

struct CardNetworkValidation {
    var niceType: String
    var patterns: [[Int]]
    var gaps: [Int]
    var lengths: [Int]
    var code: CardNetworkCode
}

struct CardNetworkCode {
    var name: String
    var length: Int
}

public enum CardNetwork: String, Codable, CaseIterable, LogReporter {

    // https://github.com/primer-io/platform/blob/59980a07113089000c9814b079579e15c616b6db/platform/commons/models/bin_range.py#L66
    case amex = "AMEX"
    case bancontact = "BANCONTACT"
    case cartesBancaires = "CARTES_BANCAIRES"
    case diners = "DINERS_CLUB"
    case discover = "DISCOVER"
    case eftpos = "EFTPOS"
    case elo = "ELO"
    case hiper = "HIPER"
    case hipercard = "HIPERCARD"
    case jcb = "JCB"
    case maestro = "MAESTRO"
    case masterCard = "MASTERCARD"
    case mir = "MIR"
    case visa = "VISA"
    case unionpay = "UNIONPAY"
    case unknown = "OTHER" // or "UNKNOWN"

    var validation: CardNetworkValidation? {
        switch self {
        case .amex:
            return CardNetworkValidation(
                niceType: "American Express",
                patterns: [[34], [37]],
                gaps: [4, 10],
                lengths: [15],
                code: CardNetworkCode(
                    name: "CID",
                    length: 4))

        case .bancontact, .cartesBancaires, .eftpos:
            return nil

        case .diners:
            return CardNetworkValidation(
                niceType: "Diners",
                patterns: [[300, 305], [36], [38], [39]],
                gaps: [4, 10],
                lengths: [14, 16, 19],
                code: CardNetworkCode(
                    name: "CVV",
                    length: 3))

        case .discover:
            return CardNetworkValidation(
                niceType: "Discover",
                patterns: [[6011], [644, 649], [65]],
                gaps: [4, 8, 12],
                lengths: [16, 19],
                code: CardNetworkCode(
                    name: "CID",
                    length: 3))

        case .elo:
            return CardNetworkValidation(
                niceType: "Elo",
                patterns: [
                    [401178],
                    [401179],
                    [438935],
                    [457631],
                    [457632],
                    [431274],
                    [451416],
                    [457393],
                    [504175],
                    [506699, 506778],
                    [509000, 509999],
                    [627780],
                    [636297],
                    [636368],
                    [650031, 650033],
                    [650035, 650051],
                    [650405, 650439],
                    [650485, 650538],
                    [650541, 650598],
                    [650700, 650718],
                    [650720, 650727],
                    [650901, 650978],
                    [651652, 651679],
                    [655000, 655019],
                    [655021, 655058]
                ],
                gaps: [4, 8, 12],
                lengths: [16],
                code: CardNetworkCode(
                    name: "CVE",
                    length: 3))

        case .hiper:
            return CardNetworkValidation(
                niceType: "Hiper",
                patterns: [[637095], [63737423], [63743358], [637568], [637599], [637609], [637612]],
                gaps: [4, 8, 12],
                lengths: [16],
                code: CardNetworkCode(
                    name: "CVC",
                    length: 3))

        case .hipercard:
            return CardNetworkValidation(
                niceType: "Hiper",
                patterns: [[606282]],
                gaps: [4, 8, 12],
                lengths: [16],
                code: CardNetworkCode(
                    name: "CVC",
                    length: 3))

        case .jcb:
            return CardNetworkValidation(
                niceType: "JCB",
                patterns: [[2131], [1800], [3528, 3589]],
                gaps: [4, 8, 12],
                lengths: [16, 17, 18, 19],
                code: CardNetworkCode(
                    name: "CVV",
                    length: 3))

        case .masterCard:
            return CardNetworkValidation(
                niceType: "Mastercard",
                patterns: [[51, 55], [2221, 2229], [223, 229], [23, 26], [270, 271], [2720]],
                gaps: [4, 10],
                lengths: [16],
                code: CardNetworkCode(
                    name: "CVC",
                    length: 3))

        case .maestro:
            return CardNetworkValidation(
                niceType: "Maestro",
                patterns: [
                    [493698],
                    [500000, 504174],
                    [504176, 506698],
                    [506779, 508999],
                    [56, 59],
                    [63],
                    [67],
                    [6]
                ],
                gaps: [4, 8, 12],
                lengths: [16, 17, 18, 19],
                code: CardNetworkCode(
                    name: "CVC",
                    length: 3))

        case .mir:
            return CardNetworkValidation(
                niceType: "Mir",
                patterns: [[2200, 2204]],
                gaps: [4, 8, 12],
                lengths: [16, 17, 18, 19],
                code: CardNetworkCode(
                    name: "CVP2",
                    length: 3))

        case .visa:
            return CardNetworkValidation(
                niceType: "Visa",
                patterns: [[4]],
                gaps: [4, 8, 12],
                lengths: [16, 18, 19],
                code: CardNetworkCode(
                    name: "CVV",
                    length: 3))

        case .unionpay:
            return CardNetworkValidation(
                niceType: "UnionPay",
                patterns: [
                    [620],
                    [624, 626],
                    [62100, 62182],
                    [62184, 62187],
                    [62185, 62197],
                    [62200, 62205],
                    [622010, 622999],
                    [622018],
                    [622019, 622999],
                    [62207, 62209],
                    [622126, 622925],
                    [623, 626],
                    [6270],
                    [6272],
                    [6276],
                    [627700, 627779],
                    [627781, 627799],
                    [6282, 6289],
                    [6291],
                    [6292],
                    [810],
                    [8110, 8131],
                    [8132, 8151],
                    [8152, 8163],
                    [8164, 8171]
                ],
                gaps: [4, 8, 12],
                lengths: [14, 15, 16, 17, 18, 19],
                code: CardNetworkCode(
                    name: "CVN",
                    length: 3))
        case .unknown:
            return nil
        }
    }

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

            // Handle nested surcharge structure: surcharge.amount
            if let surchargeData = tmpNetwork["surcharge"] as? [String: Any],
               let surchargeAmount = surchargeData["amount"] as? Int {
                return surchargeAmount
            }

            // Fallback: handle direct surcharge integer format
            if let surcharge = tmpNetwork["surcharge"] as? Int {
                return surcharge
            }
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
    public init(cardNumber: String) {
        self = CardNetworkParser.shared.cardNetwork(from: cardNumber) ?? .unknown
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

extension [CardNetwork]: LogReporter {

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
