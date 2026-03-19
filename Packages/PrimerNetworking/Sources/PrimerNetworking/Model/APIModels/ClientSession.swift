//
//  ClientSession.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_body_length
// swiftlint:disable file_length

import Foundation
import PrimerFoundation

public final class ClientSession {

    // MARK: - ClientSession.Action

    public final class Action: NSObject, Encodable {

        public static func makeBillingAddressDictionaryRequestFromParameters(_ parameters: [String: Any]) -> [String: Any] {
            ["billingAddress": parameters]
        }

        public static func makeShippingAddressDictionaryRequestFromParameters(_ parameters: [String: Any]) -> [String: Any] {
            ["shippingAddress": parameters]
        }

        public static func selectPaymentMethodActionWithParameters(_ parameters: [String: Any]) -> ClientSession.Action {
            ClientSession.Action(type: .selectPaymentMethod, params: parameters)
        }

        public static func setBillingAddressActionWithParameters(_ parameters: [String: Any]) -> ClientSession.Action {
            ClientSession.Action(
                type: .setBillingAddress,
                params: makeBillingAddressDictionaryRequestFromParameters(parameters)
            )
        }

        public static func setCustomerFirstName(_ firstName: String) -> ClientSession.Action {
            ClientSession.Action(
                type: .setCustomerFirstName,
                params: ["firstName": firstName]
            )
        }

        public static func setCustomerLastName(_ lastName: String) -> ClientSession.Action {
            ClientSession.Action(
                type: .setCustomerLastName,
                params: ["lastName": lastName]
            )
        }

        public static func setCustomerEmailAddress(_ emailAddress: String) -> ClientSession.Action {
            ClientSession.Action(
                type: .setCustomerEmailAddress,
                params: ["emailAddress": emailAddress]
            )
        }

        public static func setShippingAddressActionWithParameters(_ parameters: [String: Any]) -> ClientSession.Action {
            ClientSession.Action(type: .setShippingAddress, params: makeShippingAddressDictionaryRequestFromParameters(parameters))
        }

        public static func selectShippingMethodActionWithParameters(_ parameters: [String: Any]) -> ClientSession.Action {
            ClientSession.Action(type: .selectShippingMethod, params: parameters)
        }

        public static func setMobileNumberAction(mobileNumber: String) -> ClientSession.Action {
            ClientSession.Action(type: .setMobileNumber, params: ["mobileNumber": mobileNumber])
        }

        // swiftlint:disable:next nesting
        public enum ActionType: String {
            case selectPaymentMethod = "SELECT_PAYMENT_METHOD"
            case unselectPaymentMethod = "UNSELECT_PAYMENT_METHOD"
            case setBillingAddress = "SET_BILLING_ADDRESS"
            case setShippingAddress = "SET_SHIPPING_ADDRESS"
            case setSurchargeFee = "SET_SURCHARGE_FEE"
            case selectShippingMethod = "SELECT_SHIPPING_METHOD"
            case setMobileNumber = "SET_MOBILE_NUMBER"
            case setCustomerFirstName = "SET_CUSTOMER_FIRST_NAME"
            case setCustomerLastName = "SET_CUSTOMER_LAST_NAME"
            case setCustomerEmailAddress = "SET_EMAIL_ADDRESS"
        }

        public var type: ActionType
        public var params: [String: Any]?

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case type, params
        }

        public init(type: ActionType, params: [String: Any]? = nil) {
            self.type = type
            self.params = params
            super.init()
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type.rawValue, forKey: .type)

            if let params = params,
               let paramsData = try? JSONSerialization.data(withJSONObject: params, options: .fragmentsAllowed),
               let paramsCodable = try? JSONDecoder().decode([String: AnyCodable]?.self, from: paramsData) {
                try container.encode(paramsCodable, forKey: .params)
            }
        }
    }

    // MARK: ClientSession.Address

    public struct Address: Codable {
        public let firstName: String?
        public let lastName: String?
        public let addressLine1: String?
        public let addressLine2: String?
        public let city: String?
        public let postalCode: String?
        public let state: String?
        public let countryCode: CountryCode?

        public init(
            firstName: String? = nil,
            lastName: String? = nil,
            addressLine1: String? = nil,
            addressLine2: String? = nil,
            city: String? = nil,
            postalCode: String? = nil,
            state: String? = nil,
            countryCode: CountryCode? = nil
        ) {
            self.firstName = firstName
            self.lastName = lastName
            self.addressLine1 = addressLine1
            self.addressLine2 = addressLine2
            self.city = city
            self.postalCode = postalCode
            self.state = state
            self.countryCode = countryCode
        }
    }

    // MARK: ClientSession.Customer

    public struct Customer: Codable {

        public let id: String?
        public let firstName: String?
        public let lastName: String?
        public let emailAddress: String?
        public let mobileNumber: String?
        public let billingAddress: ClientSession.Address?
        public let shippingAddress: ClientSession.Address?
        public let taxId: String?

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case id = "customerId"
            case firstName
            case lastName
            case emailAddress
            case mobileNumber
            case billingAddress
            case shippingAddress
            case taxId
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = (try? container.decode(String?.self, forKey: .id)) ?? nil
            self.firstName = (try? container.decode(String?.self, forKey: .firstName)) ?? nil
            self.lastName = (try? container.decode(String?.self, forKey: .lastName)) ?? nil
            self.emailAddress = (try? container.decode(String?.self, forKey: .emailAddress)) ?? nil
            self.mobileNumber = (try? container.decode(String?.self, forKey: .mobileNumber)) ?? nil
            self.billingAddress = (try? container.decode(ClientSession.Address?.self, forKey: .billingAddress)) ?? nil
            self.shippingAddress = (try? container.decode(ClientSession.Address?.self, forKey: .shippingAddress)) ?? nil
            self.taxId = (try? container.decode(String?.self, forKey: .taxId)) ?? nil
        }

        public init(
            id: String? = nil,
            firstName: String? = nil,
            lastName: String? = nil,
            emailAddress: String? = nil,
            mobileNumber: String? = nil,
            billingAddress: Address? = nil,
            shippingAddress: Address? = nil,
            taxId: String? = nil
        ) {
            self.id = id
            self.firstName = firstName
            self.lastName = lastName
            self.emailAddress = emailAddress
            self.mobileNumber = mobileNumber
            self.billingAddress = billingAddress
            self.shippingAddress = shippingAddress
            self.taxId = taxId
        }
    }

    // MARK: - ClientSession.Order

    public struct Order: Codable {

        public let id: String?
        public let merchantAmount: Int?
        public let totalOrderAmount: Int?
        public let totalTaxAmount: Int?
        public let countryCode: CountryCode?
        public let currencyCode: String?
        public let fees: [ClientSession.Order.Fee]?
        public let lineItems: [ClientSession.Order.LineItem]?
        public let shippingMethod: ShippingMethod?

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case id = "orderId"
            case merchantAmount
            case totalOrderAmount
            case totalTaxAmount
            case countryCode
            case currencyCode
            case fees
            case lineItems
            case shippingMethod = "shipping"
        }

        public init(
            id: String?,
            merchantAmount: Int?,
            totalOrderAmount: Int?,
            totalTaxAmount: Int?,
            countryCode: CountryCode?,
            currencyCode: String?,
            fees: [ClientSession.Order.Fee]?,
            lineItems: [ClientSession.Order.LineItem]?,
            shippingMethod: ShippingMethod? = nil
        ) {
            self.id = id
            self.merchantAmount = merchantAmount
            self.totalOrderAmount = totalOrderAmount
            self.totalTaxAmount = totalTaxAmount
            self.countryCode = countryCode
            self.currencyCode = currencyCode
            self.fees = fees
            self.lineItems = lineItems
            self.shippingMethod = shippingMethod
        }

        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = (try? container.decode(String?.self, forKey: .id)) ?? nil
            merchantAmount = (try? container.decode(Int?.self, forKey: .merchantAmount)) ?? nil
            totalOrderAmount = (try? container.decode(Int?.self, forKey: .totalOrderAmount)) ?? nil
            totalTaxAmount = (try? container.decode(Int?.self, forKey: .totalTaxAmount)) ?? nil
            countryCode = (try? container.decode(CountryCode?.self, forKey: .countryCode)) ?? nil
            currencyCode = (try? container.decode(String?.self, forKey: .currencyCode)) ?? nil
            fees = (try? container.decode([ClientSession.Order.Fee]?.self, forKey: .fees)) ?? nil
            lineItems = (try? container.decode([ClientSession.Order.LineItem]?.self, forKey: .lineItems)) ?? nil
            shippingMethod = (try? container.decode(ShippingMethod?.self, forKey: .shippingMethod)) ?? nil
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(merchantAmount, forKey: .merchantAmount)
            try? container.encode(totalOrderAmount, forKey: .totalOrderAmount)
            try? container.encode(totalTaxAmount, forKey: .totalTaxAmount)
            try? container.encode(countryCode, forKey: .countryCode)
            try? container.encode(currencyCode, forKey: .currencyCode)
            try? container.encode(fees, forKey: .fees)
            try? container.encode(lineItems, forKey: .lineItems)
            try? container.encode(shippingMethod, forKey: .shippingMethod)
        }

        // MARK: ClientSession.Order.LineItem

        // swiftlint:disable:next nesting
        public struct LineItem: Codable {

            public let itemId: String?
            public let quantity: Int
            public let amount: Int?
            public let discountAmount: Int?
            public let name: String?
            public let description: String?
            public let taxAmount: Int?
            public let taxCode: String?
            public let productType: String?
        }

        // MARK: ClientSession.Order.Fee

        // swiftlint:disable:next nesting
        public struct Fee: Codable {

            public let type: FeeType
            public let amount: Int
            // swiftlint:disable:next nesting
            enum CodingKeys: String, CodingKey {
                case type, amount
            }
            // swiftlint:disable:next nesting
            public enum FeeType: String, Codable {
                case surcharge = "SURCHARGE"
            }
        }

        // swiftlint:disable nesting
        public struct ShippingMethod: Codable {
            public let amount: Int
            public let methodId: String?
            public let methodName: String?
            public let methodDescription: String?

            enum CodingKeys: String, CodingKey {
                case amount
                case methodId
                case methodName
                case methodDescription
            }
        }
        // swiftlint:enable nesting
    }

    // MARK: - ClientSession.PaymentMethod

    public final class PaymentMethod: Codable {

        public let vaultOnSuccess: Bool
        public let options: [[String: Any]]?
        public let orderedAllowedCardNetworks: [String]?
        public let descriptor: String?

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case vaultOnSuccess,
                 options,
                 orderedAllowedCardNetworks,
                 descriptor
        }

        public init(
            vaultOnSuccess: Bool,
            options: [[String: Any]]?,
            orderedAllowedCardNetworks: [String]?,
            descriptor: String?
        ) {
            self.vaultOnSuccess = vaultOnSuccess
            self.options = options
            self.orderedAllowedCardNetworks = orderedAllowedCardNetworks
            self.descriptor = descriptor
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.vaultOnSuccess = (try? container.decode(Bool.self, forKey: .vaultOnSuccess)) ?? false
            self.orderedAllowedCardNetworks = try? container.decode([String].self, forKey: .orderedAllowedCardNetworks)
            self.descriptor = try? container.decode(String.self, forKey: .descriptor)

            if let tmpOptions = (try? container.decode([[String: AnyCodable]]?.self, forKey: .options)),
               let optionsData = try? JSONEncoder().encode(tmpOptions),
               let optionsJson = (try? JSONSerialization.jsonObject(
                   with: optionsData,
                   options: .allowFragments
               )) as? [[String: Any]] {
                self.options = optionsJson
            } else {
                self.options = nil
            }
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(vaultOnSuccess, forKey: .vaultOnSuccess)
            try container.encode(orderedAllowedCardNetworks, forKey: .orderedAllowedCardNetworks)

            if let options = options,
               let optionsData = try? JSONSerialization.data(withJSONObject: options, options: .fragmentsAllowed),
               let optionsCodable = try? JSONDecoder().decode([String: AnyCodable]?.self, from: optionsData) {
                try container.encode(optionsCodable, forKey: .options)
            }
        }
    }

    public final class APIResponse: Codable {

        public let clientSessionId: String?
        public let paymentMethod: ClientSession.PaymentMethod?
        public let order: ClientSession.Order?
        public let customer: ClientSession.Customer?
        public let testId: String?

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case clientSessionId, paymentMethod, order, customer, testId // metadata
        }

        public init(
            clientSessionId: String?,
            paymentMethod: ClientSession.PaymentMethod?,
            order: ClientSession.Order?,
            customer: ClientSession.Customer?,
            testId: String?
        ) {
            self.clientSessionId = clientSessionId
            self.paymentMethod = paymentMethod
            self.order = order
            self.customer = customer
            self.testId = testId
        }

        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.clientSessionId = (try? container.decode(String?.self, forKey: .clientSessionId)) ?? nil
            self.paymentMethod = (try? container.decode(
                ClientSession.PaymentMethod?.self,
                forKey: .paymentMethod
            )) ?? nil
            self.order = (try? container.decode(ClientSession.Order?.self, forKey: .order)) ?? nil
            self.customer = (try? container.decode(ClientSession.Customer?.self, forKey: .customer)) ?? nil
            self.testId = (try? container.decode(String?.self, forKey: .testId)) ?? nil
        }

        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(paymentMethod, forKey: .paymentMethod)
            try container.encode(order, forKey: .order)
            try container.encode(customer, forKey: .customer)
            try? container.encode(testId, forKey: .testId)
        }
    }
}
// swiftlint:enable type_body_length
