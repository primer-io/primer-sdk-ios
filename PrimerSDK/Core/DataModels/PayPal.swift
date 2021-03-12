struct PayPalPurchaseUnit: Encodable {
    let amount: PayPalAmount
}

struct PayPalAmount: Encodable {
    let currency_code: String
    let value: String
}

struct PayPalApplicationContext: Codable {
    let return_url: String
    let cancel_url: String
}

struct PayPalCreateOrderRequest: Codable {
    let paymentMethodConfigId: String
    let amount: Int
    let currencyCode: Currency
    var locale: CountryCode? = nil
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
    let externalPayerInfo: PayPalExternalPayerInfo
    let shippingAddress: ShippingAddress
}

struct PayPalExternalPayerInfo: Codable {
    let externalPayerId, email, firstName, lastName: String?
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
