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
        .mir: ._mir,
        .unionpay: .chinaUnionPay,
        .visa: .visa
    ]

    static func supportedPKPaymentNetworks(cardNetworks: [CardNetwork] = .allowedCardNetworks) -> [PKPaymentNetwork] {
        cardNetworks.compactMap { networkMap[$0] ?? nil }
    }
}

private extension PKPaymentNetwork {
    static var _mir: PKPaymentNetwork? {
        guard #available(iOS 14.5, *) else { return nil }
        return .mir
    }
}
