//
//  PrimerConfiguration.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/12/21.
//

#if canImport(UIKit)

import Foundation
import PassKit

protocol CheckoutModuleOptions: Codable {}

struct PrimerConfiguration: Codable {
    
    static var current: PrimerConfiguration? {
        let appState: AppStateProtocol = DependencyContainer.resolve()
        return appState.primerConfiguration
    }
    
    static var paymentMethodConfigs: [PaymentMethodConfig]? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        let pms = state
            .primerConfiguration?
            .paymentMethods
        
        return pms
    }
    
    static var paymentMethodConfigViewModels: [PaymentMethodTokenizationViewModelProtocol] {
        var viewModels = PrimerConfiguration.paymentMethodConfigs?
            .filter({ $0.type.isEnabled })
            .compactMap({ $0.tokenizationViewModel })
        ?? []
        
        let supportedNetworks = PaymentNetwork.iOSSupportedPKPaymentNetworks
        if !PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks) {
            if let applePayViewModel = viewModels.filter({ $0.config.type == .applePay }).first,
               let applePayViewModelIndex = viewModels.firstIndex(where: { $0 == applePayViewModel }) {
                viewModels.remove(at: applePayViewModelIndex)
            }
        }
        
#if !canImport(PrimerKlarnaSDK)
        if let klarnaViewModelIndex = viewModels.firstIndex(where: { $0.config.type == PrimerPaymentMethodType.klarna }) {
            viewModels.remove(at: klarnaViewModelIndex)
            print("WARNING!\nKlarna configuration has been found but module 'PrimerKlarnaSDK' is missing. Add `PrimerKlarnaSDK' in your project so you can perform payments with Klarna.")
        }
#endif
        
        for (index, viewModel) in viewModels.enumerated() {
            if viewModel.config.type == .applePay {
                viewModels.swapAt(0, index)
            }
        }
        
        for (index, viewModel) in viewModels.enumerated() {
            viewModel.position = index
        }
                
        return viewModels
    }
    
    let coreUrl: String?
    let pciUrl: String?
    let clientSession: ClientSession?
    let paymentMethods: [PaymentMethodConfig]?
    let keys: ThreeDS.Keys?
    let checkoutModules: [CheckoutModule]?
    
    var isSetByClientSession: Bool {
        return clientSession != nil
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.coreUrl = (try? container.decode(String?.self, forKey: .coreUrl)) ?? nil
        self.pciUrl = (try? container.decode(String?.self, forKey: .pciUrl)) ?? nil
        self.clientSession = (try? container.decode(ClientSession?.self, forKey: .clientSession)) ?? nil
        let throwables = try container.decode([Throwable<PaymentMethodConfig>].self, forKey: .paymentMethods)
        self.paymentMethods = throwables.compactMap({ $0.value })
        self.keys = (try? container.decode(ThreeDS.Keys?.self, forKey: .keys)) ?? nil
        let moduleThrowables = try container.decode([Throwable<CheckoutModule>].self, forKey: .checkoutModules)
        self.checkoutModules = moduleThrowables.compactMap({ $0.value })
        
        if let options = clientSession?.paymentMethod?.options, !options.isEmpty {
            for paymentMethodOption in options {
                if let type = paymentMethodOption["type"] as? String {
                    if type == PaymentMethodConfigType.paymentCard.rawValue,
                        let networks = paymentMethodOption["networks"] as? [[String: Any]],
                       !networks.isEmpty
                    {
                        for network in networks {
                            guard network["type"] is String,
                            network["surcharge"] is Int
                            else { continue }
                            
                        }
                    } else if let surcharge = paymentMethodOption["surcharge"] as? Int,
                              let paymentMethod = self.paymentMethods?.filter({ $0.type.rawValue == type }).first
                    {
                        paymentMethod.hasUnknownSurcharge = false
                        paymentMethod.surcharge = surcharge
                    }
                }
            }
        }
        
        if let paymentMethod = self.paymentMethods?.filter({ $0.type == PaymentMethodConfigType.paymentCard }).first {
            paymentMethod.hasUnknownSurcharge = true
            paymentMethod.surcharge = nil
        }
    }
    
    init(
        coreUrl: String?,
        pciUrl: String?,
        clientSession: ClientSession?,
        paymentMethods: [PaymentMethodConfig]?,
        keys: ThreeDS.Keys?,
        checkoutModules: [PrimerConfiguration.CheckoutModule]?
    ) {
        self.coreUrl = coreUrl
        self.pciUrl = pciUrl
        self.clientSession = clientSession
        self.paymentMethods = paymentMethods
        self.keys = keys
        self.checkoutModules = checkoutModules
    }
    
    func getConfigId(for type: PaymentMethodConfigType) -> String? {
        guard let method = self.paymentMethods?.filter({ $0.type == type }).first else { return nil }
        return method.id
    }
    
    func getProductId(for type: PaymentMethodConfigType) -> String? {
        guard let method = self.paymentMethods?
                .first(where: { method in return method.type == type }) else { return nil }
        
        if let apayaOptions = method.options as? ApayaOptions {
            return apayaOptions.merchantAccountId
        } else {
            return nil
        }
    }
}

extension PrimerConfiguration {
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
                    let err = ParserError.failedToDecode(message: "All fields are nil", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
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
                    let err = ParserError.failedToDecode(message: "All fields are nil", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
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

