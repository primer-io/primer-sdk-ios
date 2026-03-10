//
//  PaymentAPIModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable file_length
import Foundation
import PrimerFoundation
import PrimerNetworking

public struct Payment {

}

struct PrimerPaymentMethodData {
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
            let shippingMethod = PrimerShipping(
                amount: shippingMethod.amount,
                methodId: shippingMethod.methodId,
                methodName: shippingMethod.methodName,
                methodDescription: shippingMethod.methodDescription
            )
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

    public init(
        amount: Int?,
        methodId: String?,
        methodName: String?,
        methodDescription: String?
    ) {
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
        shippingAddress: PrimerAddress?
    ) {
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
