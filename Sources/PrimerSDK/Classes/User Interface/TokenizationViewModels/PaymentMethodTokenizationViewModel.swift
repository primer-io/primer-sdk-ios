//
//  PaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 7/10/21.
//

import Foundation

typealias TokenizationCompletion = ((PaymentMethodToken?, Error?) -> Void)

internal protocol PaymentMethodTokenizationViewModelProtocol: NSObject, ResumeHandlerProtocol {
    init(config: PaymentMethodConfig)
    
    var config: PaymentMethodConfig { get set }
    var title: String { get }
    var position: Int { get set }
    var paymentMethodButton: PrimerButton { get }
    var didStartTokenization: (() -> Void)? { get set }
    var completion: TokenizationCompletion? { get set }
    var paymentMethod: PaymentMethodToken? { get set }
    
    func validate() throws
    func startTokenizationFlow()
    func handleSuccessfulTokenizationFlow()
    func handleFailedTokenizationFlow(error: Error)
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
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
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
    }
    
    lazy var title: String = {
        switch config.type {
        case .applePay:
            return "Apple Pay"
        case .payPal:
            return "PayPal"
        case .paymentCard:
            return "Payment Card"
        case .googlePay:
            return "Google Pay"
        case .goCardlessMandate:
            return "Go Cardless"
        case .klarna:
            return "Klarna"
        case .payNLIdeal:
            return "Pay NL Ideal"
        case .apaya:
            return "Apaya"
        case .hoolah:
            return "Hoolah"
        case .unknown:
            return "Unknown"
        }
    }()
    
    var position: Int = 0
    
    lazy var buttonTitle: String? = {
        switch config.type {
        case .paymentCard:
            return Primer.shared.flow.internalSessionFlow.vaulted
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
        
        case .goCardlessMandate:
            return NSLocalizedString("payment-method-type-go-cardless",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Bank account",
                                     comment: "Bank account - Payment Method Type (Go Cardless)")
        
        case .payNLIdeal:
            return nil
            
        case .apaya:
            return NSLocalizedString("payment-method-type-pay-by-mobile",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Pay by mobile",
                                     comment: "Pay by mobile - Payment By Mobile (Apaya)")
        case .hoolah:
            return nil
        
        case .applePay:
            return nil
        case .googlePay:
            return nil
        case .klarna:
            return nil
        case .payPal:
            return nil
        case .unknown:
            return nil
        }
    }()
    
    lazy var buttonImage: UIImage? = {
        switch config.type {
        case .applePay:
            return UIImage(named: "apple-pay-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .payPal:
            return UIImage(named: "paypal3", in: Bundle.primerResources, compatibleWith: nil)
        case .paymentCard:
            return UIImage(named: "creditCard", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .googlePay:
            return nil
        case .goCardlessMandate:
            return UIImage(named: "rightArrow", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .klarna:
            return UIImage(named: "klarna-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .payNLIdeal:
            return UIImage(named: "iDeal-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .apaya:
            return UIImage(named: "mobile", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .hoolah:
            return UIImage(named: "hoolah-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .unknown:
            return nil
        }
    }()
    
    lazy var buttonColor: UIColor? = {
        switch config.type {
        case .applePay:
            return .black
        case .payPal:
            return UIColor(red: 0.745, green: 0.894, blue: 0.996, alpha: 1)
        case .paymentCard:
            return .white
        case .googlePay:
            return nil
        case .goCardlessMandate:
            return .white
        case .klarna:
            return UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1.0)
        case .payNLIdeal:
            return UIColor(red: 204.0/255, green: 0.0, blue: 102.0/255, alpha: 1.0)
        case .apaya:
            return .white
        case .hoolah:
            return UIColor(red: 214.0/255, green: 55.0/255, blue: 39.0/255, alpha: 1.0)
        case .unknown:
            return nil
        }
    }()
    
    lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .paymentCard,
                .goCardlessMandate,
                .apaya,
                .unknown:
            return theme.colorTheme.text1
        case .applePay,
                .googlePay,
                .hoolah,
                .payNLIdeal,
                .payPal,
                .klarna:
            return nil
        }
    }()
    
    lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .paymentCard,
                .goCardlessMandate,
                .apaya,
                .unknown:
            return 1.0
        case .applePay,
                .googlePay,
                .hoolah,
                .payNLIdeal,
                .payPal,
                .klarna:
            return 0.0
        }
    }()
    
    lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .paymentCard,
                .goCardlessMandate,
                .apaya,
                .unknown:
            return theme.colorTheme.text1
        case .applePay,
                .googlePay,
                .hoolah,
                .payNLIdeal,
                .payPal,
                .klarna:
            return nil
        }
    }()
    
    lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .applePay,
                .hoolah,
                .payNLIdeal:
            return .white
        case .klarna:
            return .black
        case .paymentCard,
                .goCardlessMandate,
                .apaya:
            return theme.colorTheme.text1
        case .payPal,
                .googlePay,
                .unknown:
            return nil
        }
    }()
    
    lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    lazy var buttonCornerRadius: CGFloat? = {
        return 4.0
    }()
    
    lazy var paymentMethodButton: PrimerButton = {
        let paymentMethodButton = PrimerButton()
        paymentMethodButton.clipsToBounds = true
        paymentMethodButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        paymentMethodButton.imageEdgeInsets = UIEdgeInsets(top: -2, left: 0, bottom: 0, right: 10)
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
