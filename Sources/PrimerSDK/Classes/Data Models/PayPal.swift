#if canImport(UIKit)

struct PayPalPurchaseUnit: Encodable {
    let amount: PayPalAmount
}

struct PayPalAmount: Encodable {
    let currencyCode: String
    let value: String

    enum CodingKeys: String, CodingKey {
        case currencyCode = "currency_code"
        case value = "value"
    }
}

struct PayPalApplicationContext: Codable {
    let returnUrl: String
    let cancelUrl: String

    enum CodingKeys: String, CodingKey {
        case returnUrl = "return_url"
        case cancelUrl = "cancel_url"
    }
}

struct PayPalCreateOrderRequest: Codable {
    let paymentMethodConfigId: String
    let amount: Int
    let currencyCode: Currency
    var locale: CountryCode?
    let returnUrl: String
    let cancelUrl: String
}

struct PayPalCreateOrderResponse: Codable {
    let orderId: String
    let approvalUrl: String
}

struct PayPalCreateBillingAgreementRequest: Codable {
    let paymentMethodConfigId: String
    let returnUrl: String
    let cancelUrl: String
}

struct PayPalCreateBillingAgreementResponse: Codable {
    let tokenId: String
    let approvalUrl: String
}

struct PayPalAccessTokenResponse: Codable {
    let accessToken: String?
}

struct PayPalOrderLink: Decodable {
    let href: String?
    let rel: String?
    let method: String?
}

struct PayPalConfirmBillingAgreementRequest: Encodable {
    let paymentMethodConfigId, tokenId: String
}

struct PayPalConfirmBillingAgreementResponse: Codable {
    let billingAgreementId: String
    let externalPayerInfo: ExternalPayerInfo
    let shippingAddress: ShippingAddress
}

/**
 Contains information of the shipping address (if available).
 
 *Values*
 
 `firstName`: Recipient's firstname.
 
 `lastName`: Recipient's lastname.
 
 `addressLine1`: Recipient's address line 1.
 
 `addressLine2`: Recipient's address line 2.
 
 `city`: Recipient's city.
 
 `state`: Recipient's state.
 
 `countryCode`: Recipient's country code.
 
 `postalCode`: Recipient's postal code.
 
 - Author:
 Primer
 - Version:
 1.2.2
 */

public struct ShippingAddress: Codable {
    let firstName, lastName, addressLine1, addressLine2, city, state, countryCode, postalCode: String?
}

#endif
