//
//  PayPal.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

extension Request.Body {
    public final class PayPal {}
}

extension Response.Body {
    public final class PayPal {}
}

extension Request.Body.PayPal {

    public struct ConfirmBillingAgreement: Encodable {
        public let paymentMethodConfigId, tokenId: String

        public init(paymentMethodConfigId: String, tokenId: String) {
            self.paymentMethodConfigId = paymentMethodConfigId
            self.tokenId = tokenId
        }
    }

    public struct CreateBillingAgreement: Codable {

        public let paymentMethodConfigId: String
        public let returnUrl: String
        public let cancelUrl: String

        public init(paymentMethodConfigId: String, returnUrl: String, cancelUrl: String) {
            self.paymentMethodConfigId = paymentMethodConfigId
            self.returnUrl = returnUrl
            self.cancelUrl = cancelUrl
        }
    }

    public struct CreateOrder: Codable {

        public let paymentMethodConfigId: String
        public let amount: Int
        public let currencyCode: String
        public var locale: CountryCode?
        public let returnUrl: String
        public let cancelUrl: String

        public init(paymentMethodConfigId: String, amount: Int, currencyCode: String, locale: CountryCode? = nil, returnUrl: String, cancelUrl: String) {
            self.paymentMethodConfigId = paymentMethodConfigId
            self.amount = amount
            self.currencyCode = currencyCode
            self.locale = locale
            self.returnUrl = returnUrl
            self.cancelUrl = cancelUrl
        }
    }

    public struct PayerInfo: Codable {

        public let paymentMethodConfigId: String
        public let orderId: String

        public init(paymentMethodConfigId: String, orderId: String) {
            self.paymentMethodConfigId = paymentMethodConfigId
            self.orderId = orderId
        }
    }
}

extension Response.Body.PayPal {

    public struct ConfirmBillingAgreement: Codable {

        public let billingAgreementId: String
        public let externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo
        public let shippingAddress: Response.Body.Tokenization.PayPal.ShippingAddress?
    }

    public struct CreateBillingAgreement: Codable {

        public let tokenId: String
        public let approvalUrl: String
    }

    public struct CreateOrder: Codable {

        public let orderId: String
        public let approvalUrl: String
    }

    public struct PayerInfo: Codable {

        public let orderId: String
        public let externalPayerInfo: Response.Body.Tokenization.PayPal.ExternalPayerInfo
    }
}
