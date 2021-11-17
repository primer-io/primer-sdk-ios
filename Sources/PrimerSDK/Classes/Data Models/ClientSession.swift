//
//  ClientSession.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 12/10/21.
//

import Foundation

public class ClientSession: Codable {
    
    let metadata: [String: Any]?
    let paymentMethod: ClientSession.PaymentMethod?
    let order: ClientSession.Order?
    let customer: Customer?
    let inputOptions: InputOptions?
    
    enum CodingKeys: String, CodingKey {
        case metadata, paymentMethod, order, customer, inputOptions
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let tmpMetadata = (try? container.decode([String: AnyCodable]?.self, forKey: .metadata)) ?? nil
        if let metadataData = try? JSONEncoder().encode(tmpMetadata),
           let metadataJsonObject = try? JSONSerialization.jsonObject(with: metadataData, options: .allowFragments),
           let metadataJson = metadataJsonObject as? [String: Any] {
            self.metadata = metadataJson
        } else {
            self.metadata = nil
        }
        
        self.paymentMethod = (try? container.decode(ClientSession.PaymentMethod?.self, forKey: .paymentMethod)) ?? nil
        self.order = (try? container.decode(Order?.self, forKey: .order)) ?? nil
        self.customer = (try? container.decode(Customer?.self, forKey: .customer)) ?? nil
        self.inputOptions = (try? container.decode(InputOptions?.self, forKey: .inputOptions)) ?? nil
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(paymentMethod, forKey: .paymentMethod)
        try container.encode(order, forKey: .order)
        try container.encode(customer, forKey: .customer)
        
        if let metadata = metadata,
           let metadataData = try? JSONSerialization.data(withJSONObject: metadata, options: .fragmentsAllowed),
           let metadataCodable = try? JSONDecoder().decode([String: AnyCodable]?.self, from: metadataData) {
            try container.encode(metadataCodable, forKey: .metadata)
        }
    }
    
    // MARK: - ClientSession.Action
    
    public class Action: NSObject, Encodable {
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
    
    // MARK: - ClientSession.PaymentMethod
    
    public class PaymentMethod: Codable {
        let vaultOnSuccess: Bool
        let paymentMethodOptions: [[String: Any]]?
        
        enum CodingKeys: String, CodingKey {
            case vaultOnSuccess, paymentMethodOptions
        }
        
        required public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.vaultOnSuccess = (try? container.decode(Bool.self, forKey: .vaultOnSuccess)) ?? false
            
            if let tmpOptions = (try? container.decode([[String: AnyCodable]]?.self, forKey: .paymentMethodOptions)),
               let optionsData = try? JSONEncoder().encode(tmpOptions),
               let optionsJson = (try? JSONSerialization.jsonObject(with: optionsData, options: .allowFragments)) as? [[String: Any]]
            {
                self.paymentMethodOptions = optionsJson
            } else {
                self.paymentMethodOptions = nil
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(vaultOnSuccess, forKey: .vaultOnSuccess)
            
            if let options = paymentMethodOptions,
               let optionsData = try? JSONSerialization.data(withJSONObject: options, options: .fragmentsAllowed),
               let optionsCodable = try? JSONDecoder().decode([String: AnyCodable]?.self, from: optionsData) {
                try container.encode(optionsCodable, forKey: .paymentMethodOptions)
            }
        }
    }
    
    // MARK: - ClientSession.Order
    
    public struct Order: Codable {
        let totalAmount: Int?
        let totalTaxAmount: Int?
        let countryCode: CountryCode?
        let currencyCode: Currency?
        let fees: [Fee]?
        let items: [LineItem]?
        let shippingAmount: Int?
        
        enum CodingKeys: String, CodingKey {
            case totalAmount, totalTaxAmount, countryCode, currencyCode, fees, items, shippingAmount
        }
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            totalAmount = (try? container.decode(Int?.self, forKey: .totalAmount)) ?? nil
            totalTaxAmount = (try? container.decode(Int?.self, forKey: .totalTaxAmount)) ?? nil
            countryCode = (try? container.decode(CountryCode?.self, forKey: .countryCode)) ?? nil
            currencyCode = (try? container.decode(Currency?.self, forKey: .currencyCode)) ?? nil
            fees = (try? container.decode([ClientSession.Order.Fee]?.self, forKey: .fees)) ?? nil
            items = (try? container.decode([LineItem]?.self, forKey: .items)) ?? nil
            shippingAmount = (try? container.decode(Int?.self, forKey: .shippingAmount)) ?? nil
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(totalAmount, forKey: .totalAmount)
            try? container.encode(totalTaxAmount, forKey: .totalTaxAmount)
            try? container.encode(countryCode, forKey: .countryCode)
            try? container.encode(currencyCode, forKey: .currencyCode)
            try? container.encode(fees, forKey: .fees)
            try? container.encode(items, forKey: .items)
            try? container.encode(shippingAmount, forKey: .shippingAmount)
        }
        
        // MARK: ClientSession.Order.LineItem
        
        public struct LineItem: Codable {
            let quantity: Int?
            let unitAmount: UInt?
            let discountAmount: UInt?
            let reference: String?
            let name: String?
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
    
    // MARK: - ClientSession.InputOptions
    
    public struct InputOptions: Codable {
        let cardInformation: CardInformation?
        let billingAddress: BillingAddress?
        
        
        struct CardInformation: Codable {
            let cardholderName: CaptureData
        }
        
        struct BillingAddress: Codable {
            let postalCode: CaptureData
        }
        
        struct CaptureData: Codable {
            let capture: Bool
            let required: Bool
        }
        
        var captureZip: Bool { billingAddress?.postalCode.capture ?? false }
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
