//
//  Klarna.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

extension Response.Body {
    public final class Klarna {}
}

extension Response.Body.Klarna {
    public struct BillingAddress: Codable {
        public let addressLine1: String?
        public let addressLine2: String?
        public let addressLine3: String?
        public let city: String?
        public let countryCode: String?
        public let email: String?
        public let firstName: String?
        public let lastName: String?
        public let phoneNumber: String?
        public let postalCode: String?
        public let state: String?
        public let title: String?
    }

    public struct SessionData: Codable {
        public let recurringDescription: String?
        public let purchaseCountry: String?
        public let purchaseCurrency: String?
        public let locale: String?
        public let orderAmount: Int?
        public let orderTaxAmount: Int?
        public let orderLines: [SessionOrderLines]
        public let billingAddress: BillingAddress?
        public let shippingAddress: BillingAddress?
        public let tokenDetails: TokenDetails?
    }

    public struct SessionOrderLines: Codable {
        public let type: String?
        public let name: String?
        public let quantity: Int?
        public let unitPrice: Int?
        public let totalAmount: Int?
        public let totalDiscountAmount: Int?

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case type = "type"
            case name = "name"
            case quantity = "quantity"
            case unitPrice = "unit_price"
            case totalAmount = "total_amount"
            case totalDiscountAmount = "total_discount_amount"
        }
    }

    public struct TokenDetails: Codable {
        public let brand: String?
        public let maskedNumber: String?
        public let type: String
        public let expiryDate: String?

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case brand = "brand"
            case maskedNumber = "masked_number"
            case type = "type"
            case expiryDate = "expiry_date"
        }
    }
}
