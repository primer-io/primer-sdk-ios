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
    let order: Order?
    let customer: Customer?
    
    enum CodingKeys: String, CodingKey {
        case metadata, paymentMethod, order, customer
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
    
    public class Action: NSObject, Encodable {
        var type: String
        var params: [String: Any]?
        
        private enum CodingKeys : String, CodingKey {
            case type, params
        }
        
        public init(type: String, params: [String: Any]?) {
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
