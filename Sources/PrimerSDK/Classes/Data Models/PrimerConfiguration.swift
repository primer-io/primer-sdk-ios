//
//  PrimerAPIConfiguration.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/12/21.
//



import Foundation
import PassKit

typealias PrimerAPIConfiguration = Response.Body.Configuration

extension Request.URLParameters {
    
    class Configuration: Codable {
        
        let skipPaymentMethodTypes: [String]?
        let requestDisplayMetadata: Bool?
        
        private enum CodingKeys: String, CodingKey {
            case skipPaymentMethodTypes = "skipPaymentMethods"
            case requestDisplayMetadata = "withDisplayMetadata"
        }
        
        init(skipPaymentMethodTypes: [String]?, requestDisplayMetadata: Bool?) {
            self.skipPaymentMethodTypes = skipPaymentMethodTypes
            self.requestDisplayMetadata = requestDisplayMetadata
        }
        
        required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.skipPaymentMethodTypes = (try? container.decode([String]?.self, forKey: .skipPaymentMethodTypes)) ?? nil
            self.requestDisplayMetadata = (try? container.decode(Bool?.self, forKey: .requestDisplayMetadata)) ?? nil
            
            if skipPaymentMethodTypes == nil && requestDisplayMetadata == nil {
                throw InternalError.failedToDecode(message: "All values are nil", userInfo: nil, diagnosticsId: UUID().uuidString)
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            
            if skipPaymentMethodTypes == nil && requestDisplayMetadata == nil {
                throw InternalError.failedToDecode(message: "All values are nil", userInfo: nil, diagnosticsId: UUID().uuidString)
            }
            
            if let skipPaymentMethodTypes = skipPaymentMethodTypes {
                try container.encode(skipPaymentMethodTypes, forKey: .skipPaymentMethodTypes)
            }
            
            if let requestDisplayMetadata = requestDisplayMetadata {
                try container.encode(requestDisplayMetadata, forKey: .requestDisplayMetadata)
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
                        
            return dict.keys.isEmpty ? nil : dict
        }
    }
}

extension Response.Body {
    
    struct Configuration: Codable, LogReporter {
        
        static var current: PrimerAPIConfiguration? {
            return PrimerAPIConfigurationModule.apiConfiguration
        }
        
        static var paymentMethodConfigs: [PrimerPaymentMethod]? {
            return PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods
        }
        
        var hasSurchargeEnabled: Bool {
            let pmSurcharge = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.paymentMethod?.options?.first(where: { $0["surcharge"] as? Int != nil })
            let cardSurcharge = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.paymentMethod?.options?.first(where: { (($0["networks"] as? [[String: Any]])?.first(where: { $0["surcharge"] as? Int != nil })) != nil  })
            return pmSurcharge != nil || cardSurcharge != nil
        }
        
        static var paymentMethodConfigViewModels: [PaymentMethodTokenizationViewModelProtocol] {
            var viewModels: [PaymentMethodTokenizationViewModelProtocol] = PrimerAPIConfiguration.paymentMethodConfigs?
                .filter({ $0.isEnabled })
                .filter({ $0.baseLogoImage != nil })
                .compactMap({ $0.tokenizationViewModel })
            ?? []
            
            let supportedNetworks = ApplePayUtils.supportedPKCardNetworks()
            var canMakePayment: Bool
            if PrimerSettings.current.paymentMethodOptions.applePayOptions?.checkProvidedNetworks == true {
                canMakePayment = PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks)
            } else {
                canMakePayment = PKPaymentAuthorizationViewController.canMakePayments()
            }

            if !canMakePayment {
                if let applePayViewModel = viewModels.filter({ $0.config.type == PrimerPaymentMethodType.applePay.rawValue }).first,
                   let applePayViewModelIndex = viewModels.firstIndex(where: { $0 == applePayViewModel }) {
                    viewModels.remove(at: applePayViewModelIndex)
                }
            }
            
#if !canImport(PrimerKlarnaSDK)
            if let klarnaViewModelIndex = viewModels.firstIndex(where: { $0.config.type == PrimerPaymentMethodType.klarna.rawValue }) {
                viewModels.remove(at: klarnaViewModelIndex)
                logger.warn(message: "Klarna configuration has been found but module 'PrimerKlarnaSDK' is missing. Add `PrimerKlarnaSDK' in your project by adding \"pod 'PrimerKlarnaSDK'\" in your podfile or by adding \"primer-klarna-sdk-ios\" in your Swift Package Manager, so you can perform payments with Klarna.")
                
                let event = Analytics.Event(
                    eventType: .message,
                    properties: MessageEventProperties(
                        message: "PrimerKlarnaSDK has not been integrated",
                        messageType: .error,
                        severity: .error))
                Analytics.Service.record(events: [event])
            }
#endif
            
#if !canImport(PrimerIPay88MYSDK)
            if let iPay88ViewModelIndex = viewModels.firstIndex(where: { $0.config.type == PrimerPaymentMethodType.iPay88Card.rawValue }) {
                viewModels.remove(at: iPay88ViewModelIndex)
                logger.warn(message: "iPay88 configuration has been found but module 'PrimerIPay88SDK' is missing. Add `PrimerIPay88SDK' in your project by adding \"pod 'PrimerIPay88SDK'\" in your podfile, so you can perform payments with iPay88.")
                
                let event = Analytics.Event(
                    eventType: .message,
                    properties: MessageEventProperties(
                        message: "PrimerIPay88MYSDK has not been integrated",
                        messageType: .error,
                        severity: .error))
                Analytics.Service.record(events: [event])
            }
#endif
            
            var validViewModels: [PaymentMethodTokenizationViewModelProtocol] = []
            
            for viewModel in viewModels {
                do {
                    try viewModel.validate()
                    validViewModels.append(viewModel)
                } catch {
                    var warningStr = "\(viewModel.config.type) configuration has been found, but it cannot be presented."
                    
                    if let primerErr = error as? PrimerError {
                        if case .underlyingErrors(let errors, _, _) = primerErr {
                            for err in errors {
                                if let primerErr = err as? PrimerError {
                                    var errLine: String = ""
                                    if let errDescription = primerErr.plainDescription {
                                        errLine += "\n-\(errDescription)"
                                    }
                                    
                                    if let recoverySuggestion = primerErr.recoverySuggestion {
                                        if errLine.count != 0 {
                                            errLine += " | "
                                        } else {
                                            errLine += "\n-"
                                        }
                                        
                                        errLine += recoverySuggestion
                                    }
                                    warningStr += errLine
                                    
                                } else {
                                    warningStr += "\n-\(error.localizedDescription)"
                                }
                            }
                        } else {
                            var errLine: String = ""
                            if let errDescription = primerErr.plainDescription {
                                errLine += "\n-\(errDescription)"
                            }
                            
                            if let recoverySuggestion = primerErr.recoverySuggestion {
                                if errLine.count != 0 {
                                    errLine += " | "
                                } else {
                                    errLine += "\n-"
                                }
                                
                                errLine += recoverySuggestion
                            }
                            warningStr += errLine
                        }
                        
                    } else {
                        warningStr += "\n-\(error.localizedDescription)"
                    }
                    
                    logger.warn(message: warningStr)
                }
            }
            
            for (index, viewModel) in validViewModels.enumerated() {
                if viewModel.config.type == PrimerPaymentMethodType.applePay.rawValue {
                    validViewModels.swapAt(0, index)
                }
            }
            
            for (index, viewModel) in validViewModels.enumerated() {
                viewModel.position = index
            }
            
            return validViewModels
        }
        
        let coreUrl: String?
        let pciUrl: String?
        var clientSession: ClientSession.APIResponse?
        let paymentMethods: [PrimerPaymentMethod]?
        let primerAccountId: String?
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
            self.primerAccountId = (try? container.decode(String?.self, forKey: .primerAccountId)) ?? nil
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
                        }
                    }
                }
                
                if let paymentMethod = self.paymentMethods?.filter({ $0.type == PrimerPaymentMethodType.paymentCard.rawValue }).first {
                    paymentMethod.hasUnknownSurcharge = true
                    paymentMethod.surcharge = nil
                }
            }
        }
        
        init(
            coreUrl: String?,
            pciUrl: String?,
            clientSession: ClientSession.APIResponse?,
            paymentMethods: [PrimerPaymentMethod]?,
            primerAccountId: String?,
            keys: ThreeDS.Keys?,
            checkoutModules: [PrimerAPIConfiguration.CheckoutModule]?
        ) {
            self.coreUrl = coreUrl
            self.pciUrl = pciUrl
            self.clientSession = clientSession
            self.paymentMethods = paymentMethods
            self.primerAccountId = primerAccountId
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
            
            if let apayaOptions = method.options as? MerchantOptions {
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
                    let err = InternalError.failedToDecode(message: "All fields are nil", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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
                    let err = InternalError.failedToDecode(message: "All fields are nil", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
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



