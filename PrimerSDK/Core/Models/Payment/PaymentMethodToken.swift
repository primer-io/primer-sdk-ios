struct GetVaultedPaymentMethodsResponse: Decodable {
    var data: [PaymentMethodToken]
}

public struct PaymentMethodToken: Codable {
    public var token: String?
    public var analyticsId: String?
    public var tokenType: String?
    public var paymentInstrumentType: PaymentInstrumentType
    public var paymentInstrumentData: PaymentInstrumentData?
}

public enum PaymentInstrumentType: String {
    case PAYPAL_BILLING_AGREEMENT = "PAYPAL_BILLING_AGREEMENT"
    case PAYMENT_CARD = "PAYMENT_CARD"
    case UNKNOWN = "UNKNOWN"
}

extension PaymentInstrumentType: Codable {
    public init(from decoder: Decoder) throws {
        self = try PaymentInstrumentType(rawValue: decoder.singleValueContainer().decode(RawValue.self)) ?? .UNKNOWN
    }
}

public struct PaymentInstrumentData: Codable {
    public var paypalBillingAgreementId: String?
    public var last4Digits: String?
    public var expirationMonth: String?
    public var expirationYear: String?
    public var cardholderName: String?
    public var network: String?
    public var isNetworkTokenized: Bool?
    public var externalPayerInfo: ExternalPayerInfo?
    public var shippingAddress: ShippingAddress?
    public var binData: BinData?
    public var vaultData: VaultData?
    public var threeDSecureAuthentication: ThreeDSecureAuthentication?
}

public struct ExternalPayerInfo: Codable {
    public var externalPayerId, email, firstName, lastName: String?
}

public struct BinData: Codable {
    public var network: String?
    public var issuerCountryCode: String?
    public var issuerName: String?
    public var issuerCurrencyCode: String?
    public var regionalRestriction: String?
    public var accountNumberType: String?
    public var accountFundingType: String?
    public var prepaidReloadableIndicator: String?
    public var productUsageType: String?
    public var productCode: String?
    public var productName: String?
}

public struct VaultData: Codable {
    public var customerId: String?
}

public struct ThreeDSecureAuthentication: Codable {
    public var responseCode, reasonCode, reasonText, protocolVersion, challengeIssued: String?
}
