//
//  PrimerClientSession.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
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

    public init(
        customerId: String?,
        orderId: String?,
        currencyCode: String?,
        totalAmount: Int?,
        lineItems: [PrimerLineItem]?,
        orderDetails: PrimerOrder?,
        customer: PrimerCustomer?
    ) {
        self.customerId = customerId
        self.orderId = orderId
        self.currencyCode = currencyCode
        self.totalAmount = totalAmount
        self.lineItems = lineItems
        self.orderDetails = orderDetails
        self.customer = customer
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
            lineItems: session?.order?.lineItems?.compactMap { PrimerLineItem(lineItem: $0, session: session) },
            orderDetails: PrimerOrder(clientSessionOrder: session?.order),
            customer: PrimerCustomer(customer: session?.customer)
        )
    }
}

private extension PrimerLineItem {
    convenience init(lineItem: ClientSession.Order.LineItem, session: ClientSession.APIResponse?) {
        self.init(
            itemId: lineItem.itemId,
            itemDescription: lineItem.description,
            amount: lineItem.amount,
            discountAmount: lineItem.discountAmount,
            quantity: lineItem.quantity,
            taxCode: session?.customer?.taxId,
            taxAmount: session?.order?.totalTaxAmount
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
