//
//  PaymentAPIModel.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
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

}

extension Request.Body {
    final class Payment {}
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

    public struct Complete: Encodable {
        let mandateSignatureTimestamp: String
        let paymentMethodId: String?

        public init(mandateSignatureTimestamp: String,
                    paymentMethodId: String? = nil) {
            self.mandateSignatureTimestamp = mandateSignatureTimestamp
            self.paymentMethodId = paymentMethodId
        }
    }
}

extension Response.Body {

    public struct Payment: Codable {
        public var id: String?
        public var paymentId: String?
        public var amount: Int?
        public var currencyCode: String?
        public var customer: Request.Body.ClientSession.Customer?
        public var customerId: String?
        public var dateStr: String?
        public var date: Date? {
            return dateStr?.toDate()
        }
        public var order: Request.Body.ClientSession.Order?
        public var orderId: String?
        public var requiredAction: Response.Body.Payment.RequiredAction?
        public let status: Status
        public var paymentFailureReason: PrimerPaymentErrorCode.RawValue?
        public var showSuccessCheckoutOnPendingPayment: Bool?
        public var checkoutOutcome: CheckoutOutcome?

        // swiftlint:disable:next nesting
        public enum CodingKeys: String, CodingKey {
            case id,
                 paymentId,
                 amount,
                 currencyCode,
                 customer,
                 customerId,
                 order,
                 orderId,
                 requiredAction,
                 status,
                 paymentFailureReason,
                 showSuccessCheckoutOnPendingPayment,
                 checkoutOutcome
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

        // swiftlint:disable:next nesting
        public enum CheckoutOutcome: String, Codable {
            case complete = "CHECKOUT_COMPLETE"
            case failure = "CHECKOUT_FAILURE"
            case determineFromPaymentStatus = "DETERMINE_FROM_PAYMENT_STATUS"
        }
    }

    public struct Complete: Codable {}
}

public struct Payment {

}

internal struct PrimerPaymentMethodData {
    let type: String
}

// MARK: - Public / User Facing

// MARK: Checkout Data

@objc public final class PrimerCheckoutData: NSObject, Codable {

    public let payment: PrimerCheckoutDataPayment?
    public var additionalInfo: PrimerCheckoutAdditionalInfo?

    public init(payment: PrimerCheckoutDataPayment?, additionalInfo: PrimerCheckoutAdditionalInfo? = nil) {
        self.payment = payment
        self.additionalInfo = additionalInfo
    }
}

@objc public final class PrimerCheckoutDataPayment: NSObject, Codable {
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

@objc public final class PrimerCheckoutPaymentMethodData: NSObject, Codable {
    public let paymentMethodType: PrimerCheckoutPaymentMethodType

    public init(type: PrimerCheckoutPaymentMethodType) {
        self.paymentMethodType = type
    }
}

@objc public final class PrimerCheckoutPaymentMethodType: NSObject, Codable {
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

// MARK: Client Session Order

@objc public final class PrimerOrder: NSObject, Codable {

    public let countryCode: String?
    public let shipping: PrimerShipping?

    public init(countryCode: String?, shipping: PrimerShipping?) {
        self.countryCode = countryCode
        self.shipping = shipping
    }

    convenience init(clientSessionOrder: ClientSession.Order?) {
        if let shippingMethod = clientSessionOrder?.shippingMethod {
            let shippingMethod = PrimerShipping(amount: shippingMethod.amount,
                                                methodId: shippingMethod.methodId,
                                                methodName: shippingMethod.methodName,
                                                methodDescription: shippingMethod.methodDescription)
            self.init(countryCode: clientSessionOrder?.countryCode?.rawValue, shipping: shippingMethod)
            return
        }
        self.init(countryCode: clientSessionOrder?.countryCode?.rawValue, shipping: nil)
    }
}

// MARK: Client Session Shipping

@objc public final class PrimerShipping: NSObject, Codable {
    public let amount: Int?
    public let methodId: String?
    public let methodName: String?
    public let methodDescription: String?

    public init(amount: Int?,
                methodId: String?,
                methodName: String?,
                methodDescription: String?) {
        self.amount = amount
        self.methodId = methodId
        self.methodName = methodName
        self.methodDescription = methodDescription
    }
}

// MARK: Client Session Customer

@objc public final class PrimerCustomer: NSObject, Codable {

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

@objc public final class PrimerLineItem: NSObject, Codable {

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

@objc public final class PrimerAddress: NSObject, Codable {

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
// swiftlint:enable file_length
