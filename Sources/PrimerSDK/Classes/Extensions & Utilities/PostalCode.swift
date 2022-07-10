#if canImport(UIKit)

class PostalCode {
    
    static func sample(for countryCode: CountryCode?) -> String {
        guard let _countryCode = countryCode else { return "90210" }
        switch (_countryCode) {
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
}

#endif
