extension Request.Body {
    public class PayPal {}
}

extension Response.Body {
    public class PayPal {}
}

extension Request.Body.PayPal {

    struct ConfirmBillingAgreement: Encodable {
        let paymentMethodConfigId, tokenId: String
    }

    struct CreateBillingAgreement: Codable {

        let paymentMethodConfigId: String
        let returnUrl: String
        let cancelUrl: String
    }

    struct CreateOrder: Codable {

        let paymentMethodConfigId: String
        let amount: Int
        let currencyCode: Currency
        var locale: CountryCode?
        let returnUrl: String
        let cancelUrl: String
    }

    struct PayerInfo: Codable {

        let paymentMethodConfigId: String
        let orderId: String
    }
}

extension Response.Body.PayPal {

    struct ConfirmBillingAgreement: Codable {

        let billingAgreementId: String
        let externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo
        let shippingAddress: Response.Body.Tokenization.PayPal.ShippingAddress?
    }

    struct CreateBillingAgreement: Codable {

        let tokenId: String
        let approvalUrl: String
    }

    struct CreateOrder: Codable {

        let orderId: String
        let approvalUrl: String
    }

    public struct PayerInfo: Codable {

        let orderId: String
        let externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo
    }
}

extension Response.Body.Tokenization {

    public class PayPal {

        public struct ShippingAddress: Codable {
            let firstName, lastName, addressLine1, addressLine2, city, state, countryCode, postalCode: String?
        }

        public struct ExternalPayerInfo: Codable {
            public var externalPayerId, email, firstName, lastName: String?
        }
    }
}
