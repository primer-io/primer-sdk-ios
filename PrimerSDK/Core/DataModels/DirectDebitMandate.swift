//
//  DirectDebitMandate.swift
//  PrimerSDK
//
//  Created by Carl Eriksson on 18/01/2021.
//

struct DirectDebitMandate {
    var firstName, lastName, email, iban, accountNumber, sortCode: String?
    var address: Address?
}

public struct Address: Codable {
    public var addressLine1, addressLine2, city, state, countryCode, postalCode: String?
    
    public init(
        addressLine1: String? = nil,
        addressLine2: String? = nil,
        city: String? = nil,
        state: String? = nil,
        countryCode: String? = nil,
        postalCode: String? = nil
    ) {
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.city = city
        self.state = state
        self.countryCode = countryCode
        self.postalCode = postalCode
    }
    
    public func toString() -> String {
        return "\(addressLine1 ?? "")\(addressLine2?.withComma ?? "")\(city?.withComma ?? "")\(postalCode?.withComma ?? "")\(countryCode?.withComma ?? "")"
    }
}

extension String {
    var withComma: String {
        if (self.count == 0) { return "" }
        return ", " + self
    }
}
