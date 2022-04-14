//
//  ClientSession.swift
//  PrimerSDK
//
//  Created by Evangelos on 22/11/21.
//

#if canImport(UIKit)

import Foundation

public class ClientSession: Codable {
    
    let clientSessionId: String?
    let paymentMethod: ClientSession.PaymentMethod?
    let order: ClientSession.Order?
    let customer: ClientSession.Customer?
    
    enum CodingKeys: String, CodingKey {
        case clientSessionId, paymentMethod, order, customer // metadata
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientSessionId = (try? container.decode(String?.self, forKey: .clientSessionId)) ?? nil
        self.paymentMethod = (try? container.decode(ClientSession.PaymentMethod?.self, forKey: .paymentMethod)) ?? nil
        self.order = (try? container.decode(ClientSession.Order?.self, forKey: .order)) ?? nil
        self.customer = (try? container.decode(ClientSession.Customer?.self, forKey: .customer)) ?? nil
        
        // Replace settings
        PrimerSettings.modify(withClientSession: self)
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(paymentMethod, forKey: .paymentMethod)
        try container.encode(order, forKey: .order)
        try container.encode(customer, forKey: .customer)
    }
    
    // MARK: - ClientSession.Action
    
    public class Action: NSObject, Encodable {
        
        static func unselectPaymentMethod() {
            let actions: [ClientSession.Action] = [ClientSession.Action(type: "UNSELECT_PAYMENT_METHOD", params: nil)]
            requestClientSessionWithActions(actions)
        }
        
        static func selectPaymentMethodWithParameters(_ parameters: [String: Any]) {
            let actions: [ClientSession.Action] = [ClientSession.Action(type: "SELECT_PAYMENT_METHOD", params: parameters)]
            requestClientSessionWithActions(actions)
        }
        
        static func setPostalCodeWithParameters(_ parameters: [String: Any]) {
            let actions: [ClientSession.Action] = [ClientSession.Action(type: "SET_BILLING_ADDRESS", params: parameters)]
            requestClientSessionWithActions(actions)
        }
        
        static func dispatchMultipleActions(_ actions: [ClientSession.Action]) {
            requestClientSessionWithActions(actions)
        }
        
        public var type: String
        public var params: [String: Any]?
        
        private enum CodingKeys : String, CodingKey {
            case type, params
        }
        
        public init(type: String, params: [String: Any]? = nil) {
            self.type = type
            self.params = params
            super.init()
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            
            if let params = params,
               let paramsData = try? JSONSerialization.data(withJSONObject: params, options: .fragmentsAllowed),
               let paramsCodable = try? JSONDecoder().decode([String: AnyCodable]?.self, from: paramsData) {
                try container.encode(paramsCodable, forKey: .params)
            }
        }
        
        public func toDictionary() -> [String: Any]? {
            do {
                return try self.asDictionary()
            } catch {
                return nil
            }
        }
    }
    
    // MARK: ClientSession.Address
    
    public struct Address: Codable {
        let firstName: String?
        let lastName: String?
        let addressLine1: String?
        let addressLine2: String?
        let city: String?
        let postalCode: String?
        let state: String?
        let countryCode: CountryCode?
        
        public func toString() -> String {
            return "\(addressLine1 ?? "")\(addressLine2?.withComma ?? "")\(city?.withComma ?? "")\(postalCode?.withComma ?? "")\(countryCode?.rawValue.withComma ?? "")"
        }
        
    }
    
    // MARK: - ClientSession.PaymentMethod
    
    public class PaymentMethod: Codable {
        let vaultOnSuccess: Bool
        let options: [[String: Any]]?
        
        enum CodingKeys: String, CodingKey {
            case vaultOnSuccess, options
        }
        
        required public init(from decoder: Decoder) throws {
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
        
        public func encode(to encoder: Encoder) throws {
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
    
    public struct Order: Codable {
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
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            id = (try? container.decode(String?.self, forKey: .id)) ?? nil
            merchantAmount = (try? container.decode(Int?.self, forKey: .merchantAmount)) ?? nil
            totalOrderAmount = (try? container.decode(Int?.self, forKey: .totalOrderAmount)) ?? nil
            totalTaxAmount = (try? container.decode(Int?.self, forKey: .totalTaxAmount)) ?? nil
            countryCode = (try? container.decode(CountryCode?.self, forKey: .countryCode)) ?? nil
            currencyCode = (try? container.decode(Currency?.self, forKey: .currencyCode)) ?? nil
            fees = (try? container.decode([ClientSession.Order.Fee]?.self, forKey: .fees)) ?? nil
            lineItems = (try? container.decode([LineItem]?.self, forKey: .lineItems)) ?? nil
            shippingAmount = (try? container.decode(Int?.self, forKey: .shippingAmount)) ?? nil
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
            try? container.encode(shippingAmount, forKey: .shippingAmount)
        }
        
        // MARK: ClientSession.Order.LineItem
        
        public struct LineItem: Codable {
            let itemId: String?
            let quantity: Int
            let amount: Int?
            let discountAmount: Int?
            let reference: String?
            let name: String?
            let description: String?
            
            func toOrderItem() throws -> OrderItem {
                return try OrderItem(
                    name: self.description ?? "Item",
                    unitAmount: self.amount,
                    quantity: self.quantity,
                    isPending: false)
            }
        }
        
        // MARK: ClientSession.Order.Fee
        
        public struct Fee: Codable {
            let id: String
            let amount: Int
            
            enum CodingKeys: String, CodingKey {
                case id, amount
            }
            
            public init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                id = try container.decode(String.self, forKey: .id)
                amount = try container.decode(Int.self, forKey: .amount)
            }
            
            public func encode(to encoder: Encoder) throws {
                var container = encoder.container(keyedBy: CodingKeys.self)
                try container.encode(id, forKey: .id)
                try container.encode(amount, forKey: .amount)
            }
        }
    }
    
    // MARK: ClientSession.Customer
    
    public struct Customer: Codable {
        let id: String?
        let firstName: String?
        let lastName: String?
        let emailAddress: String?
        let mobileNumber: String?
        let billingAddress: ClientSession.Address?
        let shippingAddress: ClientSession.Address?
        let taxId: String?
        
        enum CodingKeys: String, CodingKey {
            case id = "customerId", firstName, lastName, emailAddress, mobileNumber, billingAddress, shippingAddress, taxId
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

extension ClientSession.Action {
    
    private static func requestClientSessionWithActions(_ actions: [ClientSession.Action]) {
                
        firstly {
            ClientSession.Action.raiseClientSessionUpdateDidStartEvent()
        }
        .then { () -> Promise<PrimerConfiguration> in
            let clientSessionService: ClientSessionServiceProtocol = DependencyContainer.resolve()
            let appState: AppStateProtocol = DependencyContainer.resolve()
            let clientSessionActionsRequest = ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))
            return clientSessionService.requestClientSessionWithActions(actionsRequest: clientSessionActionsRequest)
        }
        .then { primerConfiguration -> Promise<Void> in
            ClientSession.Action.setPrimerConfiguration(primerConfiguration)
        }
        .done {
            ClientSession.Action.raiseClientSessionUpdateDidFinishEvent()
        }
        .catch { error in
            ErrorHandler.handle(error: error)
            DispatchQueue.main.async {
                PrimerDelegateProxy.checkoutFailed(with: error)
            }
        }
    }
    
    private static func raiseClientSessionUpdateDidFinishEvent() {
        PrimerDelegateProxy.clientSessionUpdateDidFinish()
    }
    
    private static func raiseClientSessionUpdateDidStartEvent() -> Promise<Void> {
        return Promise { seal in
            PrimerDelegateProxy.clientSessionUpdateDidStart()
            seal.fulfill()
        }
    }
    
    private static func setPrimerConfiguration(_ primerConfiguration: PrimerConfiguration) -> Promise<Void> {
        return Promise { seal in
            let appState: AppStateProtocol = DependencyContainer.resolve()
            appState.primerConfiguration = primerConfiguration
            seal.fulfill()
        }
    }
}

#endif
