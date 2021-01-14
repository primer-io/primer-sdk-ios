struct PayPalCreateOrderRequest: Encodable {
    let intent: String
    let purchase_units: [PayPalPurchaseUnit]
    let application_context: PayPalApplicationContext
}

struct PayPalPurchaseUnit: Encodable {
    let amount: PayPalAmount
}

struct PayPalAmount: Encodable {
    let currency_code: String
    let value: String
}

struct PayPalApplicationContext: Encodable {
    let return_url: String
    let cancel_url: String
}

struct PayPalAccessTokenRequest: Encodable {
    let paymentMethodConfigId: String
}

struct PayPalAccessTokenResponse: Decodable {
    let accessToken: String?
}

struct PayPalCreateOrderResponse: Decodable {
    let id: String?
    let status: String?
    let links: [PayPalOrderLink]?
}

struct PayPalOrderLink: Decodable {
    let href: String?
    let rel: String?
    let method: String?
}

struct PayPalCreateBillingAgreementResponse: Decodable {
    let tokenId: String?
}

struct PayPalConfirmBillingAgreementRequest: Encodable {
    let paymentMethodConfigId, tokenId: String
}

struct PayPalConfirmBillingAgreementResponse: Decodable {
    let billingAgreementId: String
    let externalPayerInfo: PayPalExternalPayerInfo
    let shippingAddress: ShippingAddress
}

struct PayPalExternalPayerInfo: Codable {
    let externalPayerId, email, firstName, lastName: String?
}

public struct ShippingAddress: Codable {
    let firstName, lastName, addressLine1, addressLine2, city, state, countryCode, postalCode: String?
}
