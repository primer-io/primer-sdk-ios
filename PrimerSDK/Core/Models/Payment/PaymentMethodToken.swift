public struct PaymentMethodToken: Decodable {
    public var token: String?
    public var analyticsId: String?
    public var tokenType: String?
    public var paymentInstrumentType: String?
    var paymentInstrumentData: PaymentInstrumentData?
}

struct PaymentInstrumentData: Decodable {
    public var last4Digits: String?
    public var expirationMonth: String?
    public var expirationYear: String?
    public var cardholderName: String?
    public var network: String?
    public var isNetworkTokenized: Bool?
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
