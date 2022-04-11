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
            
            if let apayaOptions = (try? container.decode(PaymentMethod.Apaya.Configuration.Options?.self, forKey: .options)) {
                self.options = apayaOptions
            } else if let applePayOptions = (try? container.decode(PaymentMethod.ApplePay.Configuration.Options?.self, forKey: .options)) {
                self.options = applePayOptions
            } else if let blikPaymentMethodOptions = (try? container.decode(PaymentMethod.Blik.Configuration.Options?.self, forKey: .options)) {
                self.options = blikPaymentMethodOptions
            } else if let googlePayOptions = (try? container.decode(PaymentMethod.GooglePay.Configuration.Options?.self, forKey: .options)) {
                self.options = googlePayOptions
            } else if let primerTestEComOptions = (try? container.decode(PaymentMethod.PrimerTestECom.Configuration.Options?.self, forKey: .options)) {
                self.options = primerTestEComOptions
            } else if let paymentCardOptions = (try? container.decode(PaymentMethod.PaymentCard.Configuration.Options?.self, forKey: .options)) {
                self.options = paymentCardOptions
            } else if let payPalOptions = (try? container.decode(PaymentMethod.PayPal.Configuration.Options?.self, forKey: .options)) {
                self.options = payPalOptions
            } else if let redirectPaymentMethodOptions = (try? container.decode(PaymentMethod.Redirect.Configuration.Options?.self, forKey: .options)) {
                self.options = redirectPaymentMethodOptions
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
            
            if let apayaOptions = self.options as? PaymentMethod.Apaya.Configuration.Options {
                try? container.encode(apayaOptions, forKey: .options)
            } else if let applePayOptions = self.options as? PaymentMethod.ApplePay.Configuration.Options {
                try? container.encode(applePayOptions, forKey: .options)
            } else if let blikPaymentMethodOptions = self.options as? PaymentMethod.Blik.Configuration.Options {
                try? container.encode(blikPaymentMethodOptions, forKey: .options)
            } else if let googlePayOptions = self.options as? PaymentMethod.GooglePay.Configuration.Options {
                try? container.encode(googlePayOptions, forKey: .options)
            } else if let primerTestEComOptions = self.options as? PaymentMethod.PrimerTestECom.Configuration.Options {
                try? container.encode(primerTestEComOptions, forKey: .options)
            } else if let paymentCardOptions = self.options as? PaymentMethod.PaymentCard.Configuration.Options {
                try? container.encode(paymentCardOptions, forKey: .options)
            } else if let payPalOptions = self.options as? PaymentMethod.PayPal.Configuration.Options {
                try? container.encode(payPalOptions, forKey: .options)
            } else if let redirectPaymentMethodOptions = self.options as? PaymentMethod.Redirect.Configuration.Options {
                try? container.encode(redirectPaymentMethodOptions, forKey: .options)
            } else {
                fatalError()
            }
        }

    }
}
