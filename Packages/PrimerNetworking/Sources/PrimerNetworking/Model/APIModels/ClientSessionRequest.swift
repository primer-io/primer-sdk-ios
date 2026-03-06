//
//  ClientSessionRequest.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerFoundation

extension Request.Body {

    public struct ClientSession {

        public let customerId: String?
        public let orderId: String?
        public let currencyCode: Currency?
        public let amount: Int?
        public let metadata: [String: Any]?
        public let customer: Request.Body.ClientSession.Customer?
        public let order: Request.Body.ClientSession.Order?
        public let paymentMethod: Request.Body.ClientSession.PaymentMethod?

        init(
            customerId: String? = nil,
            orderId: String? = nil,
            currencyCode: Currency? = nil,
            amount: Int? = nil,
            metadata: [String: Any]? = nil,
            customer: Request.Body.ClientSession.Customer? = nil,
            order: Request.Body.ClientSession.Order? = nil,
            paymentMethod: Request.Body.ClientSession.PaymentMethod? = nil
        ) {
            self.customerId = customerId
            self.orderId = orderId
            self.currencyCode = currencyCode
            self.amount = amount
            self.metadata = metadata
            self.customer = customer
            self.order = order
            self.paymentMethod = paymentMethod
        }

        // swiftlint:disable:next nesting
        public struct Customer: Codable {
            public let firstName: String?
            public let lastName: String?
            public let emailAddress: String?
            public let mobileNumber: String?
            public let billingAddress: PaymentAPIModelAddress?
            public let shippingAddress: PaymentAPIModelAddress?

            init(
                firstName: String? = nil,
                lastName: String? = nil,
                emailAddress: String? = nil,
                mobileNumber: String? = nil,
                billingAddress: PaymentAPIModelAddress? = nil,
                shippingAddress: PaymentAPIModelAddress? = nil
            ) {
                self.firstName = firstName
                self.lastName = lastName
                self.emailAddress = emailAddress
                self.mobileNumber = mobileNumber
                self.billingAddress = billingAddress
                self.shippingAddress = shippingAddress
            }
        }
        // swiftlint:disable:next nesting
        public struct Order: Codable {
            public let countryCode: CountryCode?
            public let lineItems: [LineItem]?

            init(countryCode: CountryCode? = nil, lineItems: [LineItem]? = nil) {
                self.countryCode = countryCode
                self.lineItems = lineItems
            }

            // swiftlint:disable:next nesting
            public struct LineItem: Codable {
                public let itemId: String?
                public let description: String?
                public let amount: Int?
                public let quantity: Int?

                init(
                    itemId: String? = nil,
                    description: String? = nil,
                    amount: Int? = nil,
                    quantity: Int? = nil
                ) {
                    self.itemId = itemId
                    self.description = description
                    self.amount = amount
                    self.quantity = quantity
                }
            }
        }
        // swiftlint:disable:next nesting
        public struct PaymentMethod {
            public let vaultOnSuccess: Bool?
            public let options: [String: Any]?

            init(vaultOnSuccess: Bool? = nil, options: [String: Any]? = nil) {
                self.vaultOnSuccess = vaultOnSuccess
                self.options = options
            }
        }
    }
}

extension Request.Body {

    public struct ClientTokenValidation: Encodable {
        public let clientToken: String

        public init(clientToken: String) {
            self.clientToken = clientToken
        }
    }
}
