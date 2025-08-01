//
//  CreateClientToken.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerSDK

enum Environment: String, Codable {
    case local, dev, sandbox, staging, production

    init(intValue: Int) {
        switch intValue {
        case 0:
            self = .local
        case 1:
            self = .dev
        case 2:
            self = .sandbox
        case 3:
            self = .staging
        case 4:
            self = .production
        default:
            fatalError()
        }
    }

    var intValue: Int {
        switch self {
        case .local:
            return 0
        case .dev:
            return 1
        case .sandbox:
            return 2
        case .staging:
            return 3
        case .production:
            return 4
        }
    }

    var baseUrl: URL {
        switch self {
        case .local:
            return URL(string: "https://primer-mock-back-end.herokuapp.com")!
        default:
            return URL(string: "https://us-central1-primerdemo-8741b.cloudfunctions.net")!
        }
    }

}

struct ClientSessionRequestBody: Encodable {

    var clientToken: String?
    var customerId: String?
    var orderId: String?
    var currencyCode: String?
    var amount: Int?
    var metadata: Metadata?
    var customer: ClientSessionRequestBody.Customer?
    var order: ClientSessionRequestBody.Order?
    var paymentMethod: ClientSessionRequestBody.PaymentMethod?
    var testParams: Test.Params?

    struct Customer: Codable {
        var firstName: String?
        var lastName: String?
        var emailAddress: String?
        var mobileNumber: String?
        var billingAddress: Address?
        var shippingAddress: Address?
    }

    struct Order: Codable {
        var countryCode: CountryCode?
        var lineItems: [LineItem]?

        struct LineItem: Codable {

            var itemId: String?
            var description: String?
            var amount: Int?
            var quantity: Int?
            var discountAmount: Int?
            var taxAmount: Int?
            var productType: String?
        }
    }

    struct PaymentMethod: Codable {
        var vaultOnSuccess: Bool?
        var vaultOnAgreement: Bool?
        var options: PaymentMethodOptionGroup?
        let descriptor: String?
        let paymentType: String?

        struct PaymentMethodOptionGroup: Codable {
            var KLARNA: PaymentMethodOption?
            var PAYMENT_CARD: PaymentMethodOption?
            var APPLE_PAY: PaymentMethodOption?
        }

        struct PaymentMethodOption: Codable {
            var surcharge: SurchargeOption?
            var instalmentDuration: String?
            var extraMerchantData: ExtraMerchantData?
            var captureVaultedCardCvv: Bool?
            var merchantName: String?
            var networks: NetworkOptionGroup?

            enum CodingKeys: CodingKey {
                case surcharge, instalmentDuration, extraMerchantData, captureVaultedCardCvv, merchantName, networks
            }

            init(surcharge: SurchargeOption?,
                 instalmentDuration: String?,
                 extraMerchantData: ExtraMerchantData?,
                 captureVaultedCardCvv: Bool?,
                 merchantName: String?,
                 networks: NetworkOptionGroup?) {
                self.surcharge = surcharge
                self.instalmentDuration = instalmentDuration
                self.extraMerchantData = extraMerchantData
                self.captureVaultedCardCvv = captureVaultedCardCvv
                self.merchantName = merchantName
                self.networks = networks
            }

            func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)

                if let surcharge = surcharge {
                    try container.encode(surcharge, forKey: .surcharge)
                }

                if let instalmentDuration = instalmentDuration {
                    try container.encode(instalmentDuration, forKey: .instalmentDuration)
                }

                if let extraMerchantData = extraMerchantData {
                    let jsonData = try JSONSerialization.data(withJSONObject: extraMerchantData, options: [])
                    let jsonString = String(data: jsonData, encoding: .utf8)
                    try container.encode(jsonString, forKey: .extraMerchantData)
                }

                if let captureVaultedCardCvv = captureVaultedCardCvv {
                    try container.encode(captureVaultedCardCvv, forKey: .captureVaultedCardCvv)
                }

                if let merchantName = merchantName {
                    try container.encode(merchantName, forKey: .merchantName)
                }

                if let networks = networks {
                    try container.encode(networks, forKey: .networks)
                }
            }

            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)

                surcharge = try container.decodeIfPresent(SurchargeOption.self, forKey: .surcharge)
                instalmentDuration = try container.decodeIfPresent(String.self, forKey: .instalmentDuration)

                if let jsonString = try container.decodeIfPresent(String.self, forKey: .extraMerchantData),
                   let jsonData = jsonString.data(using: .utf8) {
                    extraMerchantData = try JSONSerialization.jsonObject(with: jsonData) as? ExtraMerchantData
                } else {
                    extraMerchantData = nil
                }

                captureVaultedCardCvv = try container.decodeIfPresent(Bool.self, forKey: .captureVaultedCardCvv)
                merchantName = try container.decodeIfPresent(String.self, forKey: .merchantName)
                networks = try container.decodeIfPresent(NetworkOptionGroup.self, forKey: .networks)
            }
        }

        struct  SurchargeOption: Codable {
            var amount: Int?

            var dictionaryValue: [String: Any] {
                return ["amount": amount ?? 0]
            }

        }

        struct NetworkOptionGroup: Codable {
            var VISA: NetworkOption?
            var MASTERCARD: NetworkOption?
            var JCB: NetworkOption?

            var dictionaryValue: [String: Any]? {
                var dic: [String: Any] = [:]

                if let VISA = VISA {
                    dic["VISA"] = VISA.dictionaryValue
                }

                if let MASTERCARD = MASTERCARD {
                    dic["MASTERCARD"] = MASTERCARD.dictionaryValue
                }

                if let JCB = JCB {
                    dic["JCB"] = JCB.dictionaryValue
                }

                return dic.isEmpty ? nil : dic
            }
        }

        struct NetworkOption: Codable {
            var surcharge: SurchargeOption

            var dictionaryValue: [String: Any] {
                return ["surcharge": surcharge.dictionaryValue]
            }
        }
    }
}

struct ExtraMerchantData: Codable {
    let subscription: [Subscription]
    let customerAccountInfo: [CustomerAccountInfo]

    enum CodingKeys: String, CodingKey {
        case subscription
        case customerAccountInfo = "customer_account_info"
    }

    struct Subscription: Codable {
        let subscriptionName: String
        let startTime: String
        let endTime: String
        let autoRenewalOfSubscription: Bool

        enum CodingKeys: String, CodingKey {
            case subscriptionName = "subscription_name"
            case autoRenewalOfSubscription = "auto_renewal_of_subscription"
            case endTime = "end_time"
            case startTime = "start_time"
        }
    }

    struct CustomerAccountInfo: Codable {
        let uniqueAccountIdentifier: String
        let accountRegistrationDate: String
        let accountLastModified: String

        enum CodingKeys: String, CodingKey {
            case accountRegistrationDate = "account_registration_date"
            case uniqueAccountIdentifier = "unique_account_identifier"
            case accountLastModified = "account_last_modified"
        }
    }
}



extension String {

    var jwtTokenPayload: JWTToken? {
        let components = self.split(separator: ".")
        if components.count < 2 { return nil }
        let segment = String(components[1]).fixedBase64Format
        guard !segment.isEmpty, let data = Data(base64Encoded: segment, options: .ignoreUnknownCharacters) else { return nil }
        return (try? JSONDecoder().decode(JWTToken.self, from: data))
    }

    var fixedBase64Format: Self {
        let str = self.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let offset = str.count % 4
        guard offset != 0 else { return str }
        return str.padding(toLength: str.count + 4 - offset, withPad: "=", startingAt: 0)
    }

}

struct JWTToken: Decodable {
    var accessToken: String?
    var exp: Int?
    var expDate: Date? {
        guard let exp = exp else { return nil }
        return Date(timeIntervalSince1970: TimeInterval(exp))
    }
    var configurationUrl: String?
    var paymentFlow: String?
    var threeDSecureInitUrl: String?
    var threeDSecureToken: String?
    var coreUrl: String?
    var pciUrl: String?
    var env: String?
    var intent: String?
}

public struct Address: Codable {

    var firstName: String?
    var lastName: String?
    var addressLine1: String?
    var addressLine2: String?
    var city: String?
    var state: String?
    var countryCode: String?
    var postalCode: String?

    public init(
        firstName: String?,
        lastName: String?,
        addressLine1: String,
        addressLine2: String?,
        city: String,
        state: String?,
        countryCode: String,
        postalCode: String
    ) {
        self.addressLine1 = addressLine1
        self.addressLine2 = addressLine2
        self.city = city
        self.countryCode = countryCode
        self.postalCode = postalCode
        self.firstName = firstName
        self.lastName = lastName
        self.state = state
    }

    var dictionaryValue: [String: Any]? {
        var dic: [String: Any] = [:]

        if let firstName = firstName {
            dic["firstName"] = firstName
        }

        if let lastName = lastName {
            dic["lastName"] = lastName
        }

        if let addressLine1 = addressLine1 {
            dic["addressLine1"] = addressLine1
        }

        if let addressLine2 = addressLine2 {
            dic["addressLine2"] = addressLine2
        }

        if let city = city {
            dic["city"] = city
        }

        if let postalCode = postalCode {
            dic["postalCode"] = postalCode
        }

        if let state = state {
            dic["state"] = state
        }

        if let countryCode = countryCode {
            dic["countryCode"] = countryCode
        }

        return dic.keys.count == 0 ? nil : dic
    }
}
