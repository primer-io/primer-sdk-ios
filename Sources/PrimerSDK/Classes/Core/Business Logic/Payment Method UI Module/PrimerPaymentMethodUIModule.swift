//
//  PrimerPaymentMethodUIModule.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 30/6/23.
//

import Foundation

class PrimerPaymentMethodUIModule: NSObject {
    
    let paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator
    var paymentMethodAsset: PrimerPaymentMethodAsset?
    var paymentMethodButton: UIButton?
    var submitButton: UIButton?
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    init(paymentMethodOrchestrator: PrimerPaymentMethodOrchestrator) {
        self.paymentMethodOrchestrator = paymentMethodOrchestrator
        super.init()
        self.paymentMethodAsset = self.buildPaymentMethodAsset()
        self.paymentMethodButton = self.buildPaymentMethodButton()
        self.submitButton = self.buildSubmitButton()
    }
    
    func presentPreTokenizationUI() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }
    
    func presentPaymentUI() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }
    
    func dismissPaymentUI() -> Promise<Void> {
        fatalError("\(#function) must be overriden")
    }
    
    
    @discardableResult
    func presentResultUIIfNeeded() -> Promise<Void> {
        return Promise { seal in
            
        }
    }
}

internal extension PrimerPaymentMethodUIModule {
    
    var logo: UIImage? {
        guard let baseLogoImage = self.paymentMethodOrchestrator.paymentMethodConfig.baseLogoImage else { return nil }
        
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
        guard let baseLogoImage = self.paymentMethodOrchestrator.paymentMethodConfig.baseLogoImage else { return nil }
        
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
    
    var navigationBarLogo: UIImage? {
        guard let internaPaymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodOrchestrator.paymentMethodConfig.type) else {
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
}

fileprivate extension PrimerPaymentMethodUIModule {
    
    /// Helper to build the **PrimerPaymentMethodAsset** that's exposed via Headless
    private func buildPaymentMethodAsset() -> PrimerPaymentMethodAsset? {
        if AppState.current.apiConfiguration == nil {
            let err = PrimerError.uninitializedSDKSession(userInfo: nil, diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            return nil
        }
        
        guard let baseLogoImage = self.paymentMethodOrchestrator.paymentMethodConfig.baseLogoImage,
              let baseBackgroundColor = self.paymentMethodOrchestrator.paymentMethodConfig.displayMetadata?.button.backgroundColor
        else {
            return nil
        }
        
        guard let paymentMethodLogo = PrimerPaymentMethodLogo(
            colored: baseLogoImage.colored,
            light: baseLogoImage.light,
            dark: baseLogoImage.dark) else {
            return nil
        }
        
        guard let paymentMethodBackgroundColor = PrimerPaymentMethodBackgroundColor(
            coloredStr: baseBackgroundColor.coloredHex,
            lightStr: baseBackgroundColor.lightHex,
            darkStr: baseBackgroundColor.darkHex) else {
            return nil
        }
        
        return PrimerPaymentMethodAsset(
            paymentMethodType: self.paymentMethodOrchestrator.paymentMethodConfig.type,
            paymentMethodName: self.paymentMethodOrchestrator.paymentMethodConfig.name,
            paymentMethodLogo: paymentMethodLogo,
            paymentMethodBackgroundColor: paymentMethodBackgroundColor)
    }
    
    /// Helper to build the payment method button that's present on the Drop In Universal Checkout.
    private func buildPaymentMethodButton() -> PrimerButton? {
        let customPaddingSettingsCard: [String] = [
            PrimerPaymentMethodType.adyenBancontactCard.rawValue,
            PrimerPaymentMethodType.coinbase.rawValue,
            PrimerPaymentMethodType.iPay88Card.rawValue,
            PrimerPaymentMethodType.paymentCard.rawValue
        ]
        
        let paymentMethodButton = PrimerButton()
        paymentMethodButton.translatesAutoresizingMaskIntoConstraints = false
        paymentMethodButton.accessibilityIdentifier = self.paymentMethodOrchestrator.paymentMethodConfig.type
        paymentMethodButton.clipsToBounds = true
        let imagePadding: CGFloat = 20
        let leftPadding = UILocalizableUtil.isRightToLeftLocale ? imagePadding : 0
        let defaultRightPadding = customPaddingSettingsCard.contains(self.paymentMethodOrchestrator.paymentMethodConfig.type) ? imagePadding : 0
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
//        paymentMethodButton.addTarget(self, action: #selector(paymentMethodButtonTapped(_:)), for: .touchUpInside)
        return paymentMethodButton
    }
    
    /// Helper to build the payment method's submit button (e.g. on the card form) that's present on the
    /// Drop In Universal Checkout
    private func buildSubmitButton() -> UIButton? {
        var buttonTitle: String = ""
        
        switch self.paymentMethodOrchestrator.paymentMethodConfig.type {
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
    }
    
    /// Helper to find out which theme mode should be used.
    var themeMode: PrimerTheme.Mode {
        if let baseLogoImage = self.paymentMethodOrchestrator.paymentMethodConfig.baseLogoImage {
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
    
    var buttonColor: UIColor? {
        let baseBackgroundColor = self.paymentMethodOrchestrator.paymentMethodConfig.displayMetadata?.button.backgroundColor
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
    
    var buttonTintColor: UIColor? {
        return nil
    }
    
    var buttonFont: UIFont? {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }
    
    var buttonCornerRadius: CGFloat? {
        let cornerRadius = self.paymentMethodOrchestrator.paymentMethodConfig.displayMetadata?.button.cornerRadius
            ?? self.localDisplayMetadata?.button.cornerRadius
        guard cornerRadius != nil else { return 4.0 }
        return CGFloat(cornerRadius!)
    }
    
    var buttonTitle: String? {
        let metadataButtonText = self.paymentMethodOrchestrator.paymentMethodConfig.displayMetadata?.button.text
            ?? self.localDisplayMetadata?.button.text
        
        switch self.paymentMethodOrchestrator.paymentMethodConfig.type {
        
        case PrimerPaymentMethodType.adyenBancontactCard.rawValue:
            return Strings.PaymentButton.payWithCard
            
        case PrimerPaymentMethodType.apaya.rawValue:
            // Update with `metadataButtonText ?? Strings.PaymentButton.payByMobile` once we'll get localized strings
            return Strings.PaymentButton.payByMobile
            
        case PrimerPaymentMethodType.iPay88Card.rawValue:
            return Strings.PaymentButton.payWithCard
            
        case PrimerPaymentMethodType.paymentCard.rawValue:
            // Commenting the below code as we are not getting localized strings in `text` key
            // for the a Payment Method Instrument object out of `/configuration` API response
            //
            // if let metadataButtonText = metadataButtonText { return metadataButtonText }
            return PrimerInternal.shared.intent == .vault ? Strings.VaultPaymentMethodViewContent.addCard : Strings.PaymentButton.payWithCard
            
        case PrimerPaymentMethodType.twoCtwoP.rawValue:
            return Strings.PaymentButton.payInInstallments
            
        default:
            return metadataButtonText
        }
    }
    
    var buttonTitleColor: UIColor? {
        let baseTextColor = self.paymentMethodOrchestrator.paymentMethodConfig.displayMetadata?.button.textColor
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
    
    var buttonImage: UIImage? {
        return self.logo
    }
    
    var buttonBorderWidth: CGFloat {
        let baseBorderWidth = self.paymentMethodOrchestrator.paymentMethodConfig.displayMetadata?.button.borderWidth
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
        let baseBorderColor = self.paymentMethodOrchestrator.paymentMethodConfig.displayMetadata?.button.borderColor
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
    
    // FIXME: Move it within **buildSubmitButton()**
    /// Helper to create a submit button
    func makePrimerButtonWithTitleText(_ titleText: String, isEnabled: Bool) -> PrimerButton {
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
//        submitButton.addTarget(self, action: #selector(submitButtonTapped(_:)), for: .touchUpInside)
        return submitButton
    }
    
    /// **surchargeSectionText** is the text above the payment method on the Drop In Universal Checkout
    /// when surcharge has been added for the payment method in the client session.
    var surchargeSectionText: String? {
        switch self.paymentMethodOrchestrator.paymentMethodConfig.type {
        case PrimerPaymentMethodType.paymentCard.rawValue:
            return Strings.CardFormView.additionalFeesTitle
        default:
            guard let currency = AppState.current.currency else { return nil }
            guard let availablePaymentMethods = PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods, !availablePaymentMethods.isEmpty else { return nil }
            guard let str = availablePaymentMethods.filter({ $0.type == self.paymentMethodOrchestrator.paymentMethodConfig.type }).first?.surcharge?.toCurrencyString(currency: currency) else { return nil }
            return "+\(str)"
        }
    }
    
    /// **localDisplayMetadata** will be used for building the UI for payment method buttons when the
    /// configuration response hasn't returned **displayMetadata**.
    var localDisplayMetadata: PrimerPaymentMethod.DisplayMetadata? {
        guard let internalPaymentMethodType = PrimerPaymentMethodType(rawValue: self.paymentMethodOrchestrator.paymentMethodConfig.type) else { return nil }
        
        switch internalPaymentMethodType {
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
            
        case .iPay88Card:
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
}
