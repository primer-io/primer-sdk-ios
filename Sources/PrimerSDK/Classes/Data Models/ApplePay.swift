import PassKit

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
    var items: [ApplePayOrderItem]
    var shippingMethods: [PKShippingMethod]?
}

struct ApplePayPaymentResponse {
    let token: ApplePayPaymentInstrument.PaymentResponseToken
    let billingAddress: ClientSession.Address?
    let shippingAddress: ClientSession.Address?
    let mobileNumber: String?
    let emailAddress: String?

    init(payment: PKPayment, tokenPaymentData: ApplePayPaymentResponseTokenPaymentData) {
        token = ApplePayPaymentInstrument.PaymentResponseToken(token: payment.token, paymentData: tokenPaymentData)
        billingAddress = payment.billingContact?.clientSessionAddress
        shippingAddress = payment.shippingContact?.clientSessionAddress
        mobileNumber = payment.shippingContact?.phoneNumber?.stringValue
        emailAddress = payment.shippingContact?.emailAddress
    }
}

struct ApplePayShippingMethodsInfo {
    let shippingMethods: [PKShippingMethod]?
    let selectedShippingMethodOrderItem: ApplePayOrderItem?

    init(shippingMethods: [PKShippingMethod]? = nil, selectedShippingMethodOrderItem: ApplePayOrderItem? = nil) {
        self.shippingMethods = shippingMethods
        self.selectedShippingMethodOrderItem = selectedShippingMethodOrderItem
    }
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

    #if DEBUG
        init(
            data: String = "apple-pay-payment-response-mock-data",
            signature: String = "apple-pay-mock-signature",
            version: String = "apple-pay-mock-version",
            header: ApplePayTokenPaymentDataHeader = .init(
                ephemeralPublicKey: "apple-pay-mock-ephemeral-key",
                publicKeyHash: "apple-pay-mock-public-key-hash",
                transactionId: "apple-pay-mock--transaction-id"
            )
        ) {
            self.data = data
            self.signature = signature
            self.version = version
            self.header = header
        }
    #endif
}

struct ApplePayTokenPaymentDataHeader: Codable {
    let ephemeralPublicKey: String
    let publicKeyHash: String
    let transactionId: String
}
