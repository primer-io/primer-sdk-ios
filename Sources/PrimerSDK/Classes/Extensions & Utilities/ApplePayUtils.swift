//
//  ApplePayUtils.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import struct PassKit.PKPaymentNetwork

enum ApplePayUtils {

    private static let networkMap: [CardNetwork: PKPaymentNetwork?] = [
        .amex: .amex,
        .cartesBancaires: .cartesBancaires,
        .discover: .discover,
        .elo: .elo,
        .jcb: .JCB,
        .masterCard: .masterCard,
        .maestro: .maestro,
        .mir: .pkMir,
        .unionpay: .chinaUnionPay,
        .visa: .visa
    ]

    static func supportedPKPaymentNetworks(cardNetworks: [CardNetwork] = .allowedCardNetworks) -> [PKPaymentNetwork] {
        cardNetworks.compactMap { networkMap[$0] ?? nil }
    }
}

private extension PKPaymentNetwork {
    static var pkMir: PKPaymentNetwork? {
        guard #available(iOS 14.5, *) else { return nil }
        return .mir
    }
}
