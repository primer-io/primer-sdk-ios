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

struct Address: Codable {
    var addressLine1, addressLine2, city, state, countryCode, postalCode: String?
    
    func toString() -> String {
        return "\(addressLine1 ?? "")\(addressLine2?.withComma ?? "")\(city?.withComma ?? "")\(postalCode?.withComma ?? "")\(countryCode?.withComma ?? "")"
    }
}

extension String {
    var withComma: String {
        if (self.count == 0) { return "" }
        return ", " + self
    }
}
