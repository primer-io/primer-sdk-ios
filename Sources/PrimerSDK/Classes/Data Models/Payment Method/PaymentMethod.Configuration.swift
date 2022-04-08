//
//  PaymentMethodConfiguration.swift
//  PrimerSDK
//
//  Created by Evangelos on 7/4/22.
//

import Foundation

protocol PaymentMethodConfigurationOptions: Codable {}

extension PaymentMethod {
    struct Configuration: Codable {
        let id: String? // Will be nil for cards
        let processorConfigId: String?
        let type: PaymentMethod.PaymentMethodType
        let options: PaymentMethodConfigurationOptions?
        var surcharge: Int?
        var hasUnknownSurcharge: Bool = false
        var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol? {
            let asyncPaymentMethodTypes: [PaymentMethod.PaymentMethodType] = [
                .adyenMobilePay,
                .adyenVipps,
                .adyenAlipay,
                .adyenGiropay,
                .atome,
                .buckarooBancontact,
                .buckarooEps,
                .buckarooGiropay,
                .buckarooIdeal,
                .buckarooSofort,
                .mollieBankcontact,
                .mollieIdeal,
                .payNLBancontact,
                .payNLGiropay,
                .payNLPayconiq,
                .adyenSofort,
                .adyenTrustly,
                .adyenTwint
            ]
            
            if type == .paymentCard {
                return CardFormPaymentMethodTokenizationViewModel(config: self)
            } else if type == .applePay {
                if #available(iOS 11.0, *) {
                    return ApplePayTokenizationViewModel(config: self)
                }
            } else if type == .klarna {
                return KlarnaTokenizationViewModel(config: self)
            } else if type == .hoolah || type == .payNLIdeal {
                return ExternalPaymentMethodTokenizationViewModel(config: self)
            } else if type == .payPal {
                return PayPalTokenizationViewModel(config: self)
            } else if type == .apaya {
                return ApayaTokenizationViewModel(config: self)
            } else if asyncPaymentMethodTypes.contains(type) {
                return ExternalPaymentMethodTokenizationViewModel(config: self)
            } else if type == .adyenDotPay || type == .adyenIDeal {
                return BankSelectorTokenizationViewModel(config: self)
            } else if type == .adyenBlik {
                return FormPaymentMethodTokenizationViewModel(config: self)
            } else if type == .xfers {
                return QRCodeTokenizationViewModel(config: self)
            }
            
            log(logLevel: .info, title: "UNHANDLED PAYMENT METHOD TYPE", message: type.rawValue, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: #function, line: nil)

            return nil
        }
        
        private enum CodingKeys: String, CodingKey {
            case id, processorConfigId, type, options, surcharge, hasUnknownSurcharge
        }
        
        init(id: String?, options: PaymentMethodConfigurationOptions?, processorConfigId: String?, type: PaymentMethod.PaymentMethodType) {
            self.id = id
            self.options = options
            self.processorConfigId = processorConfigId
            self.type = type
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.id = (try? container.decode(String?.self, forKey: .id)) ?? nil
            self.processorConfigId = (try? container.decode(String?.self, forKey: .processorConfigId)) ?? nil
            self.type = try container.decode(PaymentMethod.PaymentMethodType.self, forKey: .type)
            self.surcharge = (try? container.decode(Int?.self, forKey: .surcharge)) ?? nil
            
            if let applePayOptions = (try? container.decode(ApplePayOptions?.self, forKey: .options)) {
                self.options = applePayOptions
            } else {
                fatalError()
            }
        }
        
        func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(self.id, forKey: .id)
            try? container.encode(self.processorConfigId, forKey: .processorConfigId)
            try? container.encode(self.type, forKey: .type)
            try? container.encode(self.surcharge, forKey: .surcharge)
            
            if let applePayOptions = self.options as? ApplePayOptions {
                try? container.encode(applePayOptions, forKey: .options)
            } else {
                fatalError()
            }
        }

    }
}

extension PaymentMethod.Configuration {
    struct ApayaOptions: PaymentMethodConfigurationOptions {
        let merchantAccountId: String
    }
    
    struct ApplePayOptions: PaymentMethodConfigurationOptions {
        let test: String
    }
    
    struct CardOptions: PaymentMethodConfigurationOptions {
        let threeDSecureEnabled: Bool
        let threeDSecureToken: String?
        let threeDSecureInitUrl: String?
        let threeDSecureProvider: String
        let processorConfigId: String?
    }
    
    struct PayPalOptions: PaymentMethodConfigurationOptions {
        let clientId: String
    }
    
    struct RedirectPaymentMethodOptions: PaymentMethodConfigurationOptions {
        let paymentMethodConfigId: String
        let paymentMethodType: PaymentMethod.PaymentMethodType
        let sessionInfo: SessionInfo
        lazy var type: String = {
            "OFF_SESSION_PAYMENT"
        }()
        
        struct SessionInfo: Codable {
            var locale: String
            var platform: String = "IOS"
            var redirectionUrl: String? = PrimerSettings.current.urlScheme
        }
        
    }
    
    struct BlikPaymentMethodOptions: PaymentMethodConfigurationOptions {
        let paymentMethodConfigId: String
        let paymentMethodType: PaymentMethod.PaymentMethodType
        let sessionInfo: SessionInfo
        lazy var type: String = {
            "OFF_SESSION_PAYMENT"
        }()
    }
    
    struct SessionInfo: Codable {
        let blikCode: String
        let locale: String
        lazy var platform: String = {
            "IOS"
        }()
        lazy var redirectionUrl: String? = {
            PrimerSettings.current.urlScheme
        }()
    }
}
