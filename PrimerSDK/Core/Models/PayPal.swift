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
