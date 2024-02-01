//
//  MerchantHelpers.swift
//  Debug App
//
//  Created by Stefan Vrancianu on 01.02.2024.
//  Copyright © 2024 Primer API Ltd. All rights reserved.
//

import UIKit

struct MerchantMockDataManager {
    
    enum SessionType {
        case normal
        case klarna
    }
    
    static let customerIdStorageKey = "io.primer.debug.customer-id"
    
    static var customerId: String {
        if let customerId = UserDefaults.standard.string(forKey: customerIdStorageKey) {
            return customerId
        }

        let customerId = "ios-customer-\(String.randomString(length: 8))"
        UserDefaults.standard.set(customerId, forKey: customerIdStorageKey)
        return customerId
    }
    
    static func getClientSession(sessionType: SessionType) -> ClientSessionRequestBody {
        return sessionType == .normal ? normalClientSession : klarnaClientSession
    }
    
    static var klarnaClientSession = ClientSessionRequestBody(
        customerId: customerId,
        orderId: "ios-order-\(String.randomString(length: 8))",
        currencyCode: .EUR,
        amount: nil,
        metadata: nil,
        customer: ClientSessionRequestBody.Customer(
            firstName: "John",
            lastName: "Smith",
            emailAddress: "john@primer.io",
            mobileNumber: "+4901761428434",
            billingAddress: Address(
                firstName: "John",
                lastName: "Smith",
                addressLine1: "Neue Schönhauser Str. 2",
                addressLine2: nil,
                city: "Berlin",
                state: "Berlin",
                countryCode: "DE",
                postalCode: "10178"),
            shippingAddress: Address(
                firstName: "John",
                lastName: "Smith",
                addressLine1: "Neue Schönhauser Str. 2",
                addressLine2: nil,
                city: "Berlin",
                state: "Berlin",
                countryCode: "DE",
                postalCode: "10178")
        ),
        order: ClientSessionRequestBody.Order(
            countryCode: .de,
            lineItems: [
                ClientSessionRequestBody.Order.LineItem(
                    itemId: "this item",
                    description: "item-123",
                    amount: 1000,
                    quantity: 1,
                    discountAmount: nil,
                    taxAmount: nil)
            ]),
        paymentMethod: ClientSessionRequestBody.PaymentMethod(
            vaultOnSuccess: false,
            options: nil,
            paymentType: nil
        ),
        testParams: nil)
    
    static var normalClientSession = ClientSessionRequestBody(
        customerId: customerId,
        orderId: "ios-order-\(String.randomString(length: 8))",
        currencyCode: .EUR,
        amount: nil,
        metadata: nil,
        customer: ClientSessionRequestBody.Customer(
            firstName: "John",
            lastName: "Smith",
            emailAddress: "john@primer.io",
            mobileNumber: "+4478888888888",
            billingAddress: Address(
                firstName: "John",
                lastName: "Smith",
                addressLine1: "65 York Road",
                addressLine2: nil,
                city: "London",
                state: "Greater London",
                countryCode: "GB",
                postalCode: "NW06 4OM"),
            shippingAddress: Address(
                firstName: "John",
                lastName: "Smith",
                addressLine1: "9446 Richmond Road",
                addressLine2: nil,
                city: "London",
                state: "Greater London",
                countryCode: "GB",
                postalCode: "EC53 8BT")
        ),
        order: ClientSessionRequestBody.Order(
            countryCode: .de,
            lineItems: [
                ClientSessionRequestBody.Order.LineItem(
                    itemId: "fancy-shoes-\(String.randomString(length: 4))",
                    description: "Fancy Shoes",
                    amount: 600,
                    quantity: 1,
                    discountAmount: nil,
                    taxAmount: nil)
            ]),
        paymentMethod: ClientSessionRequestBody.PaymentMethod(
            vaultOnSuccess: false,
            options: nil,
            paymentType: nil
        ),
        testParams: nil)
    
}

