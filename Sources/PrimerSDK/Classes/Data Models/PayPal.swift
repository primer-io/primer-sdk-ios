extension Request.Body {
    public final class PayPal {}
}

extension Response.Body {
    public final class PayPal {}
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
        let currencyCode: String
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

    public final class PayPal {

        // swiftlint:disable:next nesting
        public struct ShippingAddress: Codable {
            let firstName, lastName, addressLine1, addressLine2, city, state, countryCode, postalCode: String?
        }

        // swiftlint:disable:next nesting
        public struct ExternalPayerInfo: Codable {
            public var externalPayerId, externalPayerIdSnakeCase,
                       email,
                       firstName, firstNameSnakeCase,
                       lastName, lastNameSnakeCase: String?

            public init(externalPayerId: String,
                        externalPayerIdSnakeCase: String? = nil,
                        email: String,
                        firstName: String?,
                        firstNameSnakeCase: String? = nil,
                        lastName: String,
                        lastNameSnakeCase: String? = nil) {
                self.externalPayerId = externalPayerId
                self.externalPayerIdSnakeCase = externalPayerIdSnakeCase ?? externalPayerId
                self.email = email
                self.firstName = firstName
                self.firstNameSnakeCase = firstNameSnakeCase ?? firstName
                self.lastName = lastName
                self.lastNameSnakeCase = lastNameSnakeCase ?? lastName
            }

            public init(from decoder: Decoder) throws {
                let container: KeyedDecodingContainer<Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys> =
                    try decoder.container(keyedBy: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.self)

                externalPayerId = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.externalPayerId)

                externalPayerIdSnakeCase = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.externalPayerIdSnakeCase)

                email = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.email)

                firstName = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.firstName)

                firstNameSnakeCase = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.firstNameSnakeCase)

                lastName = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.lastName)

                lastNameSnakeCase = try container.decodeIfPresent(
                    String.self,
                    forKey: Response.Body.Tokenization.PayPal.ExternalPayerInfo.CodingKeys.lastNameSnakeCase)

                // This logic ensures we mirror externalPayerId to external_payer_id and vice versa
                if externalPayerId == nil && externalPayerIdSnakeCase != nil {
                    externalPayerId = externalPayerIdSnakeCase
                } else if externalPayerIdSnakeCase == nil && externalPayerId != nil {
                    externalPayerIdSnakeCase = externalPayerId
                }

                if firstName == nil && firstNameSnakeCase != nil {
                    firstName = firstNameSnakeCase
                } else if firstNameSnakeCase == nil && firstName != nil {
                    firstNameSnakeCase = firstName
                }

                if lastName == nil && lastNameSnakeCase != nil {
                    lastName = lastNameSnakeCase
                } else if lastNameSnakeCase == nil && lastName != nil {
                    lastNameSnakeCase = lastName
                }
            }

            // swiftlint:disable:next nesting
            enum CodingKeys: String, CodingKey {
                case externalPayerId
                case externalPayerIdSnakeCase = "external_payer_id"
                case firstNameSnakeCase = "first_name"
                case lastNameSnakeCase = "last_name"
                case email, firstName, lastName
            }
        }
    }
}
