import Foundation

// MARK: - Currency
public struct Currency: Codable {
    public let code: String
    public let decimalDigits: Int

    enum CodingKeys: String, CodingKey {
        case code = "c"
        case decimalDigits = "m"
    }

    var symbol: String? {
        let localeIdentifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code])
        let locale = Locale(identifier: localeIdentifier)
        return locale.currencySymbol
    }

    var isZeroDecimal: Bool {
        decimalDigits == 0
    }
}
