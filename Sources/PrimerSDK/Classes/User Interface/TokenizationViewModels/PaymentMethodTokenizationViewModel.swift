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
    internal let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
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
        case .googlePay:
            return "Google Pay"
        case .goCardlessMandate:
            return "Go Cardless"
        case .unknown:
            return "Unknown"
        default:
            assert(true, "Shouldn't end up in here")
            return ""
        }
    }()
    
    var position: Int = 0
    
    lazy var buttonTitle: String? = {
        switch config.type {
        case .goCardlessMandate:
            return NSLocalizedString("payment-method-type-go-cardless",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Bank account",
                                     comment: "Bank account - Payment Method Type (Go Cardless)")
        case .googlePay:
            return nil
        case .unknown:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    lazy var buttonImage: UIImage? = {
        switch config.type {
        case .googlePay:
            return nil
        case .goCardlessMandate:
            return UIImage(named: "rightArrow", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .unknown:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    lazy var buttonColor: UIColor? = {
        switch config.type {
        case .googlePay:
            return nil
        case .goCardlessMandate:
            return .white
        case .unknown:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .goCardlessMandate:
            return theme.colorTheme.text1
        case .googlePay,
                .unknown:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .goCardlessMandate:
            return 1.0
        case .googlePay,
                .unknown:
            return 0.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .goCardlessMandate:
            return theme.colorTheme.text1
        case .googlePay,
                .unknown:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .goCardlessMandate:
            return theme.colorTheme.text1
        case .googlePay,
                .unknown:
            return nil
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
