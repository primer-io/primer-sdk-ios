#if canImport(UIKit)

class PostalCode {
    
    static func sample(for countryCode: CountryCode?) -> String {
        guard let countryCode = countryCode else { return "90210" }
        switch (countryCode) {
        case CountryCode.gb:
            return "EC1A 1BB"
        case CountryCode.us:
            return "90210"
        case CountryCode.ca:
            return "K1A 0B1"
        default:
            return "90210"
        }
    }
    
    static func name(for countryCode: CountryCode?) -> String {
        guard let countryCode = countryCode else { return Strings.PostalCode.defaultPostalCodeName }
        switch (countryCode) {
        case CountryCode.us:
            return Strings.PostalCode.zipCodeName
        default:
            return Strings.PostalCode.defaultPostalCodeName
        }
    }
}

#endif
