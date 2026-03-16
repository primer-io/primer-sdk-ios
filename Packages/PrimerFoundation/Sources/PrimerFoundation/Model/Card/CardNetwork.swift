//
//  CardNetwork.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_body_length

import Foundation

/// Represents a card network (card scheme) that can process card payments.
///
/// `CardNetwork` identifies the payment network associated with a credit or debit card.
/// The SDK uses this to determine card validation rules, display appropriate icons,
/// and handle co-badged card scenarios where multiple networks are available.
///
/// The network is automatically detected from the card number during input,
/// or can be specified explicitly when working with tokenized payment methods.
///
/// Example usage:
/// ```swift
/// // Detect network from card number
/// let network = CardNetwork(cardNumber: "4242424242424242") // Returns .visa
///
/// // Check if network is allowed by merchant
/// if network.allowsUserSelection {
///     // Show network selector for co-badged cards
/// }
/// ```
public enum CardNetwork: String, Codable, CaseIterable, Sendable {

    /// American Express cards (starts with 34 or 37).
    case amex = "AMEX"

    /// Bancontact cards (Belgian debit card network).
    case bancontact = "BANCONTACT"

    /// Cartes Bancaires (French domestic card network).
    case cartesBancaires = "CARTES_BANCAIRES"

    /// Diners Club International cards.
    case diners = "DINERS_CLUB"

    /// Discover cards (primarily US).
    case discover = "DISCOVER"

    /// EFTPOS (Australian domestic debit network).
    case eftpos = "EFTPOS"

    /// Elo cards (Brazilian card network).
    case elo = "ELO"

    /// Hiper cards (Brazilian card network).
    case hiper = "HIPER"

    /// Hipercard cards (Brazilian card network).
    case hipercard = "HIPERCARD"

    /// JCB cards (Japan Credit Bureau).
    case jcb = "JCB"

    /// Maestro debit cards (Mastercard brand).
    case maestro = "MAESTRO"

    /// Mastercard credit and debit cards.
    case masterCard = "MASTERCARD"

    /// Mir cards (Russian national payment system).
    case mir = "MIR"

    /// Visa credit and debit cards.
    case visa = "VISA"

    /// UnionPay cards (China's largest card network).
    case unionpay = "UNIONPAY"

    /// Unknown or unsupported card network.
    case unknown = "OTHER"

    public var validation: CardNetworkValidation? {
        switch self {
        case .amex:
            CardNetworkValidation(
                niceType: "American Express",
                patterns: [[34], [37]],
                gaps: [4, 10],
                lengths: [15],
                code: CardNetworkCode(
                    name: "CID",
                    length: 4))

        case .bancontact, .cartesBancaires, .eftpos:
            nil

        case .diners:
            CardNetworkValidation(
                niceType: "Diners",
                patterns: [[300, 305], [36], [38], [39]],
                gaps: [4, 10],
                lengths: [14, 16, 19],
                code: CardNetworkCode(
                    name: "CVV",
                    length: 3))

        case .discover:
            CardNetworkValidation(
                niceType: "Discover",
                patterns: [[6011], [644, 649], [65]],
                gaps: [4, 8, 12],
                lengths: [16, 19],
                code: CardNetworkCode(
                    name: "CID",
                    length: 3))

        case .elo:
            CardNetworkValidation(
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
            CardNetworkValidation(
                niceType: "Hiper",
                patterns: [[637095], [63737423], [63743358], [637568], [637599], [637609], [637612]],
                gaps: [4, 8, 12],
                lengths: [16],
                code: CardNetworkCode(
                    name: "CVC",
                    length: 3))

        case .hipercard:
            CardNetworkValidation(
                niceType: "Hiper",
                patterns: [[606282]],
                gaps: [4, 8, 12],
                lengths: [16],
                code: CardNetworkCode(
                    name: "CVC",
                    length: 3))

        case .jcb:
            CardNetworkValidation(
                niceType: "JCB",
                patterns: [[2131], [1800], [3528, 3589]],
                gaps: [4, 8, 12],
                lengths: [16, 17, 18, 19],
                code: CardNetworkCode(
                    name: "CVV",
                    length: 3))

        case .masterCard:
            CardNetworkValidation(
                niceType: "Mastercard",
                patterns: [[51, 55], [2221, 2229], [223, 229], [23, 26], [270, 271], [2720]],
                gaps: [4, 8, 12],
                lengths: [16],
                code: CardNetworkCode(
                    name: "CVC",
                    length: 3))

        case .maestro:
            CardNetworkValidation(
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
            CardNetworkValidation(
                niceType: "Mir",
                patterns: [[2200, 2204]],
                gaps: [4, 8, 12],
                lengths: [16, 17, 18, 19],
                code: CardNetworkCode(
                    name: "CVP2",
                    length: 3))

        case .visa:
            CardNetworkValidation(
                niceType: "Visa",
                patterns: [[4]],
                gaps: [4, 8, 12],
                lengths: [16, 18, 19],
                code: CardNetworkCode(
                    name: "CVV",
                    length: 3))

        case .unionpay:
            CardNetworkValidation(
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
            nil
        }
    }

    public var displayName: String {
        if let displayName = validation?.niceType {
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

    public var assetName: String {
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

// swiftlint:enable type_body_length
