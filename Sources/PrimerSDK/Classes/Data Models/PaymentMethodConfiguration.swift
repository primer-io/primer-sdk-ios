//
//  PaymentMethodConfiguration.swift
//  PrimerSDK
//
//  Created by Evangelos on 28/12/21.
//

#if canImport(UIKit)

import Foundation

class PrimerPaymentMethod: Codable {
    
    static func getPaymentMethod(withType type: String) -> PrimerPaymentMethod? {
        return AppState.current.apiConfiguration?.paymentMethods?.filter({ $0.type == type }).first
    }
    
    static func getBundledImageFileName(for paymentMethodType: String, assetType: PrimerAsset.ImageType) -> String? {
        var tmpPaymentMethodFileNameFirstComponent: String?
        
        guard let supportedPaymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodType) else { return nil }
        
        if supportedPaymentMethodType == .xfersPayNow {
            tmpPaymentMethodFileNameFirstComponent = supportedPaymentMethodType.provider
        } else if supportedPaymentMethodType.provider == paymentMethodType {
            tmpPaymentMethodFileNameFirstComponent = paymentMethodType
        } else if paymentMethodType.starts(with: "\(supportedPaymentMethodType.provider)_") {
            tmpPaymentMethodFileNameFirstComponent = paymentMethodType.replacingOccurrences(of: "\(supportedPaymentMethodType.provider)_", with: "")
        } else {
            return nil
        }
        
        tmpPaymentMethodFileNameFirstComponent = tmpPaymentMethodFileNameFirstComponent!.lowercased().replacingOccurrences(of: "_", with: "-")
        
        switch assetType {
        case .logo:
            return "\(tmpPaymentMethodFileNameFirstComponent!)-logo-colored"
        case .icon:
            return "\(tmpPaymentMethodFileNameFirstComponent!)-icon-colored"
        }
    }
    
    let id: String? // Will be nil for cards
    let implementationType: PrimerPaymentMethod.ImplementationType
    let type: String
    var name: String?
    let processorConfigId: String?
    var surcharge: Int?
    let options: PaymentMethodOptions?
    var data: PrimerPaymentMethod.Data?
    
    var hasUnknownSurcharge: Bool = false
    var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol? {
        if implementationType == .webRedirect {
            return ExternalPaymentMethodTokenizationViewModel(config: self)
            
        } else {
            switch self.type {
            case "ADYEN_DOTPAY",
                "ADYEN_IDEAL":
                return BankSelectorTokenizationViewModel(config: self)
                
            case "ADYEN_BLIK":
                return FormPaymentMethodTokenizationViewModel(config: self)
                
            case "APAYA":
                return ApayaTokenizationViewModel(config: self)
                
            case "APPLE_PAY":
                if #available(iOS 11.0, *) {
                    return ApplePayTokenizationViewModel(config: self)
                }
                
            case PrimerPaymentMethodType.klarna.rawValue:
                return KlarnaTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.paymentCard.rawValue:
                return CardFormPaymentMethodTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.payPal.rawValue:
                return PayPalTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.xfersPayNow.rawValue:
                return QRCodeTokenizationViewModel(config: self)
                
            default:
                break
            }
        }
        
        log(logLevel: .info, title: "UNHANDLED PAYMENT METHOD TYPE", message: type, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: #function, line: nil)
        
        return nil
    }
    
    lazy var imageName: String? = {
        switch self.type {
        case "ADYEN_ALIPAY":
            return "alipay"
            
        case "ADYEN_BLIK":
            return "blik"
            
        case "ADYEN_DOTPAY":
            return "dot-pay"
            
        case "ADYEN_GIROPAY",
            "BUCKAROO_GIROPAY",
            "PAY_NL_GIROPAY":
            return "giropay"
            
        case "ADYEN_IDEAL",
            "BUCKAROO_IDEAL",
            "MOLLIE_IDEAL",
            "PAY_NL_IDEAL":
            return "ideal"
            
        case "ADYEN_INTERAC":
            return "interac"
            
        case "ADYEN_MOBILEPAY":
            return "mobile-pay"
            
        case "ADYEN_PAYSHOP":
            return "payshop"
            
        case "ADYEN_PAYTRAIL":
            return "paytrail"
            
        case "ADYEN_SOFORT",
            "BUCKAROO_SOFORT",
            "PRIMER_TEST_SOFORT":
            return "sofort"
            
        case "ADYEN_TRUSTLY":
            return "trustly"
            
        case "ADYEN_TWINT":
            return "twint"
            
        case "ADYEN_VIPPS":
            return "vipps"
            
        case "APAYA":
            return "apaya"
            
        case "APPLE_PAY":
            return "apple-pay"
            
        case "ATOME":
            return "atome"
            
        case "BUCKAROO_BANCONTACT",
            "MOLLIE_BANCONTACT",
            "PAY_NL_BANCONTACT":
            return "bancontact"
            
        case "BUCKAROO_EPS":
            return "eps"
            
        case "COINBASE":
            return "coinbase"
            
        case "GOCARDLESS":
            return "go-cardless"
            
        case "GOOGLE_PAY":
            return "google-pay"
            
        case "HOOLAH":
            return "hoolah"
            
        case "KLARNA",
            "PRIMER_TEST_KLARNA":
            return "klarna"
            
        case "OPENNODE":
            return "opennode"
            
        case "PAY_NL_PAYCONIQ":
            return "payconiq"
            
        case "PAYMENT_CARD":
            return "card"
            
        case "PAYPAL",
            "PRIMER_TEST_PAYPAL":
            return "paypal"
            
        case "RAPYD_GCASH":
            return "gcash"
            
        case "RAPYD_GRABPAY":
            return "grab-pay"
            
        case "RAPYD_POLI":
            return "poli"
            
        case "TWOC2P":
            return "2c2p"
            
        case "XFERS_PAYNOW":
            return "xfers"
            
        default:
            return nil
        }
    }()
    
    lazy var isCheckoutEnabled: Bool = {
        switch self.type {
        case PrimerPaymentMethodType.apaya.rawValue,
            PrimerPaymentMethodType.goCardless.rawValue,
            PrimerPaymentMethodType.googlePay.rawValue:
            return false
        default:
            return true
        }
    }()
    
    lazy var isVaultingEnabled: Bool = {
        if self.implementationType == .webRedirect {
            return false
        }
        
        switch self.type {
        case PrimerPaymentMethodType.applePay.rawValue,
            PrimerPaymentMethodType.goCardless.rawValue,
            PrimerPaymentMethodType.googlePay.rawValue:
            return false
        default:
            return true
        }
    }()
    
    lazy var isEnabled: Bool = {
        switch Primer.shared.intent {
        case .checkout:
            return self.isCheckoutEnabled
        case .vault:
            return self.isVaultingEnabled
        case .none:
            precondition(true, "Should never get in here")
            return false
        }
    }()
    
    private enum CodingKeys : String, CodingKey {
        case id,
             implementationType,
             type,
             name,
             processorConfigId,
             surcharge,
             options,
             data
    }
    
    init(
        id: String?,
        implementationType: PrimerPaymentMethod.ImplementationType,
        type: String,
        name: String?,
        processorConfigId: String?,
        surcharge: Int?,
        options: PaymentMethodOptions?,
        data: PrimerPaymentMethod.Data?
    ) {
        self.id = id
        self.implementationType = implementationType
        self.type = type
        self.name = name
        self.processorConfigId = processorConfigId
        self.surcharge = surcharge
        self.options = options
        self.data = data
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = (try? container.decode(String?.self, forKey: .id)) ?? nil
        implementationType = try container.decode(PrimerPaymentMethod.ImplementationType.self, forKey: .implementationType)
        type = try container.decode(String.self, forKey: .type)
        name = (try? container.decode(String?.self, forKey: .name)) ?? nil
        processorConfigId = (try? container.decode(String?.self, forKey: .processorConfigId)) ?? nil
        surcharge = (try? container.decode(Int?.self, forKey: .surcharge)) ?? nil
        data = (try? container.decode(PrimerPaymentMethod.Data?.self, forKey: .data)) ?? nil
        
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
        try container.encode(implementationType, forKey: .implementationType)
        try container.encode(type, forKey: .type)
        try container.encode(name, forKey: .name)
        try container.encode(processorConfigId, forKey: .processorConfigId)
        try container.encode(surcharge, forKey: .surcharge)
        try container.encode(data, forKey: .data)
        
        if let cardOptions = options as? CardOptions {
            try container.encode(cardOptions, forKey: .options)
        } else if let payPalOptions = options as? PayPalOptions {
            try container.encode(payPalOptions, forKey: .options)
        } else if let apayaOptions = options as? ApayaOptions {
            try container.encode(apayaOptions, forKey: .options)
        }
    }
    
}

#endif

