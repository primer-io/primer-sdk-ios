//
//  ApplePayUtils.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

enum ApplePayUtils: LogReporter {

    private static let networkMap: [CardNetwork: PKPaymentNetwork?] = [
        .amex: .amex,
        .cartesBancaires: .cartesBancaires,
        .discover: .discover,
        .eftpos: .eftpos,
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

    static func warnAboutUnsupportedCardNetworks() {
        let paymentMethods = PrimerAPIConfiguration.current?.paymentMethods ?? []
        guard PrimerSettings.current.paymentMethodOptions.applePayOptions != nil,
              paymentMethods.contains(where: { $0.type == PrimerPaymentMethodType.applePay.rawValue })
        else { return }
        let names = [CardNetwork].allowedCardNetworks
            .filter { (networkMap[$0] ?? nil) == nil }
            .map(\.rawValue)
            .joined(separator: ", ")
        guard !names.isEmpty else { return }
        logger.warn(message: "Apple Pay doesn't support these allowed card networks, so they are left out: \(names)")
    }

    static func canMakeApplePayPayments(
        canMakePayments: ([PKPaymentNetwork]) -> Bool = PKPaymentAuthorizationController.canMakePayments(usingNetworks:)
    ) -> Bool {
        if PrimerSettings.current.paymentMethodOptions.applePayOptions?.checkProvidedNetworks == true {
            canMakePayments(supportedPKPaymentNetworks())
        } else {
            PKPaymentAuthorizationController.canMakePayments()
        }
    }
}

private extension PKPaymentNetwork {
    static var pkMir: PKPaymentNetwork? {
        guard #available(iOS 14.5, *) else { return nil }
        return .mir
    }
}
