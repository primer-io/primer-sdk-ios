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
    var imageFiles: PrimerTheme.BaseImageFiles?
    
    var hasUnknownSurcharge: Bool = false
    var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol? {
        if implementationType == .webRedirect {
            return ExternalPaymentMethodTokenizationViewModel(config: self)
            
        } else {
            switch self.type {
            case PrimerPaymentMethodType.adyenBlik.rawValue:
                return FormPaymentMethodTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.adyenDotPay.rawValue,
                PrimerPaymentMethodType.adyenIDeal.rawValue:
                return BankSelectorTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.apaya.rawValue:
                return ApayaTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.applePay.rawValue:
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
    
    var isCheckoutEnabled: Bool {
        if self.imageFiles?.colored.image == nil {
            return false
        }
        
        switch self.type {
        case PrimerPaymentMethodType.apaya.rawValue,
            PrimerPaymentMethodType.goCardless.rawValue,
            PrimerPaymentMethodType.googlePay.rawValue:
            return false
        default:
            return true
        }
    }
    
    var isVaultingEnabled: Bool {
        if self.imageFiles?.colored.image == nil {
            return false
        }
        
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
    }
    
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

extension PrimerPaymentMethod {
    
    public enum ImplementationType: String, Codable, CaseIterable, Equatable, Hashable {
        
        case nativeSdk = "NATIVE_SDK"
        case webRedirect = "WEB_REDIRECT"

        var isEnabled: Bool {
            return true
        }
    }
}

extension PrimerTheme {
    
    class BaseImageFiles {
        
        var colored: ImageFile
        var light: ImageFile?
        var dark: ImageFile?
        
        init(colored: ImageFile, light: ImageFile?, dark: ImageFile?) {
            self.colored = colored
            self.light = light
            self.dark = dark
        }
    }
    
    public class BaseColoredURLs: Codable {
        
        var colored: String
        var dark: String?
        var light: String?
    }
    
    public class BaseColors: Codable {
        
        var colored: String
        var dark: String?
        var light: String?
    }
}

extension PrimerPaymentMethod {
    
    class Data: Codable {
        
        var button: PrimerPaymentMethod.Data.Button
        
        class Button: Codable {
            
            var iconUrl: PrimerTheme.BaseColoredURLs
            var backgroundColor: PrimerTheme.BaseColors?
            var cornerRadius: Int?
            var borderWidth: Int?
            var borderColor: PrimerTheme.BaseColors?
            var text: String?
            var textColor: PrimerTheme.BaseColors?
            
            private enum CodingKeys : String, CodingKey {
                case iconUrl,
                     backgroundColor,
                     cornerRadius,
                     borderWidth,
                     borderColor,
                     text,
                     textColor
            }
        }
    }
}

#endif

