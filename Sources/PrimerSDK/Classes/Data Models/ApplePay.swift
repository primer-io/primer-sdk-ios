#if canImport(UIKit)

public enum MerchantCapability {
    case capability3DS
    case capabilityEMV
    case capabilityCredit
    case capabilityDebit
}

struct ApplePayRequest {
    var currency: Currency
    var merchantIdentifier: String
    var countryCode: CountryCode
    var items: [OrderItem]
}

struct ApplePayPaymentResponse {
    let token: ApplePayPaymentInstrument.PaymentResponseToken
}

struct ApplePayPaymentResponsePaymentMethod: Codable {
    let displayName: String?
    let network: String?
    let type: String?
}

struct ApplePayPaymentResponseTokenPaymentData: Codable {
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

#endif
