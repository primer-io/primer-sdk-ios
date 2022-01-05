//
//  PrimerConfiguration.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/12/21.
//

#if canImport(UIKit)

import Foundation

protocol CheckoutModuleOptions: Codable {}

struct PrimerConfiguration: Codable {
    
    static var paymentMethodConfigs: [PaymentMethodConfig]? {
        if Primer.shared.flow == nil { return nil }
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state
            .primerConfiguration?
            .paymentMethods
    }
    
    static var paymentMethodConfigViewModels: [PaymentMethodTokenizationViewModelProtocol] {
        var viewModels = PrimerConfiguration.paymentMethodConfigs?
            .filter({ $0.type.isEnabled })
            .compactMap({ $0.tokenizationViewModel })
        ?? []
        
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
    
    var requirePostalCode: Bool {
        let billingAddressModule = checkoutModules?.first { $0.type == "BILLING_ADDRESS" }
        return (billingAddressModule?.options as? PrimerConfiguration.CheckoutModule.PostalCodeOptions)?.postalCode ?? false
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
                            guard let type = network["type"] as? String,
                            let surcharge = network["surcharge"] as? Int
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
        }
        
        struct PostalCodeOptions: CheckoutModuleOptions {
            let postalCode: Bool
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.type = try container.decode(String.self, forKey: .type)
            self.requestUrlStr = (try? container.decode(String?.self, forKey: .requestUrlStr)) ?? nil
            
            if let options = (try? container.decode(CardInformationOptions?.self, forKey: .options)) {
                self.options = options
            } else if let options = (try? container.decode(PostalCodeOptions?.self, forKey: .options)) {
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

