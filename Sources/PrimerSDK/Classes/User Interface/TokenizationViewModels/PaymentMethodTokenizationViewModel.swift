//
//  PaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 7/10/21.
//

#if canImport(UIKit)

import Foundation
import UIKit

typealias TokenizationCompletion = ((PrimerPaymentMethodTokenData?, Error?) -> Void)
typealias PaymentCompletion = ((PrimerCheckoutData?, Error?) -> Void)

internal protocol PaymentMethodTokenizationViewModelProtocol: NSObject {
    init(config: PaymentMethodConfig)
    
    // UI
    var config: PaymentMethodConfig { get set }
    var title: String { get }
    var surcharge: String? { get }
    var position: Int { get set }
    var imageName: String? { get }
    var logo: UIImage? { get }
    var squareLogo: UIImage? { get }
    var paymentMethodButton: PrimerButton { get }
    
    // Events
    var didStartTokenization: (() -> Void)? { get set }
    var didFinishTokenization: ((Error?) -> Void)? { get set }
    var didStartPayment: (() -> Void)? { get set }
    var didFinishPayment: ((Error?) -> Void)? { get set }
    var willPresentPaymentMethodUI: (() -> Void)? { get set }
    var didPresentPaymentMethodUI: (() -> Void)? { get set }
    var willDismissPaymentMethodUI: (() -> Void)? { get set }
    var didDismissPaymentMethodUI: (() -> Void)? { get set }
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get set }
    var paymentCheckoutData: PrimerCheckoutData? { get set }
    var successMessage: String? { get set }
    
    func makeLogoImageView(withSize size: CGSize?) -> UIImageView?
    func makeSquareLogoImageView(withDimension dimension: CGFloat) -> UIImageView?
    
    func validate() throws
    func start()
    func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData>
    func startPaymentFlow(withPaymentMethodTokenData paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData?>
    func handleDecodedClientTokenIfNeeded(_ decodedClientToken: DecodedClientToken) -> Promise<String?>
    func handleResumeStepsBasedOnSDKSettings(resumeToken: String) -> Promise<PrimerCheckoutData?>
    func handleSuccessfulFlow()
    func handleFailureFlow(errorMessage: String?)
}

internal protocol SearchableItemsPaymentMethodTokenizationViewModelProtocol {
    func cancel()
    var tableView: UITableView { get set }
    var searchCountryTextField: PrimerSearchTextField { get set }
    var config: PaymentMethodConfig { get set }
}

class PaymentMethodTokenizationViewModel: NSObject, PaymentMethodTokenizationViewModelProtocol {

    var config: PaymentMethodConfig
    
    // Events
    var didStartTokenization: (() -> Void)?
    var didFinishTokenization: ((Error?) -> Void)?
    var didStartPayment: (() -> Void)?
    var didFinishPayment: ((Error?) -> Void)?
    var willPresentPaymentMethodUI: (() -> Void)?
    var didPresentPaymentMethodUI: (() -> Void)?
    var willDismissPaymentMethodUI: (() -> Void)?
    var didDismissPaymentMethodUI: (() -> Void)?
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    var paymentCheckoutData: PrimerCheckoutData?
    var successMessage: String?
    
    var resumePaymentId: String?
    let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    lazy var title: String = {
        switch config.type {
        case .adyenAlipay:
            return "Adyen Ali Pay"
        case .adyenDotPay:
            return "Dot Pay"
        case .adyenGiropay:
            return "Giropay"
        case .adyenIDeal:
            return "iDeal"
        case .apaya:
            return "Apaya"
        case .applePay:
            return "Apple Pay"
        case .atome:
            return "Atome"
        case .buckarooBancontact:
            return "Buckaroo Bancontact"
        case .buckarooEps:
            return "Buckaroo EPS"
        case .buckarooGiropay:
            return "Buckaroo Giropay"
        case .buckarooIdeal:
            return "Buckaroo iDeal"
        case .buckarooSofort:
            return "Buckaroo Sofort"
        case .goCardlessMandate:
            return "Go Cardless"
        case .googlePay:
            return "Google Pay"
        case .hoolah:
            return "Hoolah"
        case .adyenInterac:
            return "Interac"
        case .klarna,
                .primerTestKlarna:
            return "Klarna"
        case .mollieBankcontact:
            return "Mollie Bancontact"
        case .mollieIdeal:
            return "Mollie iDeal"
        case .paymentCard:
            return "Payment Card"
        case .payNLBancontact:
            return "Pay NL Bancontact"
        case .payNLGiropay:
            return "Pay NL Giropay"
        case .payNLIdeal:
            return "Pay NL Ideal"
        case .payNLPayconiq:
            return "Pay NL Payconiq"
        case .adyenSofort,
                .primerTestSofort:
            return "Sofort"
        case .adyenTwint:
            return "Twint"
        case .adyenTrustly:
            return "Trustly"
        case .adyenMobilePay:
            return "Mobile Pay"
        case .adyenVipps:
            return "Vipps"
        case .adyenPayTrail:
            return "Pay Trail"
        case .payPal,
                .primerTestPayPal:
            return "PayPal"
        case .xfers:
            return "XFers"
        case .other:
            return "Other"
            
        default:
            assert(true, "Shouldn't end up in here")
            return ""
        }
    }()
    
    lazy var surcharge: String? = {
        switch config.type {
        case .paymentCard:
            return Strings.CardFormView.additionalFeesTitle
        default:
            guard let currency = AppState.current.currency else { return nil }
            guard let availablePaymentMethods = AppState.current.apiConfiguration?.paymentMethods, !availablePaymentMethods.isEmpty else { return nil }
            guard let str = availablePaymentMethods.filter({ $0.type == config.type }).first?.surcharge?.toCurrencyString(currency: currency) else { return nil }
            return "+\(str)"
        }
    }()
    
    var position: Int = 0
    
    lazy var buttonTitle: String? = {
        switch config.type {
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
            return Strings.PaymentButton.payByMobile
            
        case .paymentCard:
            return Primer.shared.intent == .vault
            ? Strings.PrimerCardFormView.addCardButtonTitle : Strings.VaultPaymentMethodViewContent.payWithCard
            
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    lazy var originalImage: UIImage? = {
        assert(true, "Should be overriden")
        return nil
    }()
    
    lazy var buttonImage: UIImage? = {
        switch config.type {
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
    
    lazy var buttonColor: UIColor? = {
        switch config.type {
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
        switch config.type {
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
        switch config.type {
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
        switch config.type {
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
        switch config.type {
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
    
    lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    lazy var buttonCornerRadius: CGFloat? = {
        return 4.0
    }()
    
    lazy var imageName: String? = {
        switch self.config.type {
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
    
    lazy var logo: UIImage? = {
        guard let imageName = imageName else { return nil }
        return UIImage(named: "\(imageName)-logo", in: Bundle.primerResources, compatibleWith: nil)
    }()
    
    lazy var squareLogo: UIImage? = {
        guard let imageName = imageName else { return nil }
        // In case we don't have a square icon, we show the icon image
        let imageLogoSquare = UIImage(named: "\(imageName)-logo-square", in: Bundle.primerResources, compatibleWith: nil)
        let imageIcon = UIImage(named: "\(imageName)-icon", in: Bundle.primerResources, compatibleWith: nil)
        return imageLogoSquare ?? imageIcon
    }()
    
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
    
    func makeSquareLogoImageView(withDimension dimension: CGFloat) -> UIImageView? {
        guard let squareLogo = self.squareLogo else { return nil }
        let imgView = UIImageView()
        imgView.image = squareLogo
        imgView.contentMode = .scaleAspectFit
        imgView.translatesAutoresizingMaskIntoConstraints = false
        imgView.heightAnchor.constraint(equalToConstant: dimension).isActive = true
        imgView.widthAnchor.constraint(equalToConstant: dimension).isActive = true
        return imgView
    }
    
    lazy var paymentMethodButton: PrimerButton = {
        
        // TODO: Find better way to handle it. Perhaps a new property for each config?
        let customPaddingSettingsCard: [PrimerPaymentMethodType] = [.paymentCard, .coinbase]
        
        let paymentMethodButton = PrimerButton()
        paymentMethodButton.accessibilityIdentifier = config.type.rawValue
        paymentMethodButton.clipsToBounds = true
        paymentMethodButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        let imagePadding: CGFloat = 20
        let leftPadding = UILocalizableUtil.isRightToLeftLocale ? imagePadding : 0
        let defaultRightPadding = customPaddingSettingsCard.contains(config.type) ? imagePadding : 0
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
        paymentMethodButton.setTitle(buttonTitle, for: .normal)
        paymentMethodButton.setImage(buttonImage, for: .normal)
        paymentMethodButton.setTitleColor(buttonTitleColor, for: .normal)
        paymentMethodButton.tintColor = buttonTintColor
        paymentMethodButton.layer.borderWidth = buttonBorderWidth
        paymentMethodButton.layer.borderColor = buttonBorderColor?.cgColor
        paymentMethodButton.addTarget(self, action: #selector(start), for: .touchUpInside)
        if config.type == .paymentCard {
            paymentMethodButton.isUserInteractionEnabled = true
        }
        return paymentMethodButton
    }()
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    required init(config: PaymentMethodConfig) {
        self.config = config
        super.init()
    }
    
    @objc
    func validate() throws {
        fatalError("\(#function) must be overriden")
    }
    
    func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
        fatalError("\(#function) must be overriden")
    }
    
    func handleDecodedClientTokenIfNeeded(_ decodedClientToken: DecodedClientToken) -> Promise<String?> {
        fatalError("\(#function) must be overriden")
    }
}

#endif
