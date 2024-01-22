//
//  ClientSessionAPIModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 5/9/22.
//

import Foundation

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

        var dictionaryValue: [String: Any]? {
            var dic: [String: Any] = [:]

            if let customerId = customerId {
                dic["customerId"] = customerId
            }

            if let orderId = orderId {
                dic["orderId"] = orderId
            }

            if let currencyCode = currencyCode {
                dic["currencyCode"] = currencyCode.code
            }

            if let amount = amount {
                dic["amount"] = amount
            }

            if let metadata = metadata {
                dic["metadata"] = metadata
            }

            if let customer = customer {
                dic["customer"] = customer.dictionaryValue
            }

            if let order = order {
                dic["order"] = order.dictionaryValue
            }

            if let paymentMethod = paymentMethod {
                dic["paymentMethod"] = paymentMethod.dictionaryValue
            }

            return dic.keys.count == 0 ? nil : dic
        }

		// swiftlint:disable:next nesting
        public struct Customer: Codable {
            public let firstName: String?
            public let lastName: String?
            public let emailAddress: String?
            public let mobileNumber: String?
            public let billingAddress: PaymentAPIModelAddress?
            public let shippingAddress: PaymentAPIModelAddress?

            var dictionaryValue: [String: Any]? {
                var dic: [String: Any] = [:]

                if let firstName = firstName {
                    dic["firstName"] = firstName
                }

                if let lastName = lastName {
                    dic["lastName"] = lastName
                }

                if let emailAddress = emailAddress {
                    dic["emailAddress"] = emailAddress
                }

                if let mobileNumber = mobileNumber {
                    dic["mobileNumber"] = mobileNumber
                }

                if let mobileNumber = mobileNumber {
                    dic["mobileNumber"] = mobileNumber
                }

                if let billingAddress = billingAddress {
                    dic["billingAddress"] = billingAddress.dictionaryValue
                }

                if let shippingAddress = shippingAddress {
                    dic["shippingAddress"] = shippingAddress.dictionaryValue
                }

                return dic.keys.count == 0 ? nil : dic
            }
        }
		// swiftlint:disable:next nesting
        public struct Order: Codable {
            public let countryCode: CountryCode?
            public let lineItems: [LineItem]?

            public var dictionaryValue: [String: Any]? {
                var dic: [String: Any] = [:]

                if let countryCode = countryCode {
                    dic["countryCode"] = countryCode.rawValue
                }

                if let lineItems = lineItems {
                    dic["lineItems"] = lineItems.compactMap({ $0.dictionaryValue })
                }

                return dic.keys.count == 0 ? nil : dic
            }
			// swiftlint:disable:next nesting
            public struct LineItem: Codable {
                public let itemId: String?
                public let description: String?
                public let amount: Int?
                public let quantity: Int?

                var dictionaryValue: [String: Any]? {
                    var dic: [String: Any] = [:]

                    if let itemId = itemId {
                        dic["itemId"] = itemId
                    }

                    if let description = description {
                        dic["description"] = description
                    }

                    if let amount = amount {
                        dic["amount"] = amount
                    }

                    if let quantity = quantity {
                        dic["quantity"] = quantity
                    }

                    return dic.keys.count == 0 ? nil : dic
                }
            }
        }
		// swiftlint:disable:next nesting
        public struct PaymentMethod {
            public let vaultOnSuccess: Bool?
            public let options: [String: Any]?

            var dictionaryValue: [String: Any]? {
                var dic: [String: Any] = [:]

                if let vaultOnSuccess = vaultOnSuccess {
                    dic["vaultOnSuccess"] = vaultOnSuccess
                }

                if let options = options {
                    dic["options"] = options
                }

                return dic.keys.count == 0 ? nil : dic
            }
        }
    }
}

public struct ClientSessionAction: Encodable {
    let actions: [ClientSession.Action]
}

public struct ClientSessionUpdateRequest: Encodable {
    let actions: ClientSessionAction
}
