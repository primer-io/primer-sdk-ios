//
//  PaymentAPIModel.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 28/02/22.
//

#if canImport(UIKit)

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
    let fees: Fees?
    let lineItems: [LineItem]?
    let shipping: Shipping?
    
    public init (
        countryCode: String?,
        fees: Fees?,
        lineItems: [LineItem]?,
        shipping: Shipping?
    ) {
        self.countryCode = countryCode
                self.fees = fees
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

public struct ClientSessionAction: Encodable {
    let actions: [ClientSession.Action]
}

public struct ClientSessionUpdateRequest: Encodable {
    let actions: ClientSessionAction
}

internal struct JWTToken: Decodable {
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
        public let paymentFailureReason: PaymentErrorCode.RawValue?
        
        public enum CodingKeys: String, CodingKey {
            case id, paymentId, amount, currencyCode, customer, customerId, order, orderId, requiredAction, status, paymentFailureReason
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

internal struct PaymentMethodData {
    let type: PaymentMethodConfigType
}

//MARK: - Public / User Facing

@objc public class CheckoutData: NSObject, Codable {
    
    public let payment: CheckoutDataPayment?
    
    public init(payment: CheckoutDataPayment?) {
        self.payment = payment
    }
}

@objc public enum PaymentErrorCode: Int, RawRepresentable, Codable {
    case failed
    case cancelledByCustomer
    
    public typealias RawValue = String
    
    public var rawValue: RawValue {
        switch self {
        case .failed:
            return "payment-failed"
        case .cancelledByCustomer:
            return "cancelled-by-customer"
        }
    }
    
    public init?(rawValue: RawValue) {
        switch rawValue {
        case "payment-failed":
            self = .failed
        case "cancelled-by-customer":
            self = .cancelledByCustomer
        default:
            return nil
        }
    }
}

// TODO: Update / Temporary name to avoid conflicts

@objc public class CheckoutPaymentMethodData: NSObject, Codable {
    public let paymentMethodType: CheckoutPaymentMethodType
    
    public init(type: CheckoutPaymentMethodType) {
        self.paymentMethodType = type
    }
}

@objc public class CheckoutPaymentMethodType: NSObject, Codable {
    public let type: String
    
    public init(type: String) {
        self.type = type
    }
}

@objc public class CheckoutDataPayment: NSObject, Codable {
    public let id: String?
    public let orderId: String?
    public let paymentFailureReason: PaymentErrorCode?
    
    public init(id: String?, orderId: String?, paymentFailureReason: PaymentErrorCode?) {
        self.id = id
        self.orderId = orderId
        self.paymentFailureReason = paymentFailureReason
    }
}

extension CheckoutDataPayment {
    
    convenience init(from paymentReponse: Payment.Response) {
        self.init(id: paymentReponse.id, orderId: paymentReponse.orderId, paymentFailureReason: nil)
    }
}

@objc public class CheckoutClientSessionData: NSObject {
    public let customerId: String?
    public let orderId: String?
    public let currencyCode: String?
    public let totalAmount: Int?
    public let lineItems: [CheckoutDataLineItem]?
    public let orderDetails: CheckoutDataOrder?
    public let customer: CheckoutDataCustomer?
    
    public init(customerId: String?,
                orderId: String?,
                currencyCode: String?,
                totalAmount: Int?,
                lineItems: [CheckoutDataLineItem]?,
                orderDetails: CheckoutDataOrder?,
                customer: CheckoutDataCustomer?) {
        self.customerId = customerId
        self.orderId = orderId
        self.currencyCode = currencyCode
        self.totalAmount = totalAmount
        self.lineItems = lineItems
        self.orderDetails = orderDetails
        self.customer = customer
    }
}

@objc public class CheckoutDataOrder: NSObject {
    public let countryCode: String?
    
    public init(countryCode: String?) {
        self.countryCode = countryCode
    }
}

@objc public class CheckoutDataCustomer: NSObject {
    public let emailAddress: String?
    public let mobileNumber: String?
    public let billingAddress: CheckoutDataPaymentAPIModelAddress?
    public let shippingAddress: CheckoutDataPaymentAPIModelAddress?
    
    public init(emailAddress: String?, mobileNumber: String?, billingAddress: CheckoutDataPaymentAPIModelAddress?, shippingAddress: CheckoutDataPaymentAPIModelAddress?) {
        
        self.emailAddress = emailAddress
        self.mobileNumber = mobileNumber
        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
    }
}

@objc public class CheckoutDataLineItem: NSObject {
    
    public let itemId: String?
    public let itemDescription: String?
    public let amount: Int?
    public let discountAmount: Int?
    public let quantity: Int?
    public let taxCode: String?
    public let taxAmount: Int?
    
    public init (
        itemId: String?,
        itemDescription: String?,
        amount: Int?,
        discountAmount: Int?,
        quantity: Int?,
        taxCode: String?,
        taxAmount: Int?
    ) {
        self.itemId = itemId
        self.itemDescription = itemDescription
        self.amount = amount
        self.discountAmount = discountAmount
        self.quantity = quantity
        self.taxCode = taxCode
        self.taxAmount = taxAmount
    }
}

@objc public class CheckoutDataPaymentAPIModelAddress: NSObject {
    
    public let firstName: String?
    public let lastName: String?
    public let addressLine1: String?
    public let addressLine2: String?
    public let city: String?
    public let state: String?
    public let countryCode: String?
    public let postalCode: String?
    
    public init(
        firstName: String?,
        lastName: String?,
        addressLine1: String?,
        addressLine2: String?,
        city: String?,
        state: String?,
        countryCode: String?,
        postalCode: String?
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

extension CheckoutClientSessionData {
    
    internal convenience init?(from apiConfiguration: PrimerAPIConfiguration?) {
        
        guard let apiConfiguration = apiConfiguration else {
            return nil
        }
        
        let lineItems = apiConfiguration.clientSession?.order?.lineItems?.compactMap { CheckoutDataLineItem(itemId: $0.itemId,
                                                                                                               itemDescription: $0.description,
                                                                                                               amount: $0.amount,
                                                                                                               discountAmount: $0.discountAmount,
                                                                                                               quantity: $0.quantity,
                                                                                                               taxCode: apiConfiguration.clientSession?.customer?.taxId,
                                                                                                               taxAmount: apiConfiguration.clientSession?.order?.totalTaxAmount) }
        
        let orderDetails = CheckoutDataOrder(countryCode: apiConfiguration.clientSession?.order?.countryCode?.rawValue)
        
        let billingAddress = CheckoutDataPaymentAPIModelAddress(firstName: apiConfiguration.clientSession?.customer?.billingAddress?.firstName,
                                                                lastName: apiConfiguration.clientSession?.customer?.billingAddress?.lastName,
                                                                addressLine1: apiConfiguration.clientSession?.customer?.billingAddress?.addressLine1,
                                                                addressLine2: apiConfiguration.clientSession?.customer?.billingAddress?.addressLine2,
                                                                city: apiConfiguration.clientSession?.customer?.billingAddress?.city,
                                                                state: apiConfiguration.clientSession?.customer?.billingAddress?.state,
                                                                countryCode: apiConfiguration.clientSession?.customer?.billingAddress?.countryCode?.rawValue,
                                                                postalCode: apiConfiguration.clientSession?.customer?.billingAddress?.postalCode)
        
        let shippingAddress = CheckoutDataPaymentAPIModelAddress(firstName: apiConfiguration.clientSession?.customer?.shippingAddress?.firstName,
                                                                 lastName: apiConfiguration.clientSession?.customer?.shippingAddress?.lastName,
                                                                 addressLine1: apiConfiguration.clientSession?.customer?.shippingAddress?.addressLine1,
                                                                 addressLine2: apiConfiguration.clientSession?.customer?.shippingAddress?.addressLine2,
                                                                 city: apiConfiguration.clientSession?.customer?.shippingAddress?.city,
                                                                 state: apiConfiguration.clientSession?.customer?.shippingAddress?.state,
                                                                 countryCode: apiConfiguration.clientSession?.customer?.shippingAddress?.countryCode?.rawValue,
                                                                 postalCode: apiConfiguration.clientSession?.customer?.shippingAddress?.postalCode)
        
        let customer = CheckoutDataCustomer(emailAddress: apiConfiguration.clientSession?.customer?.emailAddress,
                                            mobileNumber: apiConfiguration.clientSession?.customer?.mobileNumber,
                                            billingAddress: billingAddress,
                                            shippingAddress: shippingAddress)
        
        
        self.init(customerId: apiConfiguration.clientSession?.customer?.id,
                  orderId: apiConfiguration.clientSession?.order?.id,
                  currencyCode: apiConfiguration.clientSession?.order?.currencyCode?.rawValue,
                  totalAmount: apiConfiguration.clientSession?.order?.totalOrderAmount,
                  lineItems: lineItems,
                  orderDetails: orderDetails,
                  customer: customer)
    }
    
}

#endif
