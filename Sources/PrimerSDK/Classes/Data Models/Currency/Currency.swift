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

    public init?(_ code: String) {
        self.code = code
        if let decimalDigits = CurrencyLoader.getCurrencyFor(code)?.decimalDigits {
            self.decimalDigits = decimalDigits
        } else {
            return nil
        }
    }
}
