import Foundation

// MARK: - Currency
public struct Currency: Codable {
    public let code: String
    public let decimalDigits: Int

    enum CodingKeys: String, CodingKey {
        case code = "c"
        case decimalDigits = "m"
    }

    internal var symbol: String? {
        let localeIdentifier = Locale.identifier(fromComponents: [NSLocale.Key.currencyCode.rawValue: code])
        let locale = Locale(identifier: localeIdentifier)
        return locale.currencySymbol
    }

    internal var isZeroDecimal: Bool {
        decimalDigits == 0
    }

    internal init(code: String, decimalDigits: Int) {
        self.code = code
        self.decimalDigits = decimalDigits
    }
}
