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
    var supportedNetworks: [PaymentNetwork]
    var items: [OrderItem]
    var merchantCapabilities: [MerchantCapability]
}

struct ApplePayPaymentResponse {
    let token: ApplePayPaymentResponseToken
}

struct ApplePayPaymentResponseToken: Codable {
    let paymentMethod: ApplePayPaymentResponsePaymentMethod
    let transactionIdentifier: String
    let paymentData: ApplePayPaymentResponseTokenPaymentData
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
