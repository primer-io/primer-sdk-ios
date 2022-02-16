//
//  dsa.swift
//  HeadlessUniversalCheckoutExample
//
//  Created by Evangelos on 16/2/22.
//

import Foundation
import PrimerSDK

struct ClientSessionRequestBody {
    let customerId: String?
    let orderId: String?
    let currencyCode: Currency?
    let amount: Int?
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

        return dic.keys.count == 0 ? nil : dic
    }
    
    struct Customer: Codable {
        let firstName: String?
        let lastName: String?
        let emailAddress: String?
        let mobileNumber: String?
        let billingAddress: Address?
        let shippingAddress: Address?
        
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
        
        struct LineItem: Codable {
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

public struct Address: Codable {
    let firstName: String?
    let lastName: String?
    let addressLine1: String?
    let addressLine2: String?
    let city: String?
    let state: String?
    let countryCode: String?
    let postalCode: String?
    
    
    
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
