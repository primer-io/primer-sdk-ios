//
//  PrimerPaymentMethod.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//



import Foundation
import UIKit

extension PrimerTheme {
    enum Mode: String {
        case colored, dark, light
    }
}

class PrimerPaymentMethod: Codable {
    
    static func getPaymentMethod(withType type: String) -> PrimerPaymentMethod? {
        return PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.filter({ $0.type == type }).first
    }
    
    let id: String? // Will be nil for cards
    let implementationType: PrimerPaymentMethod.ImplementationType
    let type: String
    var name: String
    let processorConfigId: String?
    var surcharge: Int?
    let options: PaymentMethodOptions?
    var displayMetadata: PrimerPaymentMethod.DisplayMetadata?
    var baseLogoImage: PrimerTheme.BaseImage?
    
    lazy var internalPaymentMethodType: PrimerPaymentMethodType? = {
        return PrimerPaymentMethodType(rawValue: self.type)
    }()
    
    var logo: UIImage? {
        guard let baseLogoImage = baseLogoImage else { return nil }
        
        if UIScreen.isDarkModeEnabled {
            if let darkImage = baseLogoImage.dark {
                return darkImage
            } else if let coloredImage = baseLogoImage.colored {
                return coloredImage
            } else if let lightImage = baseLogoImage.light {
                return lightImage
            } else {
                return nil
            }
        } else {
            if let coloredImage = baseLogoImage.colored {
                return coloredImage
            } else if let lightImage = baseLogoImage.light {
                return lightImage
            } else if let darkImage = baseLogoImage.dark {
                return darkImage
            } else {
                return nil
            }
        }
    }
    
    var invertedLogo: UIImage? {
        guard let baseLogoImage = baseLogoImage else { return nil }
        
        if UIScreen.isDarkModeEnabled {
            if let lightImage = baseLogoImage.light {
                return lightImage
            } else if let coloredImage = baseLogoImage.colored {
                return coloredImage
            } else {
                return nil
            }
        } else {
            if let darkImage = baseLogoImage.dark {
                return darkImage
            } else if let coloredImage = baseLogoImage.colored {
                return coloredImage
            } else {
                return nil
            }
        }
    }
    
    var hasUnknownSurcharge: Bool = false
    lazy var tokenizationViewModel: PaymentMethodTokenizationViewModelProtocol? = {
        if implementationType == .webRedirect {
            return WebRedirectPaymentMethodTokenizationViewModel(config: self)
            
        } else if implementationType == .iPay88Sdk {
            return IPay88TokenizationViewModel(config: self)
            
        } else if let internalPaymentMethodType = internalPaymentMethodType {
            switch internalPaymentMethodType {
            case PrimerPaymentMethodType.adyenBlik,
                PrimerPaymentMethodType.rapydFast,
                PrimerPaymentMethodType.adyenMBWay,
                PrimerPaymentMethodType.adyenMultibanco:
                return FormPaymentMethodTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.adyenDotPay,
                PrimerPaymentMethodType.adyenIDeal:
                return BankSelectorTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.apaya:
                return ApayaTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.applePay:
                if #available(iOS 11.0, *) {
                    return ApplePayTokenizationViewModel(config: self)
                }
                
            case PrimerPaymentMethodType.klarna:
                return KlarnaTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.paymentCard,
                PrimerPaymentMethodType.adyenBancontactCard:
                return CardFormPaymentMethodTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.payPal:
                return PayPalTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.primerTestKlarna,
                PrimerPaymentMethodType.primerTestPayPal,
                PrimerPaymentMethodType.primerTestSofort:
                return PrimerTestPaymentMethodTokenizationViewModel(config: self)
                
            case PrimerPaymentMethodType.xfersPayNow,
                PrimerPaymentMethodType.rapydPromptPay,
                PrimerPaymentMethodType.omisePromptPay:
                return QRCodeTokenizationViewModel(config: self)
            case PrimerPaymentMethodType.nolPay:
                return NolPayTokenizationViewModel(config: self)
                
            default:
                break
            }
        }
        
        log(logLevel: .info, title: "UNHANDLED PAYMENT METHOD TYPE", message: type, prefix: nil, suffix: nil, bundle: nil, file: nil, className: nil, function: #function, line: nil)
        
        return nil
    }()
    
    var isCheckoutEnabled: Bool {
        if self.baseLogoImage == nil {
            return false
        }
        
        guard let internalPaymentMethodType = internalPaymentMethodType else {
            return true
        }

        switch internalPaymentMethodType {
        case PrimerPaymentMethodType.apaya,
            PrimerPaymentMethodType.goCardless,
            PrimerPaymentMethodType.googlePay:
            return false
        default:
            return true
        }
    }
    
    var isVaultingEnabled: Bool {
        if self.baseLogoImage == nil {
            return false
        }
        
        if self.implementationType == .webRedirect || self.implementationType == .iPay88Sdk {
            return false
        }
        
        switch self.type {
        case PrimerPaymentMethodType.applePay.rawValue,
            PrimerPaymentMethodType.goCardless.rawValue,
            PrimerPaymentMethodType.googlePay.rawValue,
            PrimerPaymentMethodType.iPay88Card.rawValue,
            PrimerPaymentMethodType.nolPay.rawValue:
            return false
        default:
            return true
        }
    }
    
    lazy var isEnabled: Bool = {
        if !implementationType.isEnabled { return false }
        
        switch PrimerInternal.shared.intent {
        case .checkout:
            return self.isCheckoutEnabled
        case .vault:
            return self.isVaultingEnabled
        case .none:
            precondition(true, "Should never get in here")
            return false
        }
    }()
    
    lazy var paymentMethodManagerCategories: [PrimerPaymentMethodManagerCategory]? = {
        var categories: [PrimerPaymentMethodManagerCategory] = []
        
        if implementationType == .webRedirect || implementationType == .iPay88Sdk {
            categories.append(PrimerPaymentMethodManagerCategory.nativeUI)
            return categories
        }
        
        guard let internalPaymentMethodType = self.internalPaymentMethodType else {
            return nil
        }
        
        switch internalPaymentMethodType {
        case .adyenBancontactCard:
            categories.append(PrimerPaymentMethodManagerCategory.cardComponents)
            categories.append(PrimerPaymentMethodManagerCategory.rawData)
            
        case .adyenMBWay:
            categories.append(PrimerPaymentMethodManagerCategory.rawData)
            
        case .applePay:
            categories.append(PrimerPaymentMethodManagerCategory.nativeUI)
            
        case .klarna:
            categories.append(PrimerPaymentMethodManagerCategory.nativeUI)
            
        case .paymentCard:
            categories.append(PrimerPaymentMethodManagerCategory.cardComponents)
            categories.append(PrimerPaymentMethodManagerCategory.rawData)
            
        case .payPal:
            categories.append(PrimerPaymentMethodManagerCategory.nativeUI)
            
        case .xenditOvo:
            categories.append(PrimerPaymentMethodManagerCategory.rawData)
            
        case .xenditRetailOutlets:
            categories.append(PrimerPaymentMethodManagerCategory.rawData)

        case .nolPay:
            categories.append(PrimerPaymentMethodManagerCategory.nolPay)
        default:
            break
        }
        
        return categories.isEmpty ? nil : categories
    }()
    
    private enum CodingKeys : String, CodingKey {
        case id,
             implementationType,
             type,
             name,
             processorConfigId,
             surcharge,
             options,
             displayMetadata
    }
    
    init(
        id: String?,
        implementationType: PrimerPaymentMethod.ImplementationType,
        type: String,
        name: String,
        processorConfigId: String?,
        surcharge: Int?,
        options: PaymentMethodOptions?,
        displayMetadata: PrimerPaymentMethod.DisplayMetadata?
    ) {
        self.id = id
        self.implementationType = implementationType
        self.type = type
        self.name = name
        self.processorConfigId = processorConfigId
        self.surcharge = surcharge
        self.options = options
        self.displayMetadata = displayMetadata
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        id = (try? container.decode(String?.self, forKey: .id)) ?? nil
        implementationType = try container.decode(PrimerPaymentMethod.ImplementationType.self, forKey: .implementationType)
        type = try container.decode(String.self, forKey: .type)
        name = try container.decode(String.self, forKey: .name)
        processorConfigId = (try? container.decode(String?.self, forKey: .processorConfigId)) ?? nil
        surcharge = (try? container.decode(Int?.self, forKey: .surcharge)) ?? nil
        displayMetadata = (try? container.decode(PrimerPaymentMethod.DisplayMetadata?.self, forKey: .displayMetadata)) ?? nil
        
        if let cardOptions = try? container.decode(CardOptions.self, forKey: .options) {
            options = cardOptions
        } else if let payPalOptions = try? container.decode(PayPalOptions.self, forKey: .options) {
            options = payPalOptions
        } else if let merchantOptions = try? container.decode(MerchantOptions.self, forKey: .options) {
            options = merchantOptions
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
        try container.encode(displayMetadata, forKey: .displayMetadata)
        
        if let options = options as? CardOptions {
            try container.encode(options, forKey: .options)
        } else if let options = options as? PayPalOptions {
            try container.encode(options, forKey: .options)
        } else if let options = options as? MerchantOptions {
            try container.encode(options, forKey: .options)
        }
    }
}

extension PrimerPaymentMethod {
    
    public enum ImplementationType: String, Codable, CaseIterable, Equatable, Hashable {
        
        case nativeSdk      = "NATIVE_SDK"
        case webRedirect    = "WEB_REDIRECT"
        case iPay88Sdk      = "IPAY88_SDK"
        
        var isEnabled: Bool {
            return true
        }
    }
}

extension PrimerPaymentMethod {
    
    class DisplayMetadata: Codable {
        
        var button: PrimerPaymentMethod.DisplayMetadata.Button
        
        init(button: PrimerPaymentMethod.DisplayMetadata.Button) {
            self.button = button
        }
        
        class Button: Codable {
            
            var iconUrl: PrimerTheme.BaseColoredURLs?
            var backgroundColor: PrimerTheme.BaseColors?
            var cornerRadius: Int?
            var borderWidth: PrimerTheme.BaseBorderWidth?
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
            
            init(
                iconUrl: PrimerTheme.BaseColoredURLs?,
                backgroundColor: PrimerTheme.BaseColors?,
                cornerRadius: Int?,
                borderWidth: PrimerTheme.BaseBorderWidth?,
                borderColor: PrimerTheme.BaseColors?,
                text: String?,
                textColor: PrimerTheme.BaseColors?
            ) {
                self.iconUrl = iconUrl
                self.backgroundColor = backgroundColor
                self.cornerRadius = cornerRadius
                self.borderWidth = borderWidth
                self.borderColor = borderColor
                self.text = text
                self.textColor = textColor
            }
            
            required init(from decoder: Decoder) throws {
                let container = try decoder.container(keyedBy: CodingKeys.self)
                
                iconUrl = (try? container.decode(PrimerTheme.BaseColoredURLs?.self, forKey: .iconUrl)) ?? nil
                backgroundColor = (try? container.decode(PrimerTheme.BaseColors?.self, forKey: .backgroundColor)) ?? nil
                cornerRadius = (try? container.decode(Int?.self, forKey: .cornerRadius)) ?? nil
                borderWidth = (try? container.decode(PrimerTheme.BaseBorderWidth?.self, forKey: .borderWidth)) ?? nil
                borderColor = (try? container.decode(PrimerTheme.BaseColors?.self, forKey: .borderColor)) ?? nil
                text = (try? container.decode(String?.self, forKey: .text)) ?? nil
                textColor = (try? container.decode(PrimerTheme.BaseColors?.self, forKey: .textColor)) ?? nil
                
                if iconUrl == nil,
                   backgroundColor == nil,
                   cornerRadius == nil,
                   borderWidth == nil,
                   borderColor == nil,
                   text == nil,
                   textColor == nil
                {
                    let err = InternalError.failedToDecode(message: "BaseColors", userInfo: nil, diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: err)
                    throw err
                }
            }
        }
    }
}

extension PrimerTheme {
    
    class BaseImage {
        
        var colored: UIImage?
        var light: UIImage?
        var dark: UIImage?
        
        init?(colored: UIImage?, light: UIImage?, dark: UIImage?) {
            self.colored = colored
            self.light = light
            self.dark = dark
            
            if self.colored == nil, self.light == nil, self.dark == nil {
                return nil
            }
        }
    }
    
    public class BaseColoredURLs: Codable {
        
        var coloredUrlStr: String?
        var darkUrlStr: String?
        var lightUrlStr: String?
        
        private enum CodingKeys: String, CodingKey {
            case coloredUrlStr = "colored"
            case darkUrlStr = "dark"
            case lightUrlStr = "light"
        }
        
        init?(
            coloredUrlStr: String?,
            lightUrlStr: String?,
            darkUrlStr: String?
        ) {
            self.coloredUrlStr = coloredUrlStr
            self.lightUrlStr = lightUrlStr
            self.darkUrlStr = darkUrlStr
        }
        
        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            coloredUrlStr = (try? container.decode(String?.self, forKey: .coloredUrlStr)) ?? nil
            lightUrlStr = (try? container.decode(String?.self, forKey: .lightUrlStr)) ?? nil
            darkUrlStr = (try? container.decode(String?.self, forKey: .darkUrlStr)) ?? nil
            
            if (coloredUrlStr == nil && lightUrlStr == nil && darkUrlStr == nil) {
                let err = InternalError.failedToDecode(message: "BaseColoredURLs", userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(coloredUrlStr, forKey: .coloredUrlStr)
            try? container.encode(lightUrlStr, forKey: .lightUrlStr)
            try? container.encode(darkUrlStr, forKey: .darkUrlStr)
        }
    }
    
    public class BaseColors: Codable {
        
        var coloredHex: String?
        var darkHex: String?
        var lightHex: String?
        
        private enum CodingKeys: String, CodingKey {
            case coloredHex = "colored"
            case darkHex = "dark"
            case lightHex = "light"
        }
        
        init?(
            coloredHex: String?,
            lightHex: String?,
            darkHex: String?
        ) {
            self.coloredHex = coloredHex
            self.lightHex = lightHex
            self.darkHex = darkHex
        }
        
        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            coloredHex = (try? container.decode(String?.self, forKey: .coloredHex)) ?? nil
            darkHex = (try? container.decode(String?.self, forKey: .darkHex)) ?? nil
            lightHex = (try? container.decode(String?.self, forKey: .lightHex)) ?? nil
            
            if (coloredHex == nil && lightHex == nil && darkHex == nil) {
                let err = InternalError.failedToDecode(message: "BaseColors", userInfo: nil, diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                throw err
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(coloredHex, forKey: .coloredHex)
            try? container.encode(darkHex, forKey: .darkHex)
            try? container.encode(lightHex, forKey: .lightHex)
        }
    }
    
    public class BaseBorderWidth: Codable {
        
        var colored: CGFloat?
        var dark: CGFloat?
        var light: CGFloat?
        
        private enum CodingKeys: String, CodingKey {
            case colored
            case dark
            case light
        }
        
        init?(
            colored: CGFloat? = 0,
            light: CGFloat? = 0,
            dark: CGFloat? = 0
        ) {
            self.colored = colored
            self.light = light
            self.dark = dark
        }
        
        public required init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            colored = (try? container.decode(CGFloat?.self, forKey: .colored)) ?? nil
            light = (try? container.decode(CGFloat?.self, forKey: .light)) ?? nil
            dark = (try? container.decode(CGFloat?.self, forKey: .dark)) ?? nil
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
            try? container.encode(colored, forKey: .colored)
            try? container.encode(light, forKey: .light)
            try? container.encode(dark, forKey: .dark)
        }
    }
}



