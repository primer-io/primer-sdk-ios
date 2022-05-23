//
//  PaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 7/10/21.
//

#if canImport(UIKit)

import Foundation
import UIKit

typealias TokenizationCompletion = ((PaymentMethodToken?, Error?) -> Void)

internal protocol PaymentMethodTokenizationViewModelProtocol: NSObject, ResumeHandlerProtocol {
    init(config: PaymentMethodConfig)
    
    var config: PaymentMethodConfig { get set }
    var title: String { get }
    var surcharge: String? { get }
    var position: Int { get set }
    var imageName: String? { get }
    var logo: UIImage? { get }
    var squareLogo: UIImage? { get }
    var paymentMethodButton: PrimerButton { get }
    var didStartTokenization: (() -> Void)? { get set }
    var completion: TokenizationCompletion? { get set }
    var paymentMethod: PaymentMethodToken? { get set }
    
    func makeLogoImageView(withSize size: CGSize?) -> UIImageView?
    func makeSquareLogoImageView(withDimension dimension: CGFloat) -> UIImageView?
    
    func validate() throws
    func startTokenizationFlow()
    func handleSuccessfulTokenizationFlow()
    func handleFailedTokenizationFlow(error: Error)
    func presentNativeUI()
}

internal protocol ExternalPaymentMethodTokenizationViewModelProtocol {
    var willPresentExternalView: (() -> Void)? { get set }
    var didPresentExternalView: (() -> Void)? { get set }
    var willDismissExternalView: (() -> Void)? { get set }
    var didDismissExternalView: (() -> Void)? { get set }
}

class PaymentMethodTokenizationViewModel: NSObject, PaymentMethodTokenizationViewModelProtocol {
    
    var config: PaymentMethodConfig
    var completion: TokenizationCompletion?
    var paymentMethod: PaymentMethodToken?
    var didStartTokenization: (() -> Void)?
    internal let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    required init(config: PaymentMethodConfig) {
        self.config = config
        super.init()
    }
    
    func validate() throws {
        assert(true, "\(#function) needs to be overriden")
    }
    
    @objc
    func startTokenizationFlow() {
        didStartTokenization?()
        
        self.completion = { (tok, err) in
            if let err = err {
                self.handleFailedTokenizationFlow(error: err)
            } else {
                self.handleSuccessfulTokenizationFlow()
            }
        }
    }
    
    lazy var title: String = {
        switch config.type {
        case .googlePay:
            return "Google Pay"
        case .goCardlessMandate:
            return "Go Cardless"
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
            return NSLocalizedString("surcharge-additional-fee",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Additional fee may apply",
                                     comment: "Additional fee may apply - Surcharge (Label)")
        default:
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            guard let currency = settings.currency else { return nil }
            
            let state: AppStateProtocol = DependencyContainer.resolve()
            guard let availablePaymentMethods = state.primerConfiguration?.paymentMethods, !availablePaymentMethods.isEmpty else { return nil }
            
            guard let str = availablePaymentMethods.filter({ $0.type == config.type }).first?.surcharge?.toCurrencyString(currency: currency) else { return nil }
            
            return "+\(str)"
        }
    }()
    
    var position: Int = 0
    
    lazy var buttonTitle: String? = {
        assert(true, "Should be overriden")
        return nil
    }()
    
    lazy var originalImage: UIImage? = {
        assert(true, "Should be overriden")
        return nil
    }()
    
    lazy var buttonImage: UIImage? = {
        assert(true, "Should be overriden")
        return nil
    }()
    
    lazy var buttonColor: UIColor? = {
        assert(true, "Should be overriden")
        return nil
    }()
    
    lazy var buttonTitleColor: UIColor? = {
        assert(true, "Should be overriden")
        return nil
    }()
    
    lazy var buttonBorderWidth: CGFloat = {
        assert(true, "Should be overriden")
        return 0.0
    }()
    
    lazy var buttonBorderColor: UIColor? = {
        assert(true, "Should be overriden")
        return nil
    }()
    
    var buttonTintColor: UIColor? {
        assert(true, "Should be overriden")
        return nil
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
                .buckarooSofort:
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
        case .klarna:
            return "klarna"
        case .payNLPayconiq:
            return "payconiq"
        case .paymentCard:
            return "card"
        case .payPal:
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
        let customPaddingSettingsCard: [PaymentMethodConfigType] = [.paymentCard, .coinbase]
        
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
        paymentMethodButton.addTarget(self, action: #selector(startTokenizationFlow), for: .touchUpInside)
        return paymentMethodButton
    }()
    
    @objc
    func presentNativeUI() {
        assert(true, "Should be overriden")
    }
    
    func handleSuccessfulTokenizationFlow() {
        Primer.shared.primerRootVC?.handleSuccess()
    }
    
    func handleFailedTokenizationFlow(error: Error) {
        Primer.shared.primerRootVC?.handle(error: error)
    }
    
}

extension PaymentMethodTokenizationViewModel {
    func handle(error: Error) {
        assert(true, "\(self.self).\(#function) should be overriden")
    }
    
    func handle(newClientToken clientToken: String) {
        assert(true, "\(self.self).\(#function) should be overriden")
    }
    
    func handleSuccess() {
        assert(true, "\(self.self).\(#function) should be overriden")
    }
}

private extension UIColor {
    var hex: String? {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0

        let multiplier = CGFloat(255.999999)

        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return nil
        }

        if alpha == 1.0 {
            return String(
                format: "#%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier)
            )
        }
        else {
            return String(
                format: "#%02lX%02lX%02lX%02lX",
                Int(red * multiplier),
                Int(green * multiplier),
                Int(blue * multiplier),
                Int(alpha * multiplier)
            )
        }
    }
}

#endif
