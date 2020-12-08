public struct PaymentMethodToken: Decodable {
    public var token: String?
    var analyticsId: String?
    var tokenType: String?
    var paymentInstrumentType: String?
    var paymentInstrumentData: PaymentInstrumentData?
}

struct PaymentInstrumentData: Decodable {
    var last4Digits: String?
    var expirationMonth: String?
    var expirationYear: String?
    var cardholderName: String?
    var network: String?
    var isNetworkTokenized: Bool?
    var binData: BinData?
    var vaultData: VaultData?
//    var threeDSecureAuthentication: Any?
}

struct BinData: Decodable {
    var network: String?
    var issuerCountryCode: String?
    var issuerName: String?
    var issuerCurrencyCode: String?
    var regionalRestriction: String?
    var accountNumberType: String?
    var accountFundingType: String?
    var prepaidReloadableIndicator: String?
    var productUsageType: String?
    var productCode: String?
    var productName: String?
}

struct VaultData: Decodable {
    var customerId: String?
}
