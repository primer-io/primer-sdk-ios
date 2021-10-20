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
}

struct CreateClientTokenRequest: Codable {
    let environment: Environment
    
    let orderId: String
    let amount: Int
    let currencyCode: String
    let customerId: String?
    let customerCountryCode: PrimerSDK.CountryCode?
    let metadata: [String: String]?
    let customer: Customer?
    let order: Order?
    let paymentMethod: PaymentMethod?
}

public struct Address: Codable {
    let addressLine1: String
    let addressLine2: String?
    let city: String
    let countryCode: String
    let postalCode: String
    let firstName: String?
    let lastName: String?
    let state: String?
    
    public init(
        addressLine1: String,
        addressLine2: String?,
        city: String,
        countryCode: String,
        postalCode: String,
        firstName: String?,
        lastName: String?,
        state: String?
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
}

public struct Customer: Codable {
    let email: String?
    let billingAddress: Address?
    let shippingAddress: Address?
//    let mobileNumber: String?
    
    public init (
        email: String?,
        billingAddress: Address?,
        shippingAddress: Address?
//        mobileNumber: String?
    ) {
        self.email = email
        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
//        self.mobileNumber = mobileNumber
    }
}

public struct LineItem: Codable {
    let itemId: String?
    let description: String?
    let amount: UInt?
    let discountAmount: UInt?
    let quantity: Int?
    let taxAmount: UInt?
    let taxCode: String?
    
    public init (
        itemId: String?,
        description: String?,
        amount: UInt?,
        discountAmount: UInt?,
        quantity: Int?,
        taxAmount: UInt?,
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
    let customerId: String?
    let orderId: String?
    let currencyCode: Currency?
    let amount: Int
    let metadata: [String: Any]?
    let customer: ClientSessionRequestBody.Customer?
    let order: ClientSessionRequestBody.Order?
    let paymentMethod: ClientSessionRequestBody.PaymentMethod?
    
    var dictionaryValue: [String: Any]? {
        var dic: [String: Any] = [:]
        
        if let customerId = customerId {
            dic["customerId"] = customerId
        }
        
        if let orderId = orderId {
            dic["orderId"] = orderId
        }
        
        if let currencyCode = currencyCode {
            dic["currencyCode"] = currencyCode.rawValue
        }
        
        dic["amount"] = amount
        
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

        return dic.keys.count == 0 ? nil : dic
    }
    
    struct Customer: Encodable {
        let emailAddress: String?
        
        var dictionaryValue: [String: Any]? {
            var dic: [String: Any] = [:]
            
            if let emailAddress = emailAddress {
                dic["emailAddress"] = emailAddress
            }

            return dic.keys.count == 0 ? nil : dic
        }
    }
    
    struct Order: Encodable {
        let countryCode: CountryCode?
        let lineItems: [LineItem]?
        
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
        
        struct LineItem: Encodable {
            let itemId: String?
            let description: String?
            let amount: Int?
            let quantity: Int?
            
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
                
                return dic.keys.count == 0 ? nil : dic
            }
        }
    }
    
    struct PaymentMethod {
        let vaultOnSuccess: Bool?
        let options: [String: Any]?
        
        var dictionaryValue: [String: Any]? {
            var dic: [String: Any] = [:]
            
            if let vaultOnSuccess = vaultOnSuccess {
                dic["vaultOnSuccess"] = vaultOnSuccess
            }
            
            if let options = options {
                dic["options"] = options
            }
            
            return dic.keys.count == 0 ? nil : dic
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
//        if components.count < 2 { return nil }
        let segment = String(components[0]).padding(toLength: ((String(components[0]).count+3)/4)*4,
                                                    withPad: "=",
                                                    startingAt: 0)
        guard !segment.isEmpty, let data = Data(base64Encoded: segment) else { return nil }
        
        return try? JSONDecoder().decode(JWTToken.self, from: data)
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






struct TransactionResponse {
    var id: String
    var date: String
    var status: String
    var requiredAction: [String: Any]
}
