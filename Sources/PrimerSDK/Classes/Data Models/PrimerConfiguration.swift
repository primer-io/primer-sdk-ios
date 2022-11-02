//
//  PrimerAPIConfiguration.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/12/21.
//

#if canImport(UIKit)

import Foundation

typealias PrimerAPIConfiguration = Response.Body.Configuration

extension Request.URLParameters {
    
    class Configuration: Codable {
        
        let skipPaymentMethodTypes: [String]?
        let requestDisplayMetadata: Bool?
        let mockMode: Bool?
        
        private enum CodingKeys: String, CodingKey {
            case skipPaymentMethodTypes = "skipPaymentMethods"
            case requestDisplayMetadata = "withDisplayMetadata"
            case mockMode = "mockMode"
        }
        
        init(skipPaymentMethodTypes: [String]?, requestDisplayMetadata: Bool?, mockMode: Bool?) {
            self.skipPaymentMethodTypes = skipPaymentMethodTypes
            self.requestDisplayMetadata = requestDisplayMetadata
            self.mockMode = mockMode
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.skipPaymentMethodTypes = (try? container.decode([String]?.self, forKey: .skipPaymentMethodTypes)) ?? nil
            self.requestDisplayMetadata = (try? container.decode(Bool?.self, forKey: .requestDisplayMetadata)) ?? nil
            self.mockMode = (try? container.decode(Bool?.self, forKey: .mockMode)) ?? nil
            
            if skipPaymentMethodTypes == nil && requestDisplayMetadata == nil {
                throw InternalError.failedToDecode(message: "All values are nil", userInfo: nil, diagnosticsId: nil)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            if skipPaymentMethodTypes == nil && requestDisplayMetadata == nil {
                throw InternalError.failedToDecode(message: "All values are nil", userInfo: nil, diagnosticsId: nil)
            }
            
            if let skipPaymentMethodTypes = skipPaymentMethodTypes {
                try container.encode(skipPaymentMethodTypes, forKey: .skipPaymentMethodTypes)
            }
            
            if let requestDisplayMetadata = requestDisplayMetadata {
                try container.encode(requestDisplayMetadata, forKey: .requestDisplayMetadata)
            }
            
            if let mockMode = mockMode {
                try container.encode(mockMode, forKey: .mockMode)
            }
        }
        
        func toDictionary() -> [String: String]? {
            var dict: [String: String] = [:]
            
            if let skipPaymentMethodTypes = skipPaymentMethodTypes, !skipPaymentMethodTypes.isEmpty {
                dict[CodingKeys.skipPaymentMethodTypes.rawValue] = skipPaymentMethodTypes.joined(separator: ",")
                
                if let requestDisplayMetadata = requestDisplayMetadata {
                    dict[CodingKeys.requestDisplayMetadata.rawValue] = requestDisplayMetadata ? "true" : "false"
                }
            } else {
                if let requestDisplayMetadata = requestDisplayMetadata {
                    dict[CodingKeys.requestDisplayMetadata.rawValue] = requestDisplayMetadata ? "true" : "false"
                }
            }
            
            if let mockMode = mockMode {
                dict[CodingKeys.mockMode.rawValue] = mockMode ? "true" : "false"
            }
                        
            return dict.keys.isEmpty ? nil : dict
        }
    }
}

extension Response.Body {
    
    struct Configuration: Codable {
        
        static var current: PrimerAPIConfiguration? {
            return PrimerAPIConfigurationModule.apiConfiguration
        }
        
        static var paymentMethodConfigurations: [PrimerPaymentMethod]? {
            return PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods
        }
        
        var hasSurchargeEnabled: Bool {
            let pmSurcharge = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.paymentMethod?.options?.first(where: { $0["surcharge"] as? Int != nil })
            let cardSurcharge = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.paymentMethod?.options?.first(where: { (($0["networks"] as? [[String: Any]])?.first(where: { $0["surcharge"] as? Int != nil })) != nil  })
            return pmSurcharge != nil || cardSurcharge != nil
        }
        
        let coreUrl: String?
        let pciUrl: String?
        var clientSession: ClientSession.APIResponse?
        let paymentMethods: [PrimerPaymentMethod]?
        let keys: ThreeDS.Keys?
        let checkoutModules: [Response.Body.Configuration.CheckoutModule]?
        
        var isSetByClientSession: Bool {
            return clientSession != nil
        }
        
        internal let sdkSupportedPaymentMethodTypes: [PrimerPaymentMethodType] = PrimerPaymentMethodType.allCases
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.coreUrl = (try? container.decode(String?.self, forKey: .coreUrl)) ?? nil
            self.pciUrl = (try? container.decode(String?.self, forKey: .pciUrl)) ?? nil
            self.clientSession = (try? container.decode(ClientSession.APIResponse?.self, forKey: .clientSession)) ?? nil
            let throwables = try container.decode([Throwable<PrimerPaymentMethod>].self, forKey: .paymentMethods)
            self.paymentMethods = throwables.compactMap({ $0.value })
            self.keys = (try? container.decode(ThreeDS.Keys?.self, forKey: .keys)) ?? nil
            let moduleThrowables = try container.decode([Throwable<CheckoutModule>].self, forKey: .checkoutModules)
            self.checkoutModules = moduleThrowables.compactMap({ $0.value })
            
            if let options = clientSession?.paymentMethod?.options, !options.isEmpty {
                for paymentMethodOption in options {
                    if let type = paymentMethodOption["type"] as? String {
                        if type == PrimerPaymentMethodType.paymentCard.rawValue,
                            let networks = paymentMethodOption["networks"] as? [[String: Any]],
                           !networks.isEmpty
                        {
                            for network in networks {
                                guard network["type"] is String,
                                network["surcharge"] is Int
                                else { continue }
                                
                            }
                        } else if let surcharge = paymentMethodOption["surcharge"] as? Int,
                                  let paymentMethod = self.paymentMethods?.filter({ $0.type == type }).first
                        {
                            paymentMethod.hasUnknownSurcharge = false
                            paymentMethod.surcharge = surcharge
                        }
                    }
                }
            }
            
            if let paymentMethod = self.paymentMethods?.filter({ $0.type == PrimerPaymentMethodType.paymentCard.rawValue }).first {
                paymentMethod.hasUnknownSurcharge = true
                paymentMethod.surcharge = nil
            }
        }
        
        init(
            coreUrl: String?,
            pciUrl: String?,
            clientSession: ClientSession.APIResponse?,
            paymentMethods: [PrimerPaymentMethod]?,
            keys: ThreeDS.Keys?,
            checkoutModules: [PrimerAPIConfiguration.CheckoutModule]?
        ) {
            self.coreUrl = coreUrl
            self.pciUrl = pciUrl
            self.clientSession = clientSession
            self.paymentMethods = paymentMethods
            self.keys = keys
            self.checkoutModules = checkoutModules
        }
        
        func getConfigId(for type: String) -> String? {
            guard let method = self.paymentMethods?.filter({ $0.type == type }).first else { return nil }
            return method.id
        }
        
        func getProductId(for type: String) -> String? {
            guard let method = self.paymentMethods?
                    .first(where: { method in return method.type == type }) else { return nil }
            
            if let apayaOptions = method.options as? ApayaOptions {
                return apayaOptions.merchantAccountId
            } else {
                return nil
            }
        }
    }
}

protocol CheckoutModuleOptions: Codable {}

extension Response.Body.Configuration {
    
    struct CheckoutModule: Codable {
        
        let type: String
        let requestUrlStr: String?
        let options: CheckoutModuleOptions?
        
        private enum CodingKeys: String, CodingKey {
            case type, options
            case requestUrlStr = "requestUrl"
        }
        
        struct CardInformationOptions: CheckoutModuleOptions {
            let cardHolderName: Bool?
            let saveCardCheckbox: Bool?
            
            private enum CodingKeys: String, CodingKey {
                case cardHolderName
                case saveCardCheckbox
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.cardHolderName = (try? container.decode(Bool?.self, forKey: .cardHolderName)) ?? nil
                self.saveCardCheckbox = (try? container.decode(Bool?.self, forKey: .saveCardCheckbox)) ?? nil
                
                if self.cardHolderName == nil && self.saveCardCheckbox == nil {
                    let err = InternalError.failedToDecode(message: "All fields are nil", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    throw err
                }
            }
        }
        
        struct PostalCodeOptions: CheckoutModuleOptions {
            let firstName: Bool?
            let lastName: Bool?
            let city: Bool?
            let postalCode: Bool?
            let addressLine1: Bool?
            let addressLine2: Bool?
            let countryCode: Bool?
            let phoneNumber: Bool?
            let state: Bool?
            
            private enum CodingKeys: String, CodingKey {
                case firstName
                case lastName
                case city
                case postalCode
                case addressLine1
                case addressLine2
                case countryCode
                case phoneNumber
                case state
            }
            
            init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                self.firstName = (try? container.decode(Bool?.self, forKey: .firstName)) ?? nil
                self.lastName = (try? container.decode(Bool?.self, forKey: .lastName)) ?? nil
                self.city = (try? container.decode(Bool?.self, forKey: .city)) ?? nil
                self.postalCode = (try? container.decode(Bool?.self, forKey: .postalCode)) ?? nil
                self.addressLine1 = (try? container.decode(Bool?.self, forKey: .addressLine1)) ?? nil
                self.addressLine2 = (try? container.decode(Bool?.self, forKey: .addressLine2)) ?? nil
                self.countryCode = (try? container.decode(Bool?.self, forKey: .countryCode)) ?? nil
                self.phoneNumber = (try? container.decode(Bool?.self, forKey: .phoneNumber)) ?? nil
                self.state = (try? container.decode(Bool?.self, forKey: .state)) ?? nil
                
                if self.firstName == nil &&
                    self.lastName == nil &&
                    self.city == nil &&
                    self.postalCode == nil &&
                    self.addressLine1 == nil &&
                    self.addressLine2 == nil &&
                    self.countryCode == nil &&
                    self.phoneNumber == nil &&
                    self.state == nil
                {
                    let err = InternalError.failedToDecode(message: "All fields are nil", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    throw err
                }
            }
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(String.self, forKey: .type)
            self.requestUrlStr = (try? container.decode(String?.self, forKey: .requestUrlStr)) ?? nil
            
            if let options = (try? container.decode(CardInformationOptions.self, forKey: .options)) {
                self.options = options
            } else if let options = (try? container.decode(PostalCodeOptions.self, forKey: .options)) {
                self.options = options
            } else {
                self.options = nil
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try container.encode(type, forKey: .type)
            try container.encode(requestUrlStr, forKey: .requestUrlStr)
            
            if let options = options as? CardInformationOptions {
                try container.encode(options, forKey: .options)
            } else if let options = options as? PostalCodeOptions {
                try container.encode(options, forKey: .options)
            }
        }
    }
}

#endif

