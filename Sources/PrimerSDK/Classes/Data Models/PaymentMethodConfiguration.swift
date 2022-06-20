//
//  PaymentMethodConfiguration.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/12/21.
//

#if canImport(UIKit)

import Foundation

class PaymentMethodConfig: Codable {
    
    let id: String? // Will be nil for cards
    let processorConfigId: String?
    let type: PrimerPaymentMethodType
    let options: PaymentMethodOptions?
    var surcharge: Int?
    var hasUnknownSurcharge: Bool = false
    var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol? {
        
        let asyncPaymentMethodTypes: [PrimerPaymentMethodType] = [
            .adyenMobilePay,
            .adyenVipps,
            .adyenAlipay,
            .adyenGiropay,
            .adyenInterac,
            .adyenPayTrail,
            .adyenSofort,
            .adyenTrustly,
            .adyenTwint,
            .atome,
            .buckarooBancontact,
            .buckarooEps,
            .buckarooGiropay,
            .buckarooIdeal,
            .buckarooSofort,
            .coinbase,
            .mollieBankcontact,
            .mollieIdeal,
            .payNLBancontact,
            .payNLGiropay,
            .payNLPayconiq,
            .opennode,
            .twoCtwoP,
            .adyenPayshop
        ]
        
        let testPaymentMethodTypes: [PrimerPaymentMethodType] = [
            .primerTestPayPal,
            .primerTestKlarna,
            .primerTestSofort
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
        } else if testPaymentMethodTypes.contains(type) {
            return PrimerTestPaymentMethodTokenizationViewModel(config: self)
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
    
    private enum CodingKeys : String, CodingKey {
        case id, options, processorConfigId, type
    }
    
    init(id: String?, options: PaymentMethodOptions?, processorConfigId: String?, type: PrimerPaymentMethodType) {
        self.id = id
        self.options = options
        self.processorConfigId = processorConfigId
        self.type = type
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        type = try container.decode(PrimerPaymentMethodType.self, forKey: .type)
        id = (try? container.decode(String?.self, forKey: .id)) ?? nil
        processorConfigId = (try? container.decode(String?.self, forKey: .processorConfigId)) ?? nil
        
        if let cardOptions = try? container.decode(CardOptions.self, forKey: .options) {
            options = cardOptions
        } else if let payPalOptions = try? container.decode(PayPalOptions.self, forKey: .options) {
            options = payPalOptions
        } else if let apayaOptions = try? container.decode(ApayaOptions.self, forKey: .options) {
            options = apayaOptions
        } else {
            options = nil
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(processorConfigId, forKey: .processorConfigId)
        try container.encode(type, forKey: .type)
        
        if let cardOptions = options as? CardOptions {
            try container.encode(cardOptions, forKey: .options)
        } else if let payPalOptions = options as? PayPalOptions {
            try container.encode(payPalOptions, forKey: .options)
        }
    }
    
}

#endif

