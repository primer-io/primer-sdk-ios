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
    case dev, sandbox, staging, production
}

struct CreateClientTokenRequest: Codable {
    let orderId: String
    let amount: UInt
    let currencyCode: String
    let customerId: String?
    let metadata: [String: String]?
    let customer: Customer?
    let order: Order?
    let paymentMethod: PaymentMethod?
}

//struct CreateClientTokenRequest: Codable {
//    let customerId: String
//    let customerCountryCode: String?
//    var environment: Environment?
//}

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
    let emailAddress: String?
    let billingAddress: Address?
    let shippingAddress: Address?
    let mobileNumber: String?
    
    public init (
        emailAddress: String?,
        billingAddress: Address?,
        shippingAddress: Address?,
        mobileNumber: String?
    ) {
        self.emailAddress = emailAddress
        self.billingAddress = billingAddress
        self.shippingAddress = shippingAddress
        self.mobileNumber = mobileNumber
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

struct TransactionResponse {
    var id: String
    var date: String
    var status: String
    var requiredAction: [String: Any]
}
