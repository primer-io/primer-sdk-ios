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

struct CreateClientTokenRequest: Codable {
    let orderId: String
    let amount: Int?
    let currencyCode: String
    let customerId: String?
    let metadata: [String: String]?
    let customer: Customer?
    let order: Order?
    let paymentMethod: PaymentMethod?
}

public struct Customer: Codable {
    let firstName: String?
    let lastName: String?
    let emailAddress: String?
    let billingAddress: Address?
    let shippingAddress: Address?
    let mobileNumber: String?
    let nationalDocumentId: String?
}

public struct LineItem: Codable {
    let itemId: String?
    let description: String?
    let amount: Int?
    let discountAmount: Int?
    let quantity: Int?
    let taxAmount: Int?
    let taxCode: String?

    public init (
        itemId: String?,
        description: String?,
        amount: Int?,
        discountAmount: Int?,
        quantity: Int?,
        taxAmount: Int?,
        taxCode: String?
    ) {
        self.itemId = itemId
        self.description = description
        self.amount = amount
        self.discountAmount = discountAmount
        self.quantity = quantity
        self.taxAmount = taxAmount
        self.taxCode = taxCode
    }
}

public struct Order: Codable {
    let countryCode: String?
    //    let fees: Fees?
    let lineItems: [LineItem]?
    let shipping: Shipping?

    public init (
        countryCode: String?,
        //        fees: Fees?,
        lineItems: [LineItem]?,
        shipping: Shipping?
    ) {
        self.countryCode = countryCode
        //        self.fees = fees
        self.lineItems = lineItems
        self.shipping = shipping
    }
}

public struct Fees: Codable {
    let amount: UInt?
    let description: String?

    public init (
        amount: UInt?,
        description: String?
    ) {
        self.amount = amount
        self.description = description
    }
}

public struct Shipping: Codable {
    let amount: UInt

    public init(amount: UInt) {
        self.amount = amount
    }
}

public struct PaymentMethod: Codable {
    let vaultOnSuccess: Bool

    public init(vaultOnSuccess: Bool) {
        self.vaultOnSuccess = vaultOnSuccess
    }
}

struct ClientSessionRequestBody {

    var clientToken: String?
    var customerId: String?
    var orderId: String?
    var currencyCode: Currency?
    var amount: Int?
    var metadata: [String: Any]?
    var customer: ClientSessionRequestBody.Customer?
    var order: ClientSessionRequestBody.Order?
    var paymentMethod: ClientSessionRequestBody.PaymentMethod?
    var testParams: Test.Params?

    var dictionaryValue: [String: Any]? {
        var dic: [String: Any] = [:]

        if let clientToken = clientToken {
            dic["clientToken"] = clientToken
        }

        if let customerId = customerId {
            dic["customerId"] = customerId
        }

        if let orderId = orderId {
            dic["orderId"] = orderId
        }

        if let currencyCode = currencyCode {
            dic["currencyCode"] = currencyCode.code
        }

        if let amount = amount {
            dic["amount"] = amount
        }

        if let metadata = metadata {
            dic["metadata"] = metadata
        }

        if let customer = customer {
            dic["customer"] = customer.dictionaryValue
        }

        if let order = order {
            dic["order"] = order.dictionaryValue
        }

        if let paymentMethod = paymentMethod {
            dic["paymentMethod"] = paymentMethod.dictionaryValue
        }

        if let testParams = testParams {
            dic["testParams"] = try? testParams.asDictionary()
        }

        return dic.keys.count == 0 ? nil : dic
    }

    struct Customer: Codable {
        var firstName: String?
        var lastName: String?
        var emailAddress: String?
        var mobileNumber: String?
        var billingAddress: Address?
        var shippingAddress: Address?

        var dictionaryValue: [String: Any]? {
            var dic: [String: Any] = [:]

            if let firstName = firstName {
                dic["firstName"] = firstName
            }

            if let lastName = lastName {
                dic["lastName"] = lastName
            }

            if let emailAddress = emailAddress {
                dic["emailAddress"] = emailAddress
            }

            if let mobileNumber = mobileNumber {
                dic["mobileNumber"] = mobileNumber
            }

            if let mobileNumber = mobileNumber {
                dic["mobileNumber"] = mobileNumber
            }

            if let billingAddress = billingAddress {
                dic["billingAddress"] = billingAddress.dictionaryValue
            }

            if let shippingAddress = shippingAddress {
                dic["shippingAddress"] = shippingAddress.dictionaryValue
            }

            return dic.keys.count == 0 ? nil : dic
        }
    }

    struct Order: Codable {
        var countryCode: CountryCode?
        var lineItems: [LineItem]?

        var dictionaryValue: [String: Any]? {
            var dic: [String: Any] = [:]

            if let countryCode = countryCode {
                dic["countryCode"] = countryCode.rawValue
            }

            if let lineItems = lineItems {
                dic["lineItems"] = lineItems.compactMap({ $0.dictionaryValue })
            }

            return dic.keys.count == 0 ? nil : dic
        }

        struct LineItem: Codable {

            var itemId: String?
            var description: String?
            var amount: Int?
            var quantity: Int?
            var discountAmount: Int?
            var taxAmount: Int?
            var productType: String?
            
            var dictionaryValue: [String: Any]? {
                var dic: [String: Any] = [:]

                if let itemId = itemId {
                    dic["itemId"] = itemId
                }

                if let description = description {
                    dic["description"] = description
                }

                if let amount = amount {
                    dic["amount"] = amount
                }

                if let quantity = quantity {
                    dic["quantity"] = quantity
                }

                if let taxAmount = taxAmount {
                    dic["taxAmount"] = taxAmount
                }

                if let discountAmount = discountAmount {
                    dic["discountAmount"] = discountAmount
                }
                
                if let productType = productType {
                    dic["productType"] = productType
                }
                
                return dic.keys.count == 0 ? nil : dic
            }
        }
    }
    
    struct PaymentMethod: Codable {
        let vaultOnSuccess: Bool?
        var options: PaymentMethodOptionGroup?
        let descriptor: String?
        let paymentType: String?

        var dictionaryValue: [String: Any]? {
            var dic: [String: Any] = [:]

            if let vaultOnSuccess = vaultOnSuccess {
                dic["vaultOnSuccess"] = vaultOnSuccess
            }

            if let options = options {
                dic["options"] = options.dictionaryValue
            }
            
            if let descriptor = descriptor {
                dic["descriptor"] = descriptor
            }

            if let paymentType = paymentType {
                dic["paymentType"] = paymentType
            }

            return dic.keys.count == 0 ? nil : dic
        }
        
        struct PaymentMethodOptionGroup: Codable {
            var KLARNA: PaymentMethodOption?
            var PAYMENT_CARD: PaymentMethodOption?

            var dictionaryValue: [String: Any]? {
                var dic: [String: Any] = [:]
                
                if let KLARNA = KLARNA {
                    dic["KLARNA"] = KLARNA.dictionaryValue
                }

                if let PAYMENT_CARD = PAYMENT_CARD {
                    dic["PAYMENT_CARD"] = PAYMENT_CARD.dictionaryValue
                }

                return dic.keys.count == 0 ? nil : dic
            }
        }
        
        struct PaymentMethodOption: Codable {
            var surcharge: SurchargeOption?
            var instalmentDuration: String?
            var extraMerchantData: [String: Any]?
            var captureVaultedCardCvv: Bool?

            enum CodingKeys: CodingKey {
                case surcharge, instalmentDuration, extraMerchantData, captureVaultedCardCvv
            }
            
            init(surcharge: SurchargeOption?, 
                 instalmentDuration: String?,
                 extraMerchantData: [String: Any]?,
                 captureVaultedCardCvv: Bool?) {
                self.surcharge = surcharge
                self.instalmentDuration = instalmentDuration
                self.extraMerchantData = extraMerchantData
                self.captureVaultedCardCvv = captureVaultedCardCvv
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
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                surcharge = try container.decodeIfPresent(SurchargeOption.self, forKey: .surcharge)
                instalmentDuration = try container.decodeIfPresent(String.self, forKey: .instalmentDuration)
                
                let jsonString = try container.decodeIfPresent(String.self, forKey: .extraMerchantData)
                if let jsonData = jsonString?.data(using: .utf8) {
                    extraMerchantData = try JSONSerialization.jsonObject(with: jsonData) as? [String: Any]
                } else {
                    extraMerchantData = nil
                }

                captureVaultedCardCvv = try container.decodeIfPresent(Bool.self, forKey: .captureVaultedCardCvv) ?? false
            }
            
            var dictionaryValue: [String: Any]? {
                var dic: [String: Any] = [:]
                
                if let surcharge = surcharge {
                    dic["surcharge"] = surcharge.dictionaryValue
                }
                
                if let instalmentDuration = instalmentDuration {
                    dic["instalmentDuration"] = instalmentDuration
                }
                
                if let extraMerchantData = extraMerchantData {
                    dic["extraMerchantData"] = extraMerchantData
                }

                if let captureVaultedCardCvv = captureVaultedCardCvv {
                    dic["captureVaultedCardCvv"] = captureVaultedCardCvv
                }

                return dic.keys.count == 0 ? nil : dic
            }
        }
        
        struct  SurchargeOption: Codable {
            var amount: Int?
            
            var dictionaryValue: [String: Any]? {
                var dic: [String: Any] = [:]
                
                if let amount = amount {
                    dic["amount"] = amount
                }
                
                return dic.keys.count == 0 ? nil : dic
            }
        }
    }

}

extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
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
