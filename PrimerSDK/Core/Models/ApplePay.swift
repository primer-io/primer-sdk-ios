struct ApplePayToken: Codable {
    let paymentData: ApplePayTokenPaymentData
    let paymentMethod: ApplePayTokenPaymentMethod
    let transactionIdentifier: String
}

struct ApplePayTokenPaymentData: Codable {
    let data: String
    let signature: String
    let version: String
    let header: ApplePayTokenPaymentDataHeader
}

struct ApplePayTokenPaymentDataHeader: Codable {
    let ephemeralPublicKey: String
    let publicKeyHash: String
    let transactionId: String
}

struct ApplePayTokenPaymentMethod: Codable {
    let displayName: String
    let network: String
    let type: String
}
