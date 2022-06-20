//
//  ClientSession.swift
//  PrimerSDK
//
//  Created by Evangelos on 22/11/21.
//

#if canImport(UIKit)

import Foundation

internal class ClientSessionAPIResponse: Codable {
    
    let clientSessionId: String?
    let paymentMethod: ClientSessionAPIResponse.PaymentMethod?
    let order: ClientSessionAPIResponse.Order?
    let customer: ClientSessionAPIResponse.Customer?
    
    enum CodingKeys: String, CodingKey {
        case clientSessionId, paymentMethod, order, customer // metadata
    }
    
    required internal init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientSessionId = (try? container.decode(String?.self, forKey: .clientSessionId)) ?? nil
        self.paymentMethod = (try? container.decode(ClientSessionAPIResponse.PaymentMethod?.self, forKey: .paymentMethod)) ?? nil
        self.order = (try? container.decode(ClientSessionAPIResponse.Order?.self, forKey: .order)) ?? nil
        self.customer = (try? container.decode(ClientSessionAPIResponse.Customer?.self, forKey: .customer)) ?? nil
    }
    
    internal func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(paymentMethod, forKey: .paymentMethod)
        try container.encode(order, forKey: .order)
        try container.encode(customer, forKey: .customer)
    }
    
    // MARK: - ClientSession.Action
    
    internal class Action: NSObject, Encodable {
        
        internal enum ActionType: String {
            case selectPaymentMethod = "SELECT_PAYMENT_METHOD"
            case unselectPaymentMethod = "UNSELECT_PAYMENT_METHOD"
            case setBillingAddress = "SET_BILLING_ADDRESS"
            case setSurchargeFee = "SET_SURCHARGE_FEE"
        }
                
        internal var type: ActionType
        internal var params: [String: Any]?
        
        private enum CodingKeys : String, CodingKey {
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
        
        internal func toDictionary() -> [String: Any]? {
            do {
                return try self.asDictionary()
            } catch {
                return nil
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
        
        internal func toString() -> String {
            return [firstName, lastName, addressLine1, addressLine2, city, postalCode, state, countryCode?.rawValue]
                .compactMap({ $0 })
                .joined(separator: ", ")
        }
        
    }
    
    // MARK: - ClientSession.PaymentMethod
    
    internal class PaymentMethod: Codable {
        let vaultOnSuccess: Bool
        let options: [[String: Any]]?
        
        enum CodingKeys: String, CodingKey {
            case vaultOnSuccess, options
        }
        
        required internal init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.vaultOnSuccess = (try? container.decode(Bool.self, forKey: .vaultOnSuccess)) ?? false
            
            if let tmpOptions = (try? container.decode([[String: AnyCodable]]?.self, forKey: .options)),
               let optionsData = try? JSONEncoder().encode(tmpOptions),
               let optionsJson = (try? JSONSerialization.jsonObject(with: optionsData, options: .allowFragments)) as? [[String: Any]]
            {
                self.options = optionsJson
            } else {
                self.options = nil
            }
        }
        
        internal func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(vaultOnSuccess, forKey: .vaultOnSuccess)
            
            if let options = options,
               let optionsData = try? JSONSerialization.data(withJSONObject: options, options: .fragmentsAllowed),
               let optionsCodable = try? JSONDecoder().decode([String: AnyCodable]?.self, from: optionsData) {
                try container.encode(optionsCodable, forKey: .options)
            }
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
        let fees: [Fee]?
        let lineItems: [LineItem]?
        let shippingAmount: Int?
        
        enum CodingKeys: String, CodingKey {
            case id = "orderId", merchantAmount, totalOrderAmount, totalTaxAmount, countryCode, currencyCode, fees, lineItems, shippingAmount
        }
        
        internal init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = (try? container.decode(String?.self, forKey: .id)) ?? nil
            merchantAmount = (try? container.decode(Int?.self, forKey: .merchantAmount)) ?? nil
            totalOrderAmount = (try? container.decode(Int?.self, forKey: .totalOrderAmount)) ?? nil
            totalTaxAmount = (try? container.decode(Int?.self, forKey: .totalTaxAmount)) ?? nil
            countryCode = (try? container.decode(CountryCode?.self, forKey: .countryCode)) ?? nil
            currencyCode = (try? container.decode(Currency?.self, forKey: .currencyCode)) ?? nil
            fees = (try? container.decode([ClientSessionAPIResponse.Order.Fee]?.self, forKey: .fees)) ?? nil
            lineItems = (try? container.decode([LineItem]?.self, forKey: .lineItems)) ?? nil
            shippingAmount = (try? container.decode(Int?.self, forKey: .shippingAmount)) ?? nil
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
            try? container.encode(shippingAmount, forKey: .shippingAmount)
        }
        
        // MARK: ClientSession.Order.LineItem
        
        internal struct LineItem: Codable {
            let itemId: String?
            let quantity: Int
            let amount: Int?
            let discountAmount: Int?
            let reference: String?
            let name: String?
            let description: String?
            
            func toOrderItem() throws -> OrderItem {
                return try OrderItem(
                    name: (self.description ?? PrimerSettings.current.paymentMethodOptions.applePayOptions?.merchantName) ?? "Item",
                    unitAmount: self.amount,
                    quantity: self.quantity,
                    isPending: false)
            }
        }
        
        // MARK: ClientSession.Order.Fee
        
        internal struct Fee: Codable {
            let type: String
            let amount: Int
            
            enum CodingKeys: String, CodingKey {
                case type, amount
            }
            
            internal init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                type = try container.decode(String.self, forKey: .type)
                amount = try container.decode(Int.self, forKey: .amount)
            }
            
            internal func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(type, forKey: .type)
                try container.encode(amount, forKey: .amount)
            }
        }
    }
    
    // MARK: ClientSession.Customer
    
    internal struct Customer: Codable {
        let id: String?
        let firstName: String?
        let lastName: String?
        let emailAddress: String?
        let mobileNumber: String?
        let billingAddress: ClientSessionAPIResponse.Address?
        let shippingAddress: ClientSessionAPIResponse.Address?
        let taxId: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "customerId", firstName, lastName, emailAddress, mobileNumber, billingAddress, shippingAddress, taxId
        }
        
        internal init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = (try? container.decode(String?.self, forKey: .id)) ?? nil
            self.firstName = (try? container.decode(String?.self, forKey: .firstName)) ?? nil
            self.lastName = (try? container.decode(String?.self, forKey: .lastName)) ?? nil
            self.emailAddress = (try? container.decode(String?.self, forKey: .emailAddress)) ?? nil
            self.mobileNumber = (try? container.decode(String?.self, forKey: .mobileNumber)) ?? nil
            self.billingAddress = (try? container.decode(ClientSessionAPIResponse.Address?.self, forKey: .billingAddress)) ?? nil
            self.shippingAddress = (try? container.decode(ClientSessionAPIResponse.Address?.self, forKey: .shippingAddress)) ?? nil
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
}

internal extension Encodable {
    func asDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        guard let dictionary = try JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any] else {
            throw NSError()
        }
        return dictionary
    }
}

extension ClientSessionAPIResponse.Action {
    
    private static func requestPrimerConfigurationWithActions(_ actions: [ClientSessionAPIResponse.Action]) -> Promise<Void> {
        return Promise { seal in
            firstly {
                ClientSessionAPIResponse.Action.raiseClientSessionUpdateWillStartEventForActions()
            }
            .then { () -> Promise<PrimerAPIConfiguration> in
                let clientSessionService: ClientSessionServiceProtocol = DependencyContainer.resolve()
                let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))
                return clientSessionService.requestPrimerConfigurationWithActions(actionsRequest: clientSessionActionsRequest)
            }
            .then { apiConfiguration -> Promise<PrimerAPIConfiguration> in
                ClientSessionAPIResponse.Action.setPrimerConfiguration(apiConfiguration)
            }
            .then { apiConfiguration -> Promise<Void> in
                ClientSessionAPIResponse.Action.raiseClientSessionUpdateDidFinishEvent(apiConfiguration: apiConfiguration)
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private static func raiseClientSessionUpdateDidFinishEvent(apiConfiguration: PrimerAPIConfiguration) -> Promise<Void> {
        return Promise { seal in
            PrimerDelegateProxy.primerClientSessionDidUpdate(PrimerClientSession(from: apiConfiguration))
            seal.fulfill()
        }
    }
    
    private static func raiseClientSessionUpdateWillStartEventForActions() -> Promise<Void> {
        return Promise { seal in
            PrimerDelegateProxy.primerClientSessionWillUpdate()
            seal.fulfill()
        }
    }
    
    private static func setPrimerConfiguration(_ apiConfiguration: PrimerAPIConfiguration) -> Promise<PrimerAPIConfiguration> {
        return Promise { seal in
            AppState.current.apiConfiguration = apiConfiguration
            seal.fulfill(apiConfiguration)
        }
    }
}

extension ClientSessionAPIResponse.Action {
    
    static func unselectPaymentMethodIfNeeded() -> Promise<Void> {
        return Promise { seal in
            
            guard Primer.shared.intent == .checkout else {
                seal.fulfill()
                return
            }
            
            firstly {
                requestPrimerConfigurationWithActions([ClientSessionAPIResponse.Action.unselectPaymentMethodAction()])
            }
            .done {
                seal.fulfill()
            }
            .catch { error in
                // Do not raise error, we want to finalize the flow.
                seal.fulfill()
            }
        }
    }
    
    static func selectPaymentMethodWithParametersIfNeeded(_ parameters: [String: Any]) -> Promise<Void> {
        return Promise { seal in
            
            guard Primer.shared.intent == .checkout else {
                seal.fulfill()
                return
            }
            
            firstly {
                requestPrimerConfigurationWithActions([ClientSessionAPIResponse.Action.selectPaymentMethodActionWithParameters(parameters)])
            }
            .done {
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
    
    static func setPostalCodeWithParameters(_ parameters: [String: Any]) -> Promise<Void> {
        let actions: [ClientSessionAPIResponse.Action] = [ClientSessionAPIResponse.Action(type: .setBillingAddress, params: parameters)]
        return requestPrimerConfigurationWithActions(actions)
    }
    
    static func dispatchMultipleActions(_ actions: [ClientSessionAPIResponse.Action]) -> Promise<Void> {
        return requestPrimerConfigurationWithActions(actions)
    }
}

extension ClientSessionAPIResponse.Action {
    
    static func makeBillingAddressDictionaryRequestFromParameters(_ parameters: [String: Any]) -> [String: Any] {
        return ["billingAddress": parameters]
    }
}

extension ClientSessionAPIResponse.Action {
        
    static func selectPaymentMethodActionWithParameters(_ parameters: [String: Any]) -> ClientSessionAPIResponse.Action {
        ClientSessionAPIResponse.Action(type: .selectPaymentMethod, params: parameters)
    }

    static func unselectPaymentMethodAction() -> ClientSessionAPIResponse.Action {
        ClientSessionAPIResponse.Action(type: .unselectPaymentMethod, params: nil)
    }
    
    static func setBillingAddressActionWithParameters(_ parameters: [String: Any]) -> ClientSessionAPIResponse.Action {
        ClientSessionAPIResponse.Action(type: .setBillingAddress, params: makeBillingAddressDictionaryRequestFromParameters(parameters))
    }
}

#endif
