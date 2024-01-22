//
//  Klarna.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 24/3/21.
//

import Foundation

extension Request.Body {
    public class Klarna {}
}

extension Response.Body {
    public class Klarna {}
}

public enum KlarnaSessionType: String, Codable {
    case hostedPaymentPage = "HOSTED_PAYMENT_PAGE"
    case recurringPayment = "RECURRING_PAYMENT"
}

// MARK: KLARNA API DATA MODELS

extension Request.Body.Klarna {

    struct CreateCustomerToken: Codable {

        let paymentMethodConfigId: String
        let sessionId: String
        let authorizationToken: String
        let description: String?
        let localeData: PrimerLocaleData
    }

    struct CreatePaymentSession: Codable {

        let paymentMethodConfigId: String
        let sessionType: KlarnaSessionType
        var localeData: PrimerLocaleData?
        let description: String?
        let redirectUrl: String?
        let totalAmount: Int?
        let orderItems: [OrderItem]?
    }

    struct FinalizePaymentSession: Codable {

        let paymentMethodConfigId: String
        let sessionId: String
    }
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

    struct CreatePaymentSession: Codable {

        var sessionType: KlarnaSessionType {
            return hppSessionId == nil ? .recurringPayment : .hostedPaymentPage
        }
        let clientToken: String
        let sessionId: String
        let categories: [Response.Body.Klarna.SessionCategory]
        let hppSessionId: String?
        let hppRedirectUrl: String?
    }

    struct CustomerToken: Codable {

        let customerTokenId: String?
        let sessionData: Response.Body.Klarna.SessionData
    }

    struct SessionCategory: Codable {

        let identifier: String
        let name: String
        let descriptiveAssetUrl: String
        let standardAssetUrl: String
    }

    public struct SessionData: Codable {

        public let recurringDescription: String?
        public let purchaseCountry: String?
        public let purchaseCurrency: String?
        public let locale: String?
        public let orderAmount: Int?
        public let orderLines: [Response.Body.Klarna.SessionOrderLines]
        public let billingAddress: Response.Body.Klarna.BillingAddress?
        public let tokenDetails: Response.Body.Klarna.TokenDetails?
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
