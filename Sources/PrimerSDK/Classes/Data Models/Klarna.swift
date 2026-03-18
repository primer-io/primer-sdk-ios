//
//  Klarna.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerCore
import PrimerNetworking

extension Request.Body {
    public final class Klarna {}
}

public enum KlarnaSessionType: String, Codable {
    case oneOffPayment = "ONE_OFF_PAYMENT"
    case recurringPayment = "RECURRING_PAYMENT"
}

// MARK: KLARNA API DATA MODELS

extension Request.Body.Klarna {
    struct CreateCustomerToken: Codable {
        let paymentMethodConfigId: String
        let sessionId: String
        let authorizationToken: String?
        let description: String?
        let localeData: PrimerLocaleData?
    }
    struct CreatePaymentSession: Codable {
        let paymentMethodConfigId: String
        let sessionType: KlarnaSessionType
        var localeData: KlarnaLocaleData?
        let description: String?
        let redirectUrl: String?
        let totalAmount: Int?
        let orderItems: [OrderItem]?
        let billingAddress: Response.Body.Klarna.BillingAddress?
        let shippingAddress: Response.Body.Klarna.BillingAddress?
    }
    struct KlarnaLocaleData: Codable {
        let countryCode: String
        let currencyCode: String
        let localeCode: String
    }
    struct FinalizePaymentSession: Codable {
        let paymentMethodConfigId: String
        let sessionId: String
    }
    struct OrderItem: Codable {
        let name: String
        let unitAmount: Int
        let reference: String?
        let quantity: Int
        let discountAmount: Int?
        let productType: String?
        let taxAmount: Int?
    }
}

extension Response.Body.Klarna {
    struct PaymentSession: Codable {
        var sessionType: KlarnaSessionType {
            hppSessionId == nil ? .recurringPayment : .oneOffPayment
        }
        let clientToken: String
        let sessionId: String
        let categories: [SessionCategory]
        let hppSessionId: String?
        let hppRedirectUrl: String?
    }
    struct CustomerToken: Codable {
        let customerTokenId: String?
        let sessionData: SessionData
    }
    struct SessionCategory: Codable {
        let identifier: String
        let name: String
        let descriptiveAssetUrl: String
        let standardAssetUrl: String
    }
}
