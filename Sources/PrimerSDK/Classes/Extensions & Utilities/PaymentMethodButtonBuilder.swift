//
//  PaymentMethodButtonBuilder.swift
//  PrimerSDK
//
//  Created by Dario Carlomagno on 21/11/22.
//

#if canImport(UIKit)

enum PaymentMethodButtonAccessibilityIdentifierType {
    case submit
    case paymentMethodType(String)
}

extension PaymentMethodButtonAccessibilityIdentifierType: RawRepresentable {
    
    init?(rawValue: String) {
        switch rawValue {
        case "submit_btn": self = .submit
        case let paymentMethodType: self = .paymentMethodType(paymentMethodType)
        }
    }

    var rawValue: String {
        switch self {
        case .submit: return "submit_btn"
        case let .paymentMethodType(type): return type
        }
    }
}

class PaymentMethodButtonBuilder {
    
    weak var paymentMethodConfiguration: PrimerPaymentMethod!
    var accessibilityIdentifier: PaymentMethodButtonAccessibilityIdentifierType
    
    //MARK: - Initializers
    
    init(paymentMethodConfiguration: PrimerPaymentMethod, accessibilityIdentifier: PaymentMethodButtonAccessibilityIdentifierType) {
        self.paymentMethodConfiguration = paymentMethodConfiguration
        self.accessibilityIdentifier = accessibilityIdentifier
    }
    
    private lazy var theme: PrimerThemeProtocol = {
        DependencyContainer.resolve()
    }()
    
    var themeMode: PrimerTheme.Mode {
        if let baseLogoImage = self.paymentMethodConfiguration.baseLogoImage {
            if UIScreen.isDarkModeEnabled {
                if baseLogoImage.dark != nil {
                    return .dark
                } else if baseLogoImage.colored != nil {
                    return .colored
                } else if baseLogoImage.light != nil {
                    return .light
                }
            } else {
                if baseLogoImage.colored != nil {
                    return .colored
                } else if baseLogoImage.light != nil {
                    return .light
                } else if baseLogoImage.dark != nil {
                    return .dark
                }
            }
        }
        
        if UIScreen.isDarkModeEnabled {
            return .dark
        } else {
            return .colored
        }
    }
    
    var localDisplayMetadata: PrimerPaymentMethod.DisplayMetadata? {
        guard let internaPaymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodConfiguration.type) else { return nil }
        
        switch internaPaymentMethodType {
        case .adyenAlipay:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#31B1F0",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .adyenBlik:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#000000",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
        
        case .adyenBancontactCard:
            return nil
            
        case .adyenDotPay:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: nil,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .adyenGiropay,
            .buckarooGiropay,
            .payNLGiropay:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#000268",
                        lightHex: nil,
                        darkHex: nil),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: nil,
                        dark: nil),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: nil,
                        darkHex: nil),
                    text: nil,
                    textColor: nil))
            
        case .adyenIDeal,
            .buckarooIdeal,
            .mollieIdeal,
            .payNLIdeal:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#CC0066",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .adyenInterac:
            return nil
            
        case .adyenMobilePay:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#5A78FF",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))

        case .adyenMBWay:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: nil,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .adyenMultibanco:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#000000",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: nil,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))

        case .adyenPayTrail:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .adyenPayshop:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#EE3424",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .adyenSofort,
            .buckarooSofort,
            .primerTestSofort:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#EF809F",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .adyenTrustly:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#0EE06E",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .adyenTwint:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#000000",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .adyenVipps:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#FF5B24",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .apaya:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: Strings.PaymentButton.payByMobile,
                    textColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF")))
            
        case .applePay:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#FFFFFF",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case PrimerPaymentMethodType.atome:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#F0FF5F",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .buckarooBancontact,
            .mollieBankcontact,
            .payNLBancontact:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#FFFFFF",
                        darkHex: nil),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: nil,
                        light: 1,
                        dark: nil),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: nil),
                    text: nil,
                    textColor: nil))
            
        case .buckarooEps:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#FFFFFF",
                        darkHex: nil),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: nil,
                        light: 1,
                        dark: nil),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: nil),
                    text: nil,
                    textColor: nil))
            
        case .coinbase:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#0052FF",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .goCardless:
            return nil
            
        case .googlePay:
            return nil
            
        case .hoolah:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#D63727",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .klarna,
                .primerTestKlarna:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#FFB3C7",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .opennode:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: nil,
                        light: 1,
                        dark: nil),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .payNLPayconiq:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#FF4785",
                        lightHex: nil,
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: nil,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: nil,
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .paymentCard:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#FFFFFF",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 1,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: "#000000",
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: Strings.PaymentButton.payWithCard,
                    textColor: PrimerTheme.BaseColors(
                        coloredHex: "#000000",
                        lightHex: "#000000",
                        darkHex: "#FFFFFF")))
            
        case .payPal,
                .primerTestPayPal:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#009CDE",
                        lightHex: nil,
                        darkHex: nil),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: nil,
                        dark: nil),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: nil,
                        darkHex: nil),
                    text: nil,
                    textColor: nil))
            
        case .rapydFast:
            return nil
            
        case .rapydGCash:
            return nil
            
        case .rapydGrabPay:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#01B14E",
                        lightHex: nil,
                        darkHex: nil),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: nil,
                        dark: nil),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: nil,
                        darkHex: nil),
                    text: nil,
                    textColor: nil))
                        
        case .rapydPoli:
            return nil
            
        case .twoCtwoP:
            return nil
    
        case .rapydPromptPay,
                .omisePromptPay:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#023C68",
                        lightHex: nil,
                        darkHex: nil),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: nil,
                        dark: nil),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: nil,
                        darkHex: nil),
                    text: nil,
                    textColor: nil))

        case .xenditOvo:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#4B2489",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
            
        case .xenditRetailOutlets:
            return nil

        case .xfersPayNow:
            return PrimerPaymentMethod.DisplayMetadata(
                button: PrimerPaymentMethod.DisplayMetadata.Button(
                    iconUrl: nil,
                    backgroundColor: PrimerTheme.BaseColors(
                        coloredHex: "#028BF4",
                        lightHex: "#FFFFFF",
                        darkHex: "#000000"),
                    cornerRadius: 4,
                    borderWidth: PrimerTheme.BaseBorderWidth(
                        colored: 0,
                        light: 1,
                        dark: 1),
                    borderColor: PrimerTheme.BaseColors(
                        coloredHex: nil,
                        lightHex: "#000000",
                        darkHex: "#FFFFFF"),
                    text: nil,
                    textColor: nil))
        }
    }
    
    var buttonTitle: String? {
        
        let metadataButtonText = self.paymentMethodConfiguration.displayMetadata?.button.text
            ?? self.localDisplayMetadata?.button.text
        
        switch self.paymentMethodConfiguration.type {
        case PrimerPaymentMethodType.adyenBancontactCard.rawValue:
            return Strings.PaymentButton.payWithCard
            
        case PrimerPaymentMethodType.apaya.rawValue:
            // Update with `metadataButtonText ?? Strings.PaymentButton.payByMobile` once we'll get localized strings
            return Strings.PaymentButton.payByMobile
            
        case PrimerPaymentMethodType.paymentCard.rawValue:
            // Commenting the below code as we are not getting localized strings in `text` key
            // for the a Payment Method Instrument object out of `/configuration` API response
            //
            // if let metadataButtonText = metadataButtonText { return metadataButtonText }
            return PrimerInternal.shared.intent == .vault ? Strings.VaultPaymentMethodViewContent.addCard : Strings.PaymentButton.payWithCard
            
        case PrimerPaymentMethodType.twoCtwoP.rawValue:
            return Strings.PaymentButton.payInInstallments
            
        default:
            return nil
        }
    }
    
    var buttonImage: UIImage? {
        return self.paymentMethodConfiguration.logo
    }
    
    lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    var buttonCornerRadius: CGFloat {
        let cornerRadius = self.paymentMethodConfiguration.displayMetadata?.button.cornerRadius
            ?? self.localDisplayMetadata?.button.cornerRadius
        guard cornerRadius != nil else { return 4.0 }
        return CGFloat(cornerRadius!)
    }
    
    var buttonColor: UIColor? {
        let baseBackgroundColor = self.paymentMethodConfiguration.displayMetadata?.button.backgroundColor
            ?? localDisplayMetadata?.button.backgroundColor
        
        guard baseBackgroundColor != nil else {
            return nil
        }
        
        switch self.themeMode {
        case .colored:
            if let coloredColorHex = baseBackgroundColor!.coloredHex {
                return PrimerColor(hex: coloredColorHex)
            }
        case .light:
            if let lightColorHex = baseBackgroundColor!.lightHex {
                return PrimerColor(hex: lightColorHex)
            }
        case .dark:
            if let darkColorHex = baseBackgroundColor!.darkHex {
                return PrimerColor(hex: darkColorHex)
            }
        }
        
        return nil
    }
    
    var buttonTitleColor: UIColor? {
        let baseTextColor = self.paymentMethodConfiguration.displayMetadata?.button.textColor
            ?? self.localDisplayMetadata?.button.textColor
        
        guard baseTextColor != nil else {
            return nil
        }
        
        switch self.themeMode {
        case .colored:
            if let coloredColorHex = baseTextColor!.coloredHex {
                return PrimerColor(hex: coloredColorHex)
            }
        case .light:
            if let lightColorHex = baseTextColor!.lightHex {
                return PrimerColor(hex: lightColorHex)
            }
        case .dark:
            if let darkColorHex = baseTextColor!.darkHex {
                return PrimerColor(hex: darkColorHex)
            }
        }
        
        return nil
    }
    
    var buttonBorderWidth: CGFloat {
        let baseBorderWidth = self.paymentMethodConfiguration.displayMetadata?.button.borderWidth
            ?? self.localDisplayMetadata?.button.borderWidth
        guard baseBorderWidth != nil else {
            return 0.0
        }
        
        switch self.themeMode {
        case .colored:
            return baseBorderWidth!.colored ?? 0.0
        case .light:
            return baseBorderWidth!.light ?? 0.0
        case .dark:
            return baseBorderWidth!.dark ?? 0.0
        }
    }
    
    var buttonBorderColor: UIColor? {
        let baseBorderColor = self.paymentMethodConfiguration.displayMetadata?.button.borderColor
            ?? self.localDisplayMetadata?.button.borderColor
        guard baseBorderColor != nil else {
            return nil
        }
        
        switch self.themeMode {
        case .colored:
            if let coloredColorHex = baseBorderColor!.coloredHex {
                return PrimerColor(hex: coloredColorHex)
            }
        case .light:
            if let lightColorHex = baseBorderColor!.lightHex {
                return PrimerColor(hex: lightColorHex)
            }
        case .dark:
            if let darkColorHex = baseBorderColor!.darkHex {
                return PrimerColor(hex: darkColorHex)
            }
        }
        
        return nil
    }
    
    var buttonTintColor: UIColor? {
        return nil
    }
    
    lazy var button: PrimerButton = {
        let button = PrimerButton()
        
        let customPaddingSettingsCard: [String] = [
            PrimerPaymentMethodType.coinbase.rawValue,
            PrimerPaymentMethodType.paymentCard.rawValue,
            PrimerPaymentMethodType.adyenBancontactCard.rawValue
        ]
        
        button.translatesAutoresizingMaskIntoConstraints = false
        button.accessibilityIdentifier = accessibilityIdentifier.rawValue
        button.clipsToBounds = true
        button.isEnabled = false
        let imagePadding: CGFloat = 20
        let leftPadding = UILocalizableUtil.isRightToLeftLocale ? imagePadding : 0
        let defaultRightPadding = customPaddingSettingsCard.contains(self.paymentMethodConfiguration.type) ? imagePadding : 0
        let rightPadding = UILocalizableUtil.isRightToLeftLocale ? 0 : defaultRightPadding
        button.imageEdgeInsets = UIEdgeInsets(top: 8,
                                            left: leftPadding,
                                            bottom: 8,
                                            right: rightPadding)
        button.contentMode = .scaleAspectFit
        button.imageView?.contentMode = .scaleAspectFit
        button.titleLabel?.font = self.buttonFont
        button.layer.cornerRadius = self.buttonCornerRadius
        button.backgroundColor = button.isEnabled ? self.theme.mainButton.color(for: .enabled) : self.theme.mainButton.color(for: .disabled)
        button.setTitle(self.buttonTitle, for: .normal)
        button.setImage(self.buttonImage, for: .normal)
        button.setTitleColor(self.buttonTitleColor, for: .normal)
        button.tintColor = self.buttonTintColor
        button.layer.borderWidth = self.buttonBorderWidth
        button.layer.borderColor = self.buttonBorderColor?.cgColor
        button.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        return button
    }()
}

#endif
