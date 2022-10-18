//
//  UserInterfaceModule.swift
//  PrimerSDK
//
//  Copyright © 2022 Primer API ltd. All rights reserved.
//


#if canImport(UIKit)

import UIKit

//protocol UserInterfaceModuleProtocol {
//
//    var paymentMethodModule: PaymentMethodModuleProtocol! { get }
//    var logo: UIImage? { get }
//    var invertedLogo: UIImage? { get }
//    var icon: UIImage? { get }
//    var surchargeSectionText: String? { get }
//    var paymentMethodButton: PrimerButton { get }
//    var submitButton: PrimerButton? { get }
//
//    init(paymentMethodModule: PaymentMethodModuleProtocol)
//    func makeLogoImageView(withSize size: CGSize?) -> UIImageView?
//    func makeIconImageView(withDimension dimension: CGFloat) -> UIImageView?
//}

class UserInterfaceModule: NSObject {
    
    // MARK: - PROPERTIES
    
    weak var paymentMethodModule: PaymentMethodModuleProtocol!
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    var logo: UIImage? {
        return paymentMethodModule.paymentMethodConfiguration.logo
    }
    
    var invertedLogo: UIImage? {
        return paymentMethodModule.paymentMethodConfiguration.invertedLogo
    }
    
    var navigationBarLogo: UIImage? {
        
        guard let internaPaymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodTokenizationViewModel.config.type) else {
            return logo
        }
        
        switch internaPaymentMethodType {
        case .adyenBlik:
            return UIScreen.isDarkModeEnabled ? logo : UIImage(named: "blik-logo-light", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenMultibanco:
            return UIScreen.isDarkModeEnabled ? logo : UIImage(named: "multibanco-logo-light", in: Bundle.primerResources, compatibleWith: nil)
        default:
            return logo
        }
    }
    
    var icon: UIImage? {
        var fileName = paymentMethodModule.paymentMethodConfiguration.type.lowercased().replacingOccurrences(of: "_", with: "-")
        fileName += "-icon"
        
        switch self.themeMode {
        case .colored:
            fileName += "-colored"
        case .dark:
            fileName += "-dark"
        case .light:
            fileName += "-colored"
        }
        
        return UIImage(named: fileName, in: Bundle.primerResources, compatibleWith: nil)
    }
    
    var themeMode: PrimerTheme.Mode {
        if let baseLogoImage = paymentMethodModule.paymentMethodConfiguration.baseLogoImage {
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
        guard let internaPaymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodModule.paymentMethodConfiguration.type) else { return nil }
        
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
    
    var surchargeSectionText: String? {
        switch paymentMethodModule.paymentMethodConfiguration.type {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            return Strings.CardFormView.additionalFeesTitle
        default:
            guard let currency = AppState.current.currency else { return nil }
            guard let availablePaymentMethods = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods, !availablePaymentMethods.isEmpty else { return nil }
            guard let str = availablePaymentMethods.filter({ $0.type == paymentMethodModule.paymentMethodConfiguration.type }).first?.surcharge?.toCurrencyString(currency: currency) else { return nil }
            return "+\(str)"
        }
    }
    
    var buttonTitle: String? {
        
        let metadataButtonText = paymentMethodModule.paymentMethodConfiguration.displayMetadata?.button.text
            ?? self.localDisplayMetadata?.button.text
        
        switch paymentMethodModule.paymentMethodConfiguration.type {
        
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
        return self.logo
    }
    
    lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    var buttonCornerRadius: CGFloat? {
        let cornerRadius = paymentMethodModule.paymentMethodConfiguration.displayMetadata?.button.cornerRadius
            ?? self.localDisplayMetadata?.button.cornerRadius
        guard cornerRadius != nil else { return 4.0 }
        return CGFloat(cornerRadius!)
    }
    
    var buttonColor: UIColor? {
        let baseBackgroundColor = paymentMethodModule.paymentMethodConfiguration.displayMetadata?.button.backgroundColor
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
        let baseTextColor = paymentMethodModule.paymentMethodConfiguration.displayMetadata?.button.textColor
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
        let baseBorderWidth = paymentMethodModule.paymentMethodConfiguration.displayMetadata?.button.borderWidth
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
        let baseBorderColor = paymentMethodModule.paymentMethodConfiguration.displayMetadata?.button.borderColor
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
    
    var paymentMethodButton: PrimerButton {
        
        let customPaddingSettingsCard: [String] = [
            PrimerPaymentMethodType.coinbase.rawValue,
            PrimerPaymentMethodType.paymentCard.rawValue,
            PrimerPaymentMethodType.adyenBancontactCard.rawValue
        ]
        
        let paymentMethodButton = PrimerButton()
        paymentMethodButton.translatesAutoresizingMaskIntoConstraints = false
        paymentMethodButton.accessibilityIdentifier = paymentMethodModule.paymentMethodConfiguration.type
        paymentMethodButton.clipsToBounds = true
        let imagePadding: CGFloat = 20
        let leftPadding = UILocalizableUtil.isRightToLeftLocale ? imagePadding : 0
        let defaultRightPadding = customPaddingSettingsCard.contains(paymentMethodModule.paymentMethodConfiguration.type) ? imagePadding : 0
        let rightPadding = UILocalizableUtil.isRightToLeftLocale ? 0 : defaultRightPadding
        paymentMethodButton.imageEdgeInsets = UIEdgeInsets(top: 8,
                                                           left: leftPadding,
                                                           bottom: 8,
                                                           right: rightPadding)
        paymentMethodButton.contentMode = .scaleAspectFit
        paymentMethodButton.imageView?.contentMode = .scaleAspectFit
        paymentMethodButton.titleLabel?.font = buttonFont
        if let buttonCornerRadius = buttonCornerRadius {
            paymentMethodButton.layer.cornerRadius = buttonCornerRadius
        }
        paymentMethodButton.backgroundColor = buttonColor
        paymentMethodButton.setTitle(self.buttonTitle, for: .normal)
        paymentMethodButton.setImage(self.buttonImage, for: .normal)
        paymentMethodButton.setTitleColor(buttonTitleColor, for: .normal)
        paymentMethodButton.tintColor = buttonTintColor
        paymentMethodButton.layer.borderWidth = buttonBorderWidth
        paymentMethodButton.layer.borderColor = buttonBorderColor?.cgColor
        paymentMethodButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        paymentMethodButton.addTarget(self, action: #selector(paymentMethodButtonTapped(_:)), for: .touchUpInside)
        return paymentMethodButton
    }
    
    lazy var submitButton: PrimerButton? = {
        var buttonTitle: String = ""
        
        switch self.paymentMethodModule.paymentMethodConfiguration.type {
        case PrimerPaymentMethodType.paymentCard.rawValue,
            PrimerPaymentMethodType.adyenMBWay.rawValue:
            switch PrimerInternal.shared.intent {
            case .checkout:
                let universalCheckoutViewModel: UniversalCheckoutViewModelProtocol = UniversalCheckoutViewModel()
                buttonTitle = Strings.PaymentButton.pay
                if let amountStr = universalCheckoutViewModel.amountStr {
                    buttonTitle += " \(amountStr)"
                }
                
            case .vault:
                buttonTitle = Strings.PrimerCardFormView.addCardButtonTitle
                
            case .none:
                precondition(false, "Intent should have been set")
            }
            
            return makePrimerButtonWithTitleText(buttonTitle, isEnabled: false)
            
        case PrimerPaymentMethodType.primerTestKlarna.rawValue,
            PrimerPaymentMethodType.primerTestPayPal.rawValue,
            PrimerPaymentMethodType.primerTestSofort.rawValue:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.pay, isEnabled: false)
            
        case PrimerPaymentMethodType.adyenBlik.rawValue,
            PrimerPaymentMethodType.xfersPayNow.rawValue:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.confirm, isEnabled: false)
        
        case PrimerPaymentMethodType.adyenMultibanco.rawValue:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.confirmToPay, isEnabled: true)
        
        case PrimerPaymentMethodType.adyenBancontactCard.rawValue:
            return makePrimerButtonWithTitleText(Strings.PaymentButton.pay, isEnabled: false)

        default:
            return nil
        }
    }()
    
    var isSubmitButtonAnimating: Bool {
        submitButton?.isAnimating == true
    }
    
    // MARK: - INITIALIZATION
    
    required init(paymentMethodModule: PaymentMethodModuleProtocol) {
        self.paymentMethodModule = paymentMethodModule
    }
    
    // MARK: - HELPERS
    
    private func makePrimerButtonWithTitleText(_ titleText: String, isEnabled: Bool) -> PrimerButton {
        let submitButton = PrimerButton()
        submitButton.translatesAutoresizingMaskIntoConstraints = false
        submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
        submitButton.isAccessibilityElement = true
        submitButton.accessibilityIdentifier = "submit_btn"
        submitButton.isEnabled = isEnabled
        submitButton.setTitle(titleText, for: .normal)
        submitButton.backgroundColor = isEnabled ? theme.mainButton.color(for: .enabled) : theme.mainButton.color(for: .disabled)
        submitButton.setTitleColor(theme.mainButton.text.color, for: .normal)
        submitButton.layer.cornerRadius = 4
        submitButton.clipsToBounds = true
        submitButton.addTarget(self, action: #selector(submitButtonTapped(_:)), for: .touchUpInside)
        return submitButton
    }
    
    func makeLogoImageView(withSize size: CGSize?) -> UIImageView? {
        guard let logo = self.logo else { return nil }
        
        var tmpSize: CGSize! = size
        if size == nil {
            tmpSize = CGSize(width: logo.size.width, height: logo.size.height)
        }
        
        let imgView = UIImageView()
        imgView.image = logo
        imgView.contentMode = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.heightAnchor.constraint(equalToConstant: tmpSize.width).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: tmpSize.height).isActive = true
        return imgView
    }
    
    func makeIconImageView(withDimension dimension: CGFloat) -> UIImageView? {
        guard let squareLogo = self.icon else { return nil }
        let imgView = UIImageView()
        imgView.image = squareLogo
        imgView.contentMode = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.heightAnchor.constraint(equalToConstant: dimension).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: dimension).isActive = true
        return imgView
    }
    
    @IBAction private func paymentMethodButtonTapped(_ sender: UIButton) {
        self.paymentMethodModule.tokenizeAndPayIfNeeded()
    }
    
    @IBAction private func submitButtonTapped(_ sender: UIButton) {
//        self.paymentMethodTokenizationViewModel.submitButtonTapped()
    }
    
    
    
    
    
    
    
    
    
    
    // MARK: Adyen MBWay PhoneNumber prefix view
    
    var prefixSelectorButton: PrimerButton = {
        let countryCodeFlag = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode?.flag ?? ""
        let countryDialCode = CountryCode.phoneNumberCountryCodes.first(where: { $0.code == PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.countryCode?.rawValue})?.dialCode ?? ""
        
        let prefixSelectorButton = PrimerButton()
        prefixSelectorButton.isAccessibilityElement = true
        prefixSelectorButton.accessibilityIdentifier = "prefix_selector_btn"
        prefixSelectorButton.titleLabel?.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
        prefixSelectorButton.setTitle("\(countryCodeFlag) \(countryDialCode)", for: .normal)
        prefixSelectorButton.setTitleColor(.black, for: .normal)
        prefixSelectorButton.clipsToBounds = true
        prefixSelectorButton.isUserInteractionEnabled = false
        prefixSelectorButton.translatesAutoresizingMaskIntoConstraints = false
        prefixSelectorButton.widthAnchor.constraint(equalToConstant: 80.0).isActive = true
        prefixSelectorButton.contentVerticalAlignment = .top
        return prefixSelectorButton
    }()
    
    // MARK: Adyen MBWay Input View
    
    var mbwayTopLabelView: UILabel = {
        let label = UILabel()
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        label.font = UIFont.systemFont(ofSize: 10.0, weight: .medium)
        label.text = Strings.MBWay.inputTopPlaceholder
        label.textColor = theme.text.system.color
        return label
    }()
    
    var mbwayInputView: Input = {
        let input1 = Input()
        input1.keyboardType = .numberPad
        input1.allowedCharacterSet = CharacterSet(charactersIn: "0123456789")
        input1.isValid = { text in
            return text.isNumeric && text.count >= 8
        }
        return input1
    }()
    
    // MARK: Adyen Blik Input View
    
    var adyenBlikInputView: Input = {
        let input1 = Input()
        input1.name = "OTP"
        input1.topPlaceholder = Strings.Blik.inputTopPlaceholder
        input1.textFieldPlaceholder = Strings.Blik.inputTextFieldPlaceholder
        input1.keyboardType = .numberPad
        input1.descriptor = Strings.Blik.inputDescriptor
        input1.allowedCharacterSet = CharacterSet.decimalDigits
        input1.maxCharactersAllowed = 6
        input1.isValid = { text in
            return text.isNumeric && text.count >= 6
        }
        
        return input1
    }()
    
    func createInputTextFieldsStackViews(inputs: [Input], textFieldsDelegate: PrimerTextFieldViewDelegate) -> [UIStackView] {
        var stackViews: [UIStackView] = []
        
        for input in inputs {
            let stackView = UIStackView()
            stackView.spacing = 2
            stackView.axis = .horizontal
            stackView.alignment = .fill
            stackView.distribution = .fillProportionally
            
            let inputStackView = UIStackView()
            inputStackView.spacing = 2
            inputStackView.axis = .vertical
            inputStackView.alignment = .fill
            inputStackView.distribution = .fill
            
            let inputTextFieldView = PrimerGenericFieldView()
            inputTextFieldView.delegate = textFieldsDelegate
            inputTextFieldView.translatesAutoresizingMaskIntoConstraints = false
            inputTextFieldView.heightAnchor.constraint(equalToConstant: 35).isActive = true
            inputTextFieldView.textField.keyboardType = input.keyboardType ?? .default
            inputTextFieldView.allowedCharacterSet = input.allowedCharacterSet
            inputTextFieldView.maxCharactersAllowed = input.maxCharactersAllowed
            inputTextFieldView.isValid = input.isValid
            inputTextFieldView.shouldMaskText = false
            input.primerTextFieldView = inputTextFieldView
            
            let inputContainerView = PrimerCustomFieldView()
            inputContainerView.fieldView = inputTextFieldView
            inputContainerView.placeholderText = input.topPlaceholder
            inputContainerView.setup()
            inputContainerView.tintColor = .systemBlue
            inputStackView.addArrangedSubview(inputContainerView)
            
            if let descriptor = input.descriptor {
                let lbl = UILabel()
                lbl.font = UIFont.systemFont(ofSize: 12)
                lbl.translatesAutoresizingMaskIntoConstraints = false
                lbl.text = descriptor
                inputStackView.addArrangedSubview(lbl)
            }
            
            if self.paymentMethodModule.paymentMethodConfiguration.type == PrimerPaymentMethodType.adyenMBWay.rawValue {
                let phoneNumberLabelStackView = UIStackView()
                phoneNumberLabelStackView.spacing = 2
                phoneNumberLabelStackView.axis = .vertical
                phoneNumberLabelStackView.alignment = .fill
                phoneNumberLabelStackView.distribution = .fill
                phoneNumberLabelStackView.addArrangedSubview(self.paymentMethodModule.userInterfaceModule.mbwayTopLabelView)
                inputTextFieldView.font = UIFont.systemFont(ofSize: 17.0, weight: .regular)
                stackViews.insert(phoneNumberLabelStackView, at: 0)
                stackView.addArrangedSubview(self.paymentMethodModule.userInterfaceModule.prefixSelectorButton)
            }
            
            stackView.addArrangedSubview(inputStackView)
            stackViews.append(stackView)
        }
        
        return stackViews
    }
    
    func createCountriesTableView(dataSource: UITableViewDataSource, delegate: UITableViewDelegate) -> UITableView {
        let theme: PrimerThemeProtocol = DependencyContainer.resolve()
        
        let tableView = UITableView()
        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.backgroundColor = theme.view.backgroundColor
        
        if #available(iOS 11.0, *) {
            tableView.contentInsetAdjustmentBehavior = .never
        }
        
        tableView.rowHeight = 41
        tableView.register(CountryTableViewCell.self, forCellReuseIdentifier: CountryTableViewCell.className)
        
        tableView.dataSource = dataSource
        tableView.delegate = delegate
        return tableView
    }
    
    func createSearchableTextFiel(delegate: UITextFieldDelegate) -> PrimerSearchTextField {
        let textField = PrimerSearchTextField(frame: .zero)
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.heightAnchor.constraint(equalToConstant: 35).isActive = true
        textField.delegate = delegate
        textField.borderStyle = .none
        textField.layer.cornerRadius = 3.0
        textField.font = UIFont.systemFont(ofSize: 16.0)
        textField.placeholder = Strings.CountrySelector.searchCountryTitle
        textField.rightViewMode = .always
        return textField
    }
}

#endif
