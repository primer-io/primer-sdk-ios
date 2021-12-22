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
    var paymentMethodButton: PrimerButton { get }
    var didStartTokenization: (() -> Void)? { get set }
    var completion: TokenizationCompletion? { get set }
    var paymentMethod: PaymentMethodToken? { get set }
    
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
    var completion: TokenizationCompletion? {
        didSet {
            
        }
    }
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
    
    lazy var buttonImage: UIImage? = {
        assert(true, "Should be overriden")
        return nil
    }()
    
    lazy var buttonColor: UIColor? = {
        assert(true, "Should be overriden")
        return UIColor.white
    }()
    
    lazy var buttonTitleColor: UIColor? = {
        assert(true, "Should be overriden")
        return UIColor.black
    }()
    
    lazy var buttonBorderWidth: CGFloat = {
        assert(true, "Should be overriden")
        return 0.0
    }()
    
    lazy var buttonBorderColor: UIColor? = {
        assert(true, "Should be overriden")
        return UIColor.black
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
    
    lazy var paymentMethodButton: PrimerButton = {
        let paymentMethodButton = PrimerButton()
        paymentMethodButton.accessibilityIdentifier = config.type.rawValue
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
    
    @objc
    func presentNativeUI() {
        assert(true, "Should be overriden")
    }
    
    func handleSuccessfulTokenizationFlow() {
        let sdkEvent = Analytics.Event(
            eventType: .sdkEvent,
            properties: SDKEventProperties(
                name: #function,
                params: [
                    "file": #file,
                    "class": "\(Self.self)",
                    "line": "\(#line)"
                ]))
        Analytics.Service.record(event: sdkEvent)
        
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
