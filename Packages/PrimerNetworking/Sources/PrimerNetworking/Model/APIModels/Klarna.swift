//
//  Klarna.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

extension Request.Body {
    public final class Klarna {}
}

extension Response.Body {
    public final class Klarna {}
}

public enum KlarnaSessionType: String, Codable {
    case oneOffPayment = "ONE_OFF_PAYMENT"
    case recurringPayment = "RECURRING_PAYMENT"
}

// MARK: - Request

extension Request.Body.Klarna {
    public struct CreateCustomerToken: Codable {
        public let paymentMethodConfigId: String
        public let sessionId: String
        public let authorizationToken: String?
        public let description: String?
        public let localeData: PrimerLocaleData?

        public init(paymentMethodConfigId: String, sessionId: String, authorizationToken: String?, description: String?, localeData: PrimerLocaleData?) {
            self.paymentMethodConfigId = paymentMethodConfigId
            self.sessionId = sessionId
            self.authorizationToken = authorizationToken
            self.description = description
            self.localeData = localeData
        }
    }

    public struct CreatePaymentSession: Codable {
        public let paymentMethodConfigId: String
        public let sessionType: KlarnaSessionType
        public var localeData: KlarnaLocaleData?
        public let description: String?
        public let redirectUrl: String?
        public let totalAmount: Int?
        public let orderItems: [OrderItem]?
        public let billingAddress: Response.Body.Klarna.BillingAddress?
        public let shippingAddress: Response.Body.Klarna.BillingAddress?

        public init(paymentMethodConfigId: String, sessionType: KlarnaSessionType, localeData: KlarnaLocaleData? = nil, description: String?, redirectUrl: String?, totalAmount: Int?, orderItems: [OrderItem]?, billingAddress: Response.Body.Klarna.BillingAddress?, shippingAddress: Response.Body.Klarna.BillingAddress?) {
            self.paymentMethodConfigId = paymentMethodConfigId
            self.sessionType = sessionType
            self.localeData = localeData
            self.description = description
            self.redirectUrl = redirectUrl
            self.totalAmount = totalAmount
            self.orderItems = orderItems
            self.billingAddress = billingAddress
            self.shippingAddress = shippingAddress
        }
    }

    public struct KlarnaLocaleData: Codable {
        public let countryCode: String
        public let currencyCode: String
        public let localeCode: String

        public init(countryCode: String, currencyCode: String, localeCode: String) {
            self.countryCode = countryCode
            self.currencyCode = currencyCode
            self.localeCode = localeCode
        }
    }

    public struct FinalizePaymentSession: Codable {
        public let paymentMethodConfigId: String
        public let sessionId: String

        public init(paymentMethodConfigId: String, sessionId: String) {
            self.paymentMethodConfigId = paymentMethodConfigId
            self.sessionId = sessionId
        }
    }

    public struct OrderItem: Codable {
        public let name: String
        public let unitAmount: Int
        public let reference: String?
        public let quantity: Int
        public let discountAmount: Int?
        public let productType: String?
        public let taxAmount: Int?

        public init(name: String, unitAmount: Int, reference: String?, quantity: Int, discountAmount: Int?, productType: String?, taxAmount: Int?) {
            self.name = name
            self.unitAmount = unitAmount
            self.reference = reference
            self.quantity = quantity
            self.discountAmount = discountAmount
            self.productType = productType
            self.taxAmount = taxAmount
        }
    }
}

// MARK: - Response

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

    public struct PaymentSession: Codable {
        public var sessionType: KlarnaSessionType {
            hppSessionId == nil ? .recurringPayment : .oneOffPayment
        }
        public let clientToken: String
        public let sessionId: String
        public let categories: [SessionCategory]
        public let hppSessionId: String?
        public let hppRedirectUrl: String?
    }

    public struct CustomerToken: Codable {
        public let customerTokenId: String?
        public let sessionData: SessionData
    }

    public struct SessionCategory: Codable {
        public let identifier: String
        public let name: String
        public let descriptiveAssetUrl: String
        public let standardAssetUrl: String
    }
}
