//
//  ClientSession.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

// swiftlint:disable type_body_length
// swiftlint:disable file_length

import Foundation

final class ClientSession {

    // MARK: - ClientSession.Action

    final class Action: NSObject, Encodable {

        static func makeBillingAddressDictionaryRequestFromParameters(_ parameters: [String: Any]) -> [String: Any] {
            return ["billingAddress": parameters]
        }

        static func makeShippingAddressDictionaryRequestFromParameters(_ parameters: [String: Any]) -> [String: Any] {
            return ["shippingAddress": parameters]
        }

        static func selectPaymentMethodActionWithParameters(_ parameters: [String: Any]) -> ClientSession.Action {
            ClientSession.Action(type: .selectPaymentMethod, params: parameters)
        }

        static func setBillingAddressActionWithParameters(_ parameters: [String: Any]) -> ClientSession.Action {
            ClientSession.Action(type: .setBillingAddress,
                                 params: makeBillingAddressDictionaryRequestFromParameters(parameters))
        }

        static func setCustomerFirstName(_ firstName: String) -> ClientSession.Action {
            ClientSession.Action(type: .setCustomerFirstName,
                                 params: ["firstName": firstName])
        }

        static func setCustomerLastName(_ lastName: String) -> ClientSession.Action {
            ClientSession.Action(type: .setCustomerLastName,
                                 params: ["lastName": lastName])
        }

        static func setCustomerEmailAddress(_ emailAddress: String) -> ClientSession.Action {
            ClientSession.Action(type: .setCustomerEmailAddress,
                                 params: ["emailAddress": emailAddress])
        }

        static func setShippingAddressActionWithParameters(_ parameters: [String: Any]) -> ClientSession.Action {
            ClientSession.Action(type: .setShippingAddress, params: makeShippingAddressDictionaryRequestFromParameters(parameters))
        }

        static func selectShippingMethodActionWithParameters(_ parameters: [String: Any]) -> ClientSession.Action {
            ClientSession.Action(type: .selectShippingMethod, params: parameters)
        }

        static func setMobileNumberAction(mobileNumber: String) -> ClientSession.Action {
            ClientSession.Action(type: .setMobileNumber, params: ["mobileNumber": mobileNumber])
        }

        // swiftlint:disable:next nesting
        internal enum ActionType: String {
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

        internal var type: ActionType
        internal var params: [String: Any]?

        // swiftlint:disable:next nesting
        private enum CodingKeys: String, CodingKey {
            case type, params
        }

        internal init(type: ActionType, params: [String: Any]? = nil) {
            self.type = type
            self.params = params
            super.init()
        }

        internal func encode(to encoder: Encoder) throws {
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

    internal struct Address: Codable {
        let firstName: String?
        let lastName: String?
        let addressLine1: String?
        let addressLine2: String?
        let city: String?
        let postalCode: String?
        let state: String?
        let countryCode: CountryCode?
    }

    // MARK: ClientSession.Customer

    internal struct Customer: Codable {

        let id: String?
        let firstName: String?
        let lastName: String?
        let emailAddress: String?
        let mobileNumber: String?
        let billingAddress: ClientSession.Address?
        let shippingAddress: ClientSession.Address?
        let taxId: String?

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

        internal init(from decoder: Decoder) throws {
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

        internal init(
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

    internal struct Order: Codable {

        let id: String?
        let merchantAmount: Int?
        let totalOrderAmount: Int?
        let totalTaxAmount: Int?
        let countryCode: CountryCode?
        let currencyCode: Currency?
        let fees: [ClientSession.Order.Fee]?
        let lineItems: [ClientSession.Order.LineItem]?
        let shippingMethod: ShippingMethod?

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

        internal init(
            id: String?,
            merchantAmount: Int?,
            totalOrderAmount: Int?,
            totalTaxAmount: Int?,
            countryCode: CountryCode?,
            currencyCode: Currency?,
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

        internal init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = (try? container.decode(String?.self, forKey: .id)) ?? nil
            merchantAmount = (try? container.decode(Int?.self, forKey: .merchantAmount)) ?? nil
            totalOrderAmount = (try? container.decode(Int?.self, forKey: .totalOrderAmount)) ?? nil
            totalTaxAmount = (try? container.decode(Int?.self, forKey: .totalTaxAmount)) ?? nil
            countryCode = (try? container.decode(CountryCode?.self, forKey: .countryCode)) ?? nil
            if let cCode = try? container.decode(String.self, forKey: .currencyCode) {
                let currencyLoader = CurrencyLoader(storage: DefaultCurrencyStorage(),
                                                    networkService: CurrencyNetworkService())
                currencyCode = currencyLoader.getCurrency(cCode)
            } else {
                currencyCode = nil
            }
            fees = (try? container.decode([ClientSession.Order.Fee]?.self, forKey: .fees)) ?? nil
            lineItems = (try? container.decode([ClientSession.Order.LineItem]?.self, forKey: .lineItems)) ?? nil
            shippingMethod = (try? container.decode(ShippingMethod?.self, forKey: .shippingMethod)) ?? nil
        }

        internal func encode(to encoder: Encoder) throws {
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
        internal struct LineItem: Codable {

            let itemId: String?
            let quantity: Int
            let amount: Int?
            let discountAmount: Int?
            let name: String?
            let description: String?
            let taxAmount: Int?
            let taxCode: String?
            let productType: String?

            func toOrderItem() throws -> ApplePayOrderItem {
                let applePayOptions = PrimerSettings.current.paymentMethodOptions.applePayOptions
                let name = (self.description ?? applePayOptions?.merchantName)
                return try ApplePayOrderItem(
                    name: name ?? "Item",
                    unitAmount: self.amount,
                    quantity: self.quantity,
                    discountAmount: self.discountAmount,
                    taxAmount: self.taxAmount,
                    isPending: false)
            }
        }

        // MARK: ClientSession.Order.Fee

        // swiftlint:disable:next nesting
        internal struct Fee: Codable {

            let type: FeeType
            let amount: Int
            // swiftlint:disable:next nesting
            enum CodingKeys: String, CodingKey {
                case type, amount
            }
            // swiftlint:disable:next nesting
            enum FeeType: String, Codable {
                case surcharge = "SURCHARGE"
            }
        }

        // swiftlint:disable nesting
        internal struct ShippingMethod: Codable {
            let amount: Int
            let methodId: String?
            let methodName: String?
            let methodDescription: String?

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

    final class PaymentMethod: Codable {

        let vaultOnSuccess: Bool
        let options: [[String: Any]]?
        let orderedAllowedCardNetworks: [String]?
        let descriptor: String?

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case vaultOnSuccess,
                 options,
                 orderedAllowedCardNetworks,
                 descriptor
        }

        init(
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

        required internal init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.vaultOnSuccess = (try? container.decode(Bool.self, forKey: .vaultOnSuccess)) ?? false
            self.orderedAllowedCardNetworks = try? container.decode([String].self, forKey: .orderedAllowedCardNetworks)
            self.descriptor = try? container.decode(String.self, forKey: .descriptor)

            if let tmpOptions = (try? container.decode([[String: AnyCodable]]?.self, forKey: .options)),
               let optionsData = try? JSONEncoder().encode(tmpOptions),
               let optionsJson = (try? JSONSerialization.jsonObject(with: optionsData,
                                                                    options: .allowFragments)) as? [[String: Any]] {
                self.options = optionsJson
            } else {
                self.options = nil
            }
        }

        internal func encode(to encoder: Encoder) throws {
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

    final class APIResponse: Codable {

        let clientSessionId: String?
        let paymentMethod: ClientSession.PaymentMethod?
        let order: ClientSession.Order?
        let customer: ClientSession.Customer?
        let testId: String?

        // swiftlint:disable:next nesting
        enum CodingKeys: String, CodingKey {
            case clientSessionId, paymentMethod, order, customer, testId // metadata
        }

        init(
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

        required internal init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.clientSessionId = (try? container.decode(String?.self, forKey: .clientSessionId)) ?? nil
            self.paymentMethod = (try? container.decode(ClientSession.PaymentMethod?.self,
                                                        forKey: .paymentMethod)) ?? nil
            self.order = (try? container.decode(ClientSession.Order?.self, forKey: .order)) ?? nil
            self.customer = (try? container.decode(ClientSession.Customer?.self, forKey: .customer)) ?? nil
            self.testId = (try? container.decode(String?.self, forKey: .testId)) ?? nil
        }

        internal func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(paymentMethod, forKey: .paymentMethod)
            try container.encode(order, forKey: .order)
            try container.encode(customer, forKey: .customer)
            try? container.encode(testId, forKey: .testId)
        }
    }
}

internal extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data,
                                                                options: .allowFragments) as? [String: Any] else {
            let error = NSError(domain: "EncodableError",
                                code: 1001,
                                userInfo: [NSLocalizedDescriptionKey: "Failed to serialize object to dictionary"])
            throw error
        }
        return dictionary
    }
}
// swiftlint:enable type_body_length
