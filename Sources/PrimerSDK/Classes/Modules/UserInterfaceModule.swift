//
//  UserInterfaceModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 8/7/22.
//

#if canImport(UIKit)

protocol UserInterfaceModuleProtocol {
    
    var paymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModelProtocol { get }
    var originalImage: UIImage? { get }
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
    
    lazy var imageName: String? = {
        switch paymentMethodTokenizationViewModel.config.type {
        case .adyenAlipay:
            return "alipay"
        case .adyenDotPay:
            return "dot-pay"
        case .adyenGiropay,
                .buckarooGiropay,
                .payNLGiropay:
            return "giropay"
        case .adyenIDeal,
                .buckarooIdeal,
                .mollieIdeal,
                .payNLIdeal:
            return "ideal"
        case .adyenInterac:
            return "interac"
        case .adyenMobilePay:
            return "mobile-pay"
        case .adyenPayshop:
            return "payshop"
        case .adyenPayTrail:
            return "paytrail"
        case .adyenSofort,
                .buckarooSofort,
                .primerTestSofort:
            return "sofort"
        case .adyenTrustly:
            return "trustly"
        case .adyenTwint:
            return "twint"
        case .adyenVipps:
            return "vipps"
        case .apaya:
            return "apaya"
        case .applePay:
            return "apple-pay"
        case .atome:
            return "atome"
        case .adyenBlik:
            return "blik"
        case .buckarooBancontact,
                .mollieBankcontact,
                .payNLBancontact:
            return "bancontact"
        case .buckarooEps:
            return "eps"
        case .coinbase:
            return "coinbase"
        case .goCardlessMandate:
            return "go-cardless"
        case .googlePay:
            return "google-pay"
        case .hoolah:
            return "hoolah"
        case .klarna,
                .primerTestKlarna:
            return "klarna"
        case .payNLPayconiq:
            return "payconiq"
        case .paymentCard:
            return "card"
        case .payPal,
                .primerTestPayPal:
            return "paypal"
        case .xfers:
            return "xfers"
        case .opennode:
            return "opennode"
        case .twoCtwoP:
            return "2c2p"
        case .other(rawValue: let rawValue):
            return rawValue
        }
    }()
    
    lazy var originalImage: UIImage? = {
        switch self.paymentMethodTokenizationViewModel.config.type {
        case .primerTestPayPal:
            return UIImage(named: "paypal-logo-1", in: Bundle.primerResources, compatibleWith: nil)
        case .primerTestSofort:
            return UIImage(named: "sofort-logo", in: Bundle.primerResources, compatibleWith: nil)
        default:
            return buttonImage
        }
    }()
    
    lazy var logo: UIImage? = {
        guard let imageName = imageName else { return nil }
        return UIImage(named: "\(imageName)-logo", in: Bundle.primerResources, compatibleWith: nil)
    }()
    
    lazy var icon: UIImage? = {
        guard let imageName = imageName else { return nil }
        // In case we don't have a square icon, we show the icon image
        let imageLogoSquare = UIImage(named: "\(imageName)-logo-square", in: Bundle.primerResources, compatibleWith: nil)
        let imageIcon = UIImage(named: "\(imageName)-icon", in: Bundle.primerResources, compatibleWith: nil)
        return imageLogoSquare ?? imageIcon
    }()
    
    lazy var surchargeSectionText: String? = {
        switch paymentMethodTokenizationViewModel.config.type {
        case .paymentCard:
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
    }()
    
    lazy var buttonTitle: String? = {
        switch paymentMethodTokenizationViewModel.config.type {
        case .adyenAlipay,
                .adyenBlik,
                .adyenGiropay,
                .applePay,
                .atome,
                .buckarooBancontact,
                .buckarooEps,
                .buckarooGiropay,
                .buckarooIdeal,
                .buckarooSofort,
                .hoolah,
                .klarna,
                .mollieBankcontact,
                .mollieIdeal,
                .payNLBancontact,
                .payNLGiropay,
                .payNLIdeal,
                .payNLPayconiq,
                .adyenSofort,
                .adyenTwint,
                .adyenTrustly,
                .adyenMobilePay,
                .adyenVipps,
                .adyenInterac,
                .adyenPayTrail,
                .payPal,
                .primerTestPayPal,
                .primerTestSofort,
                .primerTestKlarna,
                .xfers:
            return nil
            
        case .apaya:
            return NSLocalizedString("payment-method-type-pay-by-mobile",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Pay by mobile",
                                     comment: "Pay by mobile - Payment By Mobile (Apaya)")
            
        case .paymentCard:
            return Primer.shared.intent == .vault
            ? NSLocalizedString("payment-method-type-card-vaulted",
                                tableName: nil,
                                bundle: Bundle.primerResources,
                                value: "Add new card",
                                comment: "Add new card - Payment Method Type (Card Vaulted)")
            
            : NSLocalizedString("payment-method-type-card-not-vaulted",
                                tableName: nil,
                                bundle: Bundle.primerResources,
                                value: "Pay with card",
                                comment: "Pay with card - Payment Method Type (Card Not vaulted)")
            
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    lazy var buttonImage: UIImage? = {
        switch paymentMethodTokenizationViewModel.config.type {
        case .adyenAlipay:
            return UIImage(named: "alipay-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .adyenBlik:
            return UIImage(named: "blik-logo-white", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenDotPay:
            return UIImage(named: "dot-pay-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenIDeal:
            return UIImage(named: "iDeal-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .apaya:
            return UIImage(named: "mobile", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .applePay:
            return UIImage(named: "apple-pay-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .atome:
            return UIImage(named: "atome-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .buckarooBancontact,
                .mollieBankcontact,
                .payNLBancontact:
            return UIImage(named: "bancontact-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .buckarooEps:
            return UIImage(named: "eps-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenGiropay,
                .buckarooGiropay,
                .payNLGiropay:
            return UIImage(named: "giropay-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenInterac:
            return UIImage(named: "interac-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .hoolah:
            return UIImage(named: "hoolah-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .klarna,
                .primerTestKlarna:
            return UIImage(named: "klarna-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .payNLIdeal,
                .buckarooIdeal,
                .mollieIdeal:
            return UIImage(named: "iDeal-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenMobilePay:
            return UIImage(named: "mobile-pay-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .adyenPayTrail:
            return UIImage(named: "paytrail-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .payNLPayconiq:
            return UIImage(named: "payconiq-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .buckarooSofort,
                .adyenSofort,
                .primerTestSofort:
            return UIImage(named: "sofort-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .adyenTrustly:
            return UIImage(named: "trustly-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenTwint:
            return UIImage(named: "twint-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenVipps:
            return UIImage(named: "vipps-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .paymentCard:
            return UIImage(named: "creditCard", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .payPal,
                .primerTestPayPal:
            return UIImage(named: "paypal-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .xfers:
            return UIImage(named: "pay-now-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    lazy var buttonCornerRadius: CGFloat? = {
        return 4.0
    }()
    
    lazy var buttonColor: UIColor? = {
        switch paymentMethodTokenizationViewModel.config.type {
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
        case .xfers:
            return UIColor(red: 148.0/255, green: 31.0/255, blue: 127.0/255, alpha: 1.0)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    lazy var buttonTitleColor: UIColor? = {
        switch paymentMethodTokenizationViewModel.config.type {
        case .adyenAlipay,
                .adyenBlik,
                .adyenGiropay,
                .adyenInterac,
                .adyenMobilePay,
                .adyenPayTrail,
                .adyenTrustly,
                .adyenTwint,
                .adyenVipps,
                .atome,
                .buckarooBancontact,
                .buckarooEps,
                .buckarooIdeal,
                .buckarooGiropay,
                .buckarooSofort,
                .hoolah,
                .klarna,
                .mollieBankcontact,
                .mollieIdeal,
                .payNLBancontact,
                .payNLGiropay,
                .payNLIdeal,
                .payNLPayconiq,
                .payPal,
                .primerTestPayPal,
                .primerTestKlarna,
                .primerTestSofort,
                .xfers:
            return nil
        case .apaya,
                .paymentCard:
            return theme.paymentMethodButton.text.color
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    lazy var buttonBorderWidth: CGFloat = {
        switch paymentMethodTokenizationViewModel.config.type {
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
                .primerTestSofort:
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
    }()
    
    lazy var buttonBorderColor: UIColor? = {
        switch paymentMethodTokenizationViewModel.config.type {
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
                .xfers:
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
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    var buttonTintColor: UIColor? {
        switch paymentMethodTokenizationViewModel.config.type {
        case .adyenAlipay,
                .adyenBlik,
                .adyenDotPay,
                .atome,
                .buckarooBancontact,
                .buckarooEps,
                .buckarooIdeal,
                .buckarooGiropay,
                .buckarooSofort,
                .hoolah,
                .mollieIdeal,
                .payNLGiropay,
                .payNLIdeal,
                .payNLPayconiq,
                .adyenSofort,
                .adyenMobilePay,
                .adyenVipps,
                .adyenInterac,
                .adyenPayTrail,
                .primerTestSofort:
            return .white
        case .adyenIDeal,
                .adyenTrustly,
                .klarna,
                .primerTestKlarna:
            return .black
        case .adyenGiropay,
                .adyenTwint,
                .payPal,
                .primerTestPayPal:
            return nil
        case .apaya,
                .paymentCard:
            return theme.paymentMethodButton.text.color
        case .applePay,
                .xfers:
            return .white
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }
    
    var paymentMethodButton: PrimerButton {
        let customPaddingSettingsCard: [PrimerPaymentMethodType] = [.paymentCard, .coinbase]
        
        let paymentMethodButton = PrimerButton()
        paymentMethodButton.accessibilityIdentifier = paymentMethodTokenizationViewModel.config.type.rawValue
        paymentMethodButton.clipsToBounds = true
        paymentMethodButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        let imagePadding: CGFloat = 20
        let leftPadding = UILocalizableUtil.isRightToLeftLocale ? imagePadding : 0
        let defaultRightPadding = customPaddingSettingsCard.contains(paymentMethodTokenizationViewModel.config.type) ? imagePadding : 0
        let rightPadding = UILocalizableUtil.isRightToLeftLocale ? 0 : defaultRightPadding
        paymentMethodButton.imageEdgeInsets = UIEdgeInsets(top: 0,
                                                           left: leftPadding,
                                                           bottom: 0,
                                                           right: rightPadding)
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
        case .paymentCard:
            switch Primer.shared.intent {
            case .checkout:
                let viewModel: VaultCheckoutViewModelProtocol = DependencyContainer.resolve()
                buttonTitle = NSLocalizedString("primer-form-view-card-submit-button-text-checkout",
                                                tableName: nil,
                                                bundle: Bundle.primerResources,
                                                value: "Pay",
                                                comment: "Pay - Card Form View (Sumbit button text)") + " " + (viewModel.amountStringed ?? "")
                
            case .vault:
                buttonTitle = NSLocalizedString("primer-card-form-add-card",
                                                tableName: nil,
                                                bundle: Bundle.primerResources,
                                                value: "Add card",
                                                comment: "Add card - Card Form (Vault title text)")
                
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
            
        case .primerTestSofort,
                .primerTestKlarna,
                .primerTestPayPal:
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
            
        case .adyenBlik,
                .xfers:
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
