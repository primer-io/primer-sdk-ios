//
//  UserInterfaceModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 8/7/22.
//

#if canImport(UIKit)

protocol UserInterfaceModuleProtocol {
    
    var paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol { get }
    var logo: UIImage? { get }
    var icon: UIImage? { get }
    var surchargeSectionText: String? { get }
    var paymentMethodButton: PrimerButton { get }
    var submitButton: PrimerButton? { get }
    
    init(paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol)
    func makeLogoImageView(withSize size: CGSize?) -> UIImageView?
    func makeIconImageView(withDimension dimension: CGFloat) -> UIImageView?
}

import UIKit

class UserInterfaceModule: NSObject, UserInterfaceModuleProtocol {
    
    // MARK: - PROPERTIES
    
    var paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    var logo: UIImage? {
        guard let baseImageFiles = paymentMethodTokenizationViewModel.config.imageFiles else { return nil }
        
        if UIScreen.isDarkModeEnabled {
            if let darkImage = baseImageFiles.dark?.image {
                return darkImage
            } else if let coloredImage = baseImageFiles.colored?.image {
                return coloredImage
            } else if let lightImage = baseImageFiles.light?.image {
                return lightImage
            } else {
                return nil
            }
        } else {
            if let lightImage = baseImageFiles.light?.image {
                return lightImage
            } else if let coloredImage = baseImageFiles.colored?.image {
                return coloredImage
            } else if let darkImage = baseImageFiles.dark?.image {
                return darkImage
            } else {
                return nil
            }
    var localDisplayMetadata: PrimerPaymentMethod.DisplayMetadata? {
        guard let internaPaymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodTokenizationViewModel.config.type) else { return nil }
        
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
                    text: "Pay by mobile",
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
                    text: "Pay by card",
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
            
        case .rapydPromptPay:
            return nil
            
        case .rapydPoli:
            return nil
            
        case .twoCtwoP:
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
    
    lazy var icon: UIImage? = {
        guard let imageName = paymentMethodTokenizationViewModel.config.imageFiles?.colored?.image else { return nil }
        
        // In case we don't have a square icon, we show the icon image
        let imageLogoSquare = UIImage(named: "\(imageName)-icon-colored", in: Bundle.primerResources, compatibleWith: nil)
        let imageIcon = UIImage(named: "\(imageName)-icon", in: Bundle.primerResources, compatibleWith: nil)
        return imageLogoSquare ?? imageIcon
    }()
    
    var surchargeSectionText: String? {
        switch paymentMethodTokenizationViewModel.config.type {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            return NSLocalizedString("surcharge-additional-fee",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Additional fee may apply",
                                     comment: "Additional fee may apply - Surcharge (Label)")
        default:
            guard let currency = AppState.current.currency else { return nil }
            guard let availablePaymentMethods = AppState.current.apiConfiguration?.paymentMethods, !availablePaymentMethods.isEmpty else { return nil }
            guard let str = availablePaymentMethods.filter({ $0.type == paymentMethodTokenizationViewModel.config.type }).first?.surcharge?.toCurrencyString(currency: currency) else { return nil }
            return "+\(str)"
        }
    }
    
    var buttonTitle: String? {
        switch paymentMethodTokenizationViewModel.config.type {
        case PrimerPaymentMethodType.apaya.rawValue:
            return NSLocalizedString(paymentMethodTokenizationViewModel.config.displayMetadata?.button.text ?? "payment-method-type-pay-by-mobile",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: paymentMethodTokenizationViewModel.config.displayMetadata?.button.text ?? "Pay by mobile",
                                     comment: "Pay by mobile - Payment By Mobile (Apaya)")
            
        case PrimerPaymentMethodType.paymentCard.rawValue:
            return Primer.shared.intent == .vault
                ? Strings.VaultPaymentMethodViewContent.addCard
                : Strings.VaultPaymentMethodViewContent.payWithCard
            
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
        guard let cornerRadius = paymentMethodTokenizationViewModel.config.displayMetadata?.button.cornerRadius else { return 4.0 }
        return CGFloat(cornerRadius)
    }
    
    var buttonColor: UIColor? {
        if let baseBackgroundColor = paymentMethodTokenizationViewModel.config.displayMetadata?.button.backgroundColor {
            if UIScreen.isDarkModeEnabled {
                if let darkBorderColorHex = baseBackgroundColor.darkHex {
                    return PrimerColor(hex: darkBorderColorHex)
                } else if let coloredBorderColorHex = baseBackgroundColor.coloredHex {
                    return PrimerColor(hex: coloredBorderColorHex)
                } else if let lightBorderColorHex = baseBackgroundColor.lightHex {
                    return PrimerColor(hex: lightBorderColorHex)
                }
            } else {
                if let lightBorderColorHex = baseBackgroundColor.lightHex {
                    return PrimerColor(hex: lightBorderColorHex)
                } else if let coloredBorderColorHex = baseBackgroundColor.coloredHex {
                    return PrimerColor(hex: coloredBorderColorHex)
                } else if let darkBorderColorHex = baseBackgroundColor.darkHex {
                    return PrimerColor(hex: darkBorderColorHex)
                }
            }
        }
        
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodTokenizationViewModel.config.type) else {
            return nil
        }
        
        switch paymentMethodType {
        case .adyenAlipay:
            return UIColor(red: 49.0/255, green: 177.0/255, blue: 240.0/255, alpha: 1.0)
        case .adyenBlik:
            return .black
        case .adyenDotPay:
            return .white
        case .adyenGiropay,
                .buckarooGiropay:
            return UIColor(red: 0, green: 2.0/255, blue: 104.0/255, alpha: 1.0)
        case .adyenIDeal:
            return UIColor(red: 204.0/255, green: 0.0/255, blue: 102.0/255, alpha: 1.0)
        case .adyenInterac:
            return UIColor(red: 254.0/255, green: 185.0/255, blue: 43.0/255, alpha: 1.0)
        case .adyenSofort,
                .buckarooSofort,
                .primerTestSofort:
            return UIColor(red: 239.0/255, green: 128.0/255, blue: 159.0/255, alpha: 1.0)
        case .adyenMobilePay:
            return UIColor(red: 90.0/255, green: 120.0/255, blue: 255.0/255, alpha: 1.0)
        case .adyenPayTrail:
            return UIColor(red: 229.0/255, green: 11.0/255, blue: 150.0/255, alpha: 1.0)
        case .adyenTrustly:
            return UIColor(red: 14.0/255, green: 224.0/255, blue: 110.0/255, alpha: 1.0)
        case .adyenTwint:
            return .black
        case .adyenVipps:
            return UIColor(red: 255.0/255, green: 91.0/255, blue: 36.0/255, alpha: 1.0)
        case .apaya:
            return theme.paymentMethodButton.color(for: .enabled)
        case .applePay:
            return .black
        case .atome:
            return UIColor(red: 240.0/255, green: 255.0/255, blue: 95.0/255, alpha: 1.0)
        case .buckarooEps:
            return .white
        case .hoolah:
            return UIColor(red: 214.0/255, green: 55.0/255, blue: 39.0/255, alpha: 1.0)
        case .klarna,
                .primerTestKlarna:
            return UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1.0)
        case .buckarooBancontact,
                .mollieBankcontact,
                .payNLBancontact:
            return .white
        case .payNLIdeal,
                .buckarooIdeal,
                .mollieIdeal:
            return UIColor(red: 204.0/255, green: 0.0, blue: 102.0/255, alpha: 1.0)
        case .payNLGiropay:
            return UIColor(red: 0, green: 2.0/255, blue: 104.0/255, alpha: 1.0)
        case .payNLPayconiq:
            return UIColor(red: 255.0/255, green: 71.0/255, blue: 133.0/255, alpha: 1.0)
        case .paymentCard:
            return theme.paymentMethodButton.color(for: .enabled)
        case .payPal,
                .primerTestPayPal:
            return UIColor(red: 0.0/255, green: 156.0/255, blue: 222.0/255, alpha: 1)
        case .rapydGCash:
            return UIColor(red: 0.161, green: 0.482, blue: 0.98, alpha: 1)
        case .rapydGrabPay:
            return UIColor(red: 0.004, green: 0.694, blue: 0.306, alpha: 1)
        case .rapydPoli:
            return UIColor(red: 0.184, green: 0.263, blue: 0.596, alpha: 1)
        case .xfersPayNow:
            return UIColor(red: 148.0/255, green: 31.0/255, blue: 127.0/255, alpha: 1.0)
        default:
            precondition(false, "Shouldn't end up in here")
            return nil
        }
    }
    
    var buttonTitleColor: UIColor? {
        guard let baseTextColor = paymentMethodTokenizationViewModel.config.displayMetadata?.button.textColor else {
            switch paymentMethodTokenizationViewModel.config.type {
            case PrimerPaymentMethodType.apaya.rawValue,
                PrimerPaymentMethodType.paymentCard.rawValue:
                return theme.paymentMethodButton.text.color
                
            default:
                return nil
            }
        }
        
        if UIScreen.isDarkModeEnabled {
            if let darkBorderColorHex = baseTextColor.darkHex {
                return PrimerColor(hex: darkBorderColorHex)
            } else if let coloredBorderColorHex = baseTextColor.coloredHex {
                return PrimerColor(hex: coloredBorderColorHex)
            } else if let lightBorderColorHex = baseTextColor.lightHex {
                return PrimerColor(hex: lightBorderColorHex)
            } else {
                return nil
            }
        } else {
            if let lightBorderColorHex = baseTextColor.lightHex {
                return PrimerColor(hex: lightBorderColorHex)
            } else if let coloredBorderColorHex = baseTextColor.coloredHex {
                return PrimerColor(hex: coloredBorderColorHex)
            } else if let darkBorderColorHex = baseTextColor.darkHex {
                return PrimerColor(hex: darkBorderColorHex)
            } else {
                return nil
            }
        }
    }
    
    var buttonBorderWidth: CGFloat {
        if let borderWidth = paymentMethodTokenizationViewModel.config.displayMetadata?.button.borderWidth {
            return CGFloat(borderWidth)
        }
        
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodTokenizationViewModel.config.type) else {
            return 0.0
        }
        
        switch paymentMethodType {
        case .adyenAlipay,
                .adyenBlik,
                .adyenGiropay,
                .adyenIDeal,
                .adyenInterac,
                .adyenMobilePay,
                .adyenPayTrail,
                .adyenTrustly,
                .adyenTwint,
                .adyenVipps,
                .atome,
                .buckarooIdeal,
                .buckarooGiropay,
                .buckarooSofort,
                .hoolah,
                .klarna,
                .mollieIdeal,
                .payNLGiropay,
                .payNLIdeal,
                .payNLPayconiq,
                .payPal,
                .primerTestPayPal,
                .primerTestKlarna,
                .primerTestSofort,
                .rapydGCash,
                .rapydPoli,
                .rapydGrabPay:
            return 0.0
            
        case .adyenDotPay,
                .apaya,
                .buckarooBancontact,
                .buckarooEps,
                .mollieBankcontact,
                .payNLBancontact,
                .paymentCard:
            return 1.0
            
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }
    
    var buttonBorderColor: UIColor? {
        if let baseBorderColor = paymentMethodTokenizationViewModel.config.displayMetadata?.button.borderColor {
            if UIScreen.isDarkModeEnabled {
                if let darkBorderColorHex = baseBorderColor.darkHex {
                    return PrimerColor(hex: darkBorderColorHex)
                } else if let coloredBorderColorHex = baseBorderColor.coloredHex {
                    return PrimerColor(hex: coloredBorderColorHex)
                } else if let lightBorderColorHex = baseBorderColor.lightHex {
                    return PrimerColor(hex: lightBorderColorHex)
                }
            } else {
                if let lightBorderColorHex = baseBorderColor.lightHex {
                    return PrimerColor(hex: lightBorderColorHex)
                } else if let coloredBorderColorHex = baseBorderColor.coloredHex {
                    return PrimerColor(hex: coloredBorderColorHex)
                } else if let darkBorderColorHex = baseBorderColor.darkHex {
                    return PrimerColor(hex: darkBorderColorHex)
                }
            }
        }
        
        guard let paymentMethodType = PrimerPaymentMethodType(rawValue: paymentMethodTokenizationViewModel.config.type) else {
            return nil
        }
        
        switch paymentMethodType {
        case .adyenAlipay,
                .adyenBlik,
                .adyenDotPay,
                .adyenGiropay,
                .adyenMobilePay,
                .adyenIDeal,
                .adyenInterac,
                .adyenPayTrail,
                .adyenTrustly,
                .adyenTwint,
                .adyenVipps,
                .atome,
                .buckarooIdeal,
                .buckarooGiropay,
                .buckarooSofort,
                .hoolah,
                .klarna,
                .mollieIdeal,
                .payNLGiropay,
                .payNLIdeal,
                .payNLPayconiq,
                .payPal,
                .primerTestPayPal,
                .primerTestKlarna,
                .primerTestSofort,
                .rapydGCash,
                .rapydGrabPay,
                .rapydPoli,
                .xfersPayNow:
            return nil
            
        case .apaya,
                .paymentCard:
            return theme.paymentMethodButton.text.color
            
        case .buckarooBancontact,
                .buckarooEps,
                .mollieBankcontact,
                .payNLBancontact:
            return .black
            
        default:
            precondition(false, "Shouldn't end up in here")
            return nil
        }
    }
    
    var buttonTintColor: UIColor? {
        return nil
    }
    
    var paymentMethodButton: PrimerButton {
        let customPaddingSettingsCard: [String] = [
            PrimerPaymentMethodType.coinbase.rawValue,
            PrimerPaymentMethodType.paymentCard.rawValue
        ]
        
        let paymentMethodButton = PrimerButton()
        paymentMethodButton.accessibilityIdentifier = paymentMethodTokenizationViewModel.config.type
        paymentMethodButton.clipsToBounds = true
        paymentMethodButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        let imagePadding: CGFloat = 20
        let leftPadding = UILocalizableUtil.isRightToLeftLocale ? imagePadding : 0
        let defaultRightPadding = customPaddingSettingsCard.contains(paymentMethodTokenizationViewModel.config.type) ? imagePadding : 0
        let rightPadding = UILocalizableUtil.isRightToLeftLocale ? 0 : defaultRightPadding
        paymentMethodButton.imageEdgeInsets = UIEdgeInsets(top: 5,
                                                           left: leftPadding,
                                                           bottom: 5,
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
        paymentMethodButton.addTarget(self, action: #selector(paymentMethodButtonTapped(_:)), for: .touchUpInside)
        return paymentMethodButton
    }
    
    lazy var submitButton: PrimerButton? = {
        var buttonTitle: String = ""
        
        switch self.paymentMethodTokenizationViewModel.config.type {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            switch Primer.shared.intent {
            case .checkout:
                let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
                buttonTitle = Strings.PaymentButton.pay
                
            case .vault:
                buttonTitle = Strings.PrimerCardFormView.addCardButtonTitle
                
            case .none:
                assert(true, "Intent should have been set")
            }
            
            let submitButton = PrimerButton()
            submitButton.translatesAutoresizingMaskIntoConstraints = false
            submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            submitButton.isAccessibilityElement = true
            submitButton.accessibilityIdentifier = "submit_btn"
            submitButton.isEnabled = false
            submitButton.setTitle(buttonTitle, for: .normal)
            submitButton.setTitleColor(theme.mainButton.text.color, for: .normal)
            submitButton.backgroundColor = theme.mainButton.color(for: .disabled)
            submitButton.layer.cornerRadius = 4
            submitButton.clipsToBounds = true
            submitButton.addTarget(self, action: #selector(submitButtonTapped(_:)), for: .touchUpInside)
            return submitButton
            
        case PrimerPaymentMethodType.primerTestKlarna.rawValue,
            PrimerPaymentMethodType.primerTestPayPal.rawValue,
            PrimerPaymentMethodType.primerTestSofort.rawValue:
            let submitButton = PrimerButton()
            submitButton.translatesAutoresizingMaskIntoConstraints = false
            submitButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
            submitButton.isAccessibilityElement = true
            submitButton.accessibilityIdentifier = "submit_btn"
            submitButton.isEnabled = false
            submitButton.setTitleColor(theme.mainButton.text.color, for: .normal)
            submitButton.backgroundColor = theme.mainButton.color(for: .disabled)
            submitButton.layer.cornerRadius = 4
            submitButton.clipsToBounds = true
            submitButton.addTarget(self, action: #selector(submitButtonTapped(_:)), for: .touchUpInside)
            return submitButton
            
        case PrimerPaymentMethodType.adyenBlik.rawValue,
            PrimerPaymentMethodType.xfersPayNow.rawValue:
            let btn = PrimerButton()
            btn.isEnabled = false
            btn.clipsToBounds = true
            btn.heightAnchor.constraint(equalToConstant: 45).isActive = true
            btn.titleLabel?.font = UIFont.systemFont(ofSize: 16, weight: .bold)
            btn.layer.cornerRadius = 4
            btn.backgroundColor = btn.isEnabled ? theme.mainButton.color(for: .enabled) : theme.mainButton.color(for: .disabled)
            btn.setTitleColor(.white, for: .normal)
            btn.addTarget(self, action: #selector(submitButtonTapped(_:)), for: .touchUpInside)
            btn.setTitle("Confirm", for: .normal)
            return btn
            
        default:
            return nil
        }
    }()
    
    // MARK: - INITIALIZATION
    
    required init(paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol) {
        self.paymentMethodTokenizationViewModel = paymentMethodTokenizationViewModel
    }
    
    // MARK: - HELPERS
    
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
    
    @IBAction func paymentMethodButtonTapped(_ sender: UIButton) {
        self.paymentMethodTokenizationViewModel.start()
    }
    
    @IBAction func submitButtonTapped(_ sender: UIButton) {
        self.paymentMethodTokenizationViewModel.submitButtonTapped()
    }
}

#endif
