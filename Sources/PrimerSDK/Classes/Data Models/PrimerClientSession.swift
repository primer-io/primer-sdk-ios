//
//  PrimerClientSession.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@objc public final class PrimerClientSession: NSObject, Codable {

    public let customerId: String?
    public let orderId: String?
    public let currencyCode: String?
    public let totalAmount: Int?
    public let lineItems: [PrimerLineItem]?
    public let orderDetails: PrimerOrder?
    public let customer: PrimerCustomer?
    public let paymentMethod: PaymentMethod?
    public let fees: [PrimerFee]?

    /// Client-session payment-method options.
    ///
    /// Nested because the top-level `PrimerPaymentMethod` name is already taken by the
    /// payment-method configuration model. The property name — the only spelling merchant code
    /// writes — matches Android.
    public struct PaymentMethod: Codable, Equatable {
        /// Card networks the merchant allows, in the configured order. A network the SDK does not
        /// recognise becomes `.unknown`, which is the same `"OTHER"` wire value Android's
        /// `CardNetwork.Type.OTHER` fallback produces, so nothing is dropped.
        public let orderedAllowedCardNetworks: [CardNetwork]

        public init(orderedAllowedCardNetworks: [CardNetwork]) {
            self.orderedAllowedCardNetworks = orderedAllowedCardNetworks
        }
    }

    public init(
        customerId: String?,
        orderId: String?,
        currencyCode: String?,
        totalAmount: Int?,
        lineItems: [PrimerLineItem]?,
        orderDetails: PrimerOrder?,
        customer: PrimerCustomer?,
        paymentMethod: PaymentMethod?,
        fees: [PrimerFee]?
    ) {
        self.customerId = customerId
        self.orderId = orderId
        self.currencyCode = currencyCode
        self.totalAmount = totalAmount
        self.lineItems = lineItems
        self.orderDetails = orderDetails
        self.customer = customer
        self.paymentMethod = paymentMethod
        self.fees = fees
    }

    /// Retained so existing Swift callers keep compiling after `paymentMethod` and `fees` were added.
    public convenience init(
        customerId: String?,
        orderId: String?,
        currencyCode: String?,
        totalAmount: Int?,
        lineItems: [PrimerLineItem]?,
        orderDetails: PrimerOrder?,
        customer: PrimerCustomer?
    ) {
        self.init(
            customerId: customerId,
            orderId: orderId,
            currencyCode: currencyCode,
            totalAmount: totalAmount,
            lineItems: lineItems,
            orderDetails: orderDetails,
            customer: customer,
            paymentMethod: nil,
            fees: nil
        )
    }
}

extension PrimerClientSession {
    convenience init(from apiConfiguration: PrimerAPIConfiguration) {
        let session = apiConfiguration.clientSession
        self.init(
            customerId: session?.customer?.id,
            orderId: session?.order?.id,
            currencyCode: session?.order?.currencyCode?.code,
            totalAmount: session?.order?.totalOrderAmount,
            lineItems: session?.order?.lineItems?.map(PrimerLineItem.init(lineItem:)),
            orderDetails: PrimerOrder(clientSessionOrder: session?.order),
            customer: PrimerCustomer(customer: session?.customer),
            paymentMethod: session?.paymentMethod.map { method in
                PaymentMethod(
                    orderedAllowedCardNetworks: (method.orderedAllowedCardNetworks ?? [])
                        .map { CardNetwork(rawValue: $0) ?? .unknown }
                )
            },
            fees: session?.order?.fees?.map { PrimerFee(type: $0.type.rawValue, amount: $0.amount) }
        )
    }
}

private extension PrimerLineItem {
    convenience init(lineItem: ClientSession.Order.LineItem) {
        self.init(
            itemId: lineItem.itemId,
            itemDescription: lineItem.description,
            amount: lineItem.amount,
            discountAmount: lineItem.discountAmount,
            quantity: lineItem.quantity,
            taxCode: lineItem.taxCode,
            taxAmount: lineItem.taxAmount
        )
    }
}

private extension PrimerCustomer {
    convenience init(customer: ClientSession.Customer?) {
        self.init(
            emailAddress: customer?.emailAddress,
            mobileNumber: customer?.mobileNumber,
            firstName: customer?.firstName,
            lastName: customer?.lastName,
            billingAddress: customer?.billingAddress.map(PrimerAddress.init),
            shippingAddress: customer?.shippingAddress.map(PrimerAddress.init)
        )
    }
}

private extension PrimerAddress {
    convenience init(address: ClientSession.Address) {
        self.init(
            firstName: address.firstName,
            lastName: address.lastName,
            addressLine1: address.addressLine1,
            addressLine2: address.addressLine2,
            postalCode: address.postalCode,
            city: address.city,
            state: address.state,
            countryCode: address.countryCode?.rawValue
        )
    }
}
