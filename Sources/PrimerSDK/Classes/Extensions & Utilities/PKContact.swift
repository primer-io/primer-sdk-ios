import PassKit.PKContact

extension PKContact {
    var clientSessionAddress: ClientSession.Address? {
        // From: https://developer.apple.com/documentation/contacts/cnpostaladdress/1403414-street
        guard let address = postalAddress else { return nil }
        let addressLines = address.street.components(separatedBy: "\n")
        return ClientSession.Address(
            firstName: name?.givenName,
            lastName: name?.familyName,
            addressLine1: addressLines.first,
            addressLine2: addressLines.count > 1 ? addressLines[1] : nil,
            city: address.city,
            postalCode: address.postalCode,
            state: address.state,
            countryCode: CountryCode(rawValue: address.isoCountryCode)
        )
    }
}
