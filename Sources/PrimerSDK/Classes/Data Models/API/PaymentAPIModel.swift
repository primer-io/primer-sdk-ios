//
//  PaymentAPIModel.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//

import Foundation

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

extension Request.Body {
    class Payment {}
}

extension Request.Body.Payment {

    public struct Create: Encodable {
        let paymentMethodToken: String

        public init(token: String) {
            self.paymentMethodToken = token
        }
    }

    public struct Resume: Encodable {
        let resumeToken: String

        public init(token: String) {
            self.resumeToken = token
        }
    }
}

extension Response.Body {

    public struct Payment: Codable {

        public let id: String?
        public let paymentId: String?
        public let amount: Int?
        public let currencyCode: String?
        public let customer: Request.Body.ClientSession.Customer?
        public let customerId: String?
        public let dateStr: String?
        public var date: Date? {
            return dateStr?.toDate()
        }
        public let order: Request.Body.ClientSession.Order?
        public let orderId: String?
        public let requiredAction: Response.Body.Payment.RequiredAction?
        public let status: Status
        public let paymentFailureReason: PrimerPaymentErrorCode.RawValue?

        // swiftlint:disable:next nesting
        public enum CodingKeys: String, CodingKey {
            case id, paymentId, amount, currencyCode, customer, customerId, order, orderId, requiredAction, status, paymentFailureReason
            case dateStr = "date"
        }

        // swiftlint:disable:next nesting
        public struct RequiredAction: Codable {
            public let clientToken: String
            public let name: RequiredActionName
            public let description: String?
        }

        // swiftlint:disable:next nesting
        public enum Status: String, Codable {
            case failed = "FAILED"
            case pending = "PENDING"
            case success = "SUCCESS"
        }
    }
}

public struct Payment {

}

internal struct PrimerPaymentMethodData {
    let type: String
}

// MARK: - Public / User Facing

// MARK: Checkout Data

@objc public class PrimerCheckoutData: NSObject, Codable {

    public let payment: PrimerCheckoutDataPayment?
    public var additionalInfo: PrimerCheckoutAdditionalInfo?

    public init(payment: PrimerCheckoutDataPayment?, additionalInfo: PrimerCheckoutAdditionalInfo? = nil) {
        self.payment = payment
        self.additionalInfo = additionalInfo
    }
}

@objc public class PrimerCheckoutDataPayment: NSObject, Codable {
    public let id: String?
    public let orderId: String?
    public let paymentFailureReason: PrimerPaymentErrorCode?

    public init(id: String?, orderId: String?, paymentFailureReason: PrimerPaymentErrorCode?) {
        self.id = id
        self.orderId = orderId
        self.paymentFailureReason = paymentFailureReason
    }
}

// MARK: -

extension PrimerCheckoutDataPayment {

    convenience init(from paymentReponse: Response.Body.Payment) {
        self.init(id: paymentReponse.id, orderId: paymentReponse.orderId, paymentFailureReason: nil)
    }
}

// MARK: Checkout Data Payment

@objc public class PrimerCheckoutPaymentMethodData: NSObject, Codable {
    public let paymentMethodType: PrimerCheckoutPaymentMethodType

    public init(type: PrimerCheckoutPaymentMethodType) {
        self.paymentMethodType = type
    }
}

@objc public class PrimerCheckoutPaymentMethodType: NSObject, Codable {
    public let type: String

    public init(type: String) {
        self.type = type
    }
}

// MARK: Checkout Data Payment Error

@objc public enum PrimerPaymentErrorCode: Int, RawRepresentable, Codable {

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

// MARK: Client Session

@objc public class PrimerClientSession: NSObject, Codable {

    public let customerId: String?
    public let orderId: String?
    public let currencyCode: String?
    public let totalAmount: Int?
    public let lineItems: [PrimerLineItem]?
    public let orderDetails: PrimerOrder?
    public let customer: PrimerCustomer?

    public init(customerId: String?,
                orderId: String?,
                currencyCode: String?,
                totalAmount: Int?,
                lineItems: [PrimerLineItem]?,
                orderDetails: PrimerOrder?,
                customer: PrimerCustomer?) {
        self.customerId = customerId
        self.orderId = orderId
        self.currencyCode = currencyCode
        self.totalAmount = totalAmount
        self.lineItems = lineItems
        self.orderDetails = orderDetails
        self.customer = customer
    }
}

// MARK: Client Session Order

@objc public class PrimerOrder: NSObject, Codable {

    public let countryCode: String?

    public init(countryCode: String?) {
        self.countryCode = countryCode
    }
}

// MARK: Client Session Customer

@objc public class PrimerCustomer: NSObject, Codable {

    public let emailAddress: String?
    public let mobileNumber: String?
    public let firstName: String?
    public let lastName: String?
    public let billingAddress: PrimerAddress?
    public let shippingAddress: PrimerAddress?

    public init(
        emailAddress: String?,
        mobileNumber: String?,
        firstName: String?,
        lastName: String?,
        billingAddress: PrimerAddress?,
        shippingAddress: PrimerAddress?) {
        self.emailAddress = emailAddress
        self.mobileNumber = mobileNumber
        self.firstName = firstName
        self.lastName = lastName
        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
    }
}

// MARK: Client Session Customer Line Item

@objc public class PrimerLineItem: NSObject, Codable {

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

// MARK: Client Session Customer Address

@objc public class PrimerAddress: NSObject, Codable {

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
        postalCode: String?,
        city: String?,
        state: String?,
        countryCode: String?
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
