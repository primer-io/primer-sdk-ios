//
//  PaymentAPIModel.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 28/02/22.
//

import Foundation

struct CreateClientTokenRequest: Codable {
    let orderId: String
    let amount: Int?
    let currencyCode: String
    let customerId: String?
    let metadata: [String: String]?
    let customer: PaymentAPIModelCustomer?
    let order: PaymentAPIModelOrder?
    let paymentMethod: PaymentMethod?
}

public struct PaymentAPIModelCustomer: Codable {
    
    let firstName: String?
    let lastName: String?
    let emailAddress: String?
    let billingAddress: PaymentAPIModelAddress?
    let shippingAddress: PaymentAPIModelAddress?
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

public struct PaymentAPIModelOrder: Codable {
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

public struct ClientSessionRequestBody {
    public let customerId: String?
    public let orderId: String?
    public let currencyCode: Currency?
    public let amount: Int?
    public let metadata: [String: Any]?
    public let customer: ClientSessionRequestBody.Customer?
    public let order: ClientSessionRequestBody.Order?
    public let paymentMethod: ClientSessionRequestBody.PaymentMethod?
    
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
    
    public struct Customer: Codable {
        public let firstName: String?
        public let lastName: String?
        public let emailAddress: String?
        public let mobileNumber: String?
        public let billingAddress: PaymentAPIModelAddress?
        public let shippingAddress: PaymentAPIModelAddress?
        
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
    
    public struct Order: Codable {
        public let countryCode: CountryCode?
        public let lineItems: [LineItem]?
        
        public var dictionaryValue: [String: Any]? {
            var dic: [String: Any] = [:]
            
            if let countryCode = countryCode {
                dic["countryCode"] = countryCode.rawValue
            }
            
            if let lineItems = lineItems {
                dic["lineItems"] = lineItems.compactMap({ $0.dictionaryValue })
            }

            return dic.keys.count == 0 ? nil : dic
        }
        
        public struct LineItem: Codable {
            public let itemId: String?
            public let description: String?
            public let amount: Int?
            public let quantity: Int?
            
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
    
    public struct PaymentMethod {
        public let vaultOnSuccess: Bool?
        public let options: [String: Any]?
        
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

public struct ClientSessionActionsRequest: Encodable {
    let clientToken: String
    let actions: [ClientSession.Action]
}

extension String {
    
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

public struct PaymentAPIModelAddress: Codable {
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

public struct Payment {
    
    public struct CreateRequest: Encodable {
        let paymentMethodToken: String
        
        public init(token: String) {
            self.paymentMethodToken = token
        }
    }
    
    public struct ResumeRequest: Encodable {
        let resumeToken: String
        
        public init(token: String) {
            self.resumeToken = token
        }
    }

    public struct Response: Codable {
        public let id: String?
        public let paymentId: String?
        public let amount: Int?
        public let currencyCode: String?
        public let customer: ClientSessionRequestBody.Customer?
        public let customerId: String?
        public let dateStr: String?
        public var date: Date? {
            return dateStr?.toDate()
        }
        public let order: ClientSessionRequestBody.Order?
        public let orderId: String?
        public let requiredAction: Payment.Response.RequiredAction?
        public let status: Status
        
        public enum CodingKeys: String, CodingKey {
            case id, paymentId, amount, currencyCode, customer, customerId, order, orderId, requiredAction, status
            case dateStr = "date"
        }
        
        public struct RequiredAction: Codable {
            public let clientToken: String
            public let name: RequiredActionName
            public let description: String?
        }
        
        /// This enum is giong to be simplified removing the following cases:
        /// - authorized
        /// - settled
        /// - declined
        /// We are going to have only the following
        /// - pending
        /// - success
        /// - failed
        public enum Status: String, Codable {
            case authorized = "AUTHORIZED"
            case settled = "SETTLED"
            case declined = "DECLINED"
            case failed = "FAILED"
            case pending = "PENDING"
            case success = "SUCCESS"
        }
    }
}
