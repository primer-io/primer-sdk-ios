//
//  CreateClientToken.swift
//  PrimerSDK_Example
//
//  Created by Carl Eriksson on 08/04/2021.
//  Copyright © 2021 CocoaPods. All rights reserved.
//

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

            enum CodingKeys: CodingKey {
                case surcharge, instalmentDuration, extraMerchantData, captureVaultedCardCvv, merchantName
            }
        }

        struct  SurchargeOption: Codable {
            var amount: Int?
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
