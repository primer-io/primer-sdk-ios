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
    var resumePaymentId: String?
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
        
    @objc func startTokenizationFlow() {
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
        let paymentMethodButton = PrimerButton()
        paymentMethodButton.accessibilityIdentifier = config.type.rawValue
        paymentMethodButton.clipsToBounds = true
        paymentMethodButton.heightAnchor.constraint(equalToConstant: 45).isActive = true
        let imagePadding: CGFloat = 20
        let leftPadding = UILocalizableUtil.isRightToLeftLocale ? imagePadding : 0
        let defaultRightPadding = config.type == .paymentCard ? imagePadding : 0
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
    
    internal func handleErrorBasedOnSDKSettings(_ error: Error, isOnResumeFlow: Bool = false) {
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        if settings.isManualPaymentHandlingEnabled {
            if isOnResumeFlow {
                PrimerDelegateProxy.onResumeError(error)
            }
            handle(error: error)
        } else {
            PrimerDelegateProxy.primerDidFailWithError(error, data: nil, decisionHandler: { errorDecision in
                if let errorMessage = errorDecision?.additionalInfo?[.message] as? String {
                    let merchantError = PrimerError.merchantError(message: errorMessage, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    self.handle(error: merchantError)
                } else {
                    self.handle(error: emptyDescriptionError)
                }
            })
        }
    }
}

extension PaymentMethodTokenizationViewModel {
    
    @objc func executeCompletionAndNullifyAfter(error: Error? = nil) {
        self.completion?(nil, error)
        self.completion = nil
    }
    
    func validateReturningPromise() -> Promise<Void> {
        return Promise { seal in
            do {
                try self.validate()
                seal.fulfill()
            } catch {
                seal.reject(error)
            }
        }
    }
}

extension PaymentMethodTokenizationViewModel {
    
    internal func handleContinuePaymentFlowWithPaymentMethod(_ paymentMethod: PaymentMethodToken) {
                
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if Primer.shared.flow.internalSessionFlow.vaulted {
            PrimerDelegateProxy.tokenAddedToVault(paymentMethod)
            self.handleSuccess()
        } else if settings.isManualPaymentHandlingEnabled {
            
            PrimerDelegateProxy.onTokenizeSuccess(paymentMethod, resumeHandler: self)
            PrimerDelegateProxy.onTokenizeSuccess(paymentMethod, { err in
                if let err = err {
                    self.handleFailedTokenizationFlow(error: err)
                } else {
                    self.handleSuccessfulTokenizationFlow()
                }
            })

        } else {
                        
            guard let paymentMethodTokenString = paymentMethod.token else {
                
                DispatchQueue.main.async {
                    let paymentMethodTokenError = PrimerError.invalidValue(key: "resumePaymentId", value: "Payment method token not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: paymentMethodTokenError)
                    self.handleErrorBasedOnSDKSettings(paymentMethodTokenError)
                }
                
                return
            }
            
            firstly {
                self.handleCreatePaymentEvent(paymentMethodTokenString)
            }
            .done { paymentResponse -> Void in
                
                guard let paymentResponse = paymentResponse else {
                    return
                }

                self.resumePaymentId = paymentResponse.id
                
                if paymentResponse.status == .pending, let requiredAction = paymentResponse.requiredAction {
                    self.handle(newClientToken: requiredAction.clientToken)
                } else {
                    let checkoutData = CheckoutData(payment: CheckoutDataPayment(from: paymentResponse))
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                    self.handleSuccess()
                }
            }
            .catch { error in
                self.handleErrorBasedOnSDKSettings(error)
            }
        }
    }
        
    // Raise Primer will create Payment event
    
    internal func handlePrimerWillCreatePaymentEvent(_ paymentMethodData: PaymentMethodData) -> Promise<Void> {
        return Promise { seal in
            let checkoutPaymentMethodType = CheckoutPaymentMethodType(type: paymentMethodData.type.rawValue)
            let checkoutPaymentMethodData = CheckoutPaymentMethodData(type: checkoutPaymentMethodType)
            PrimerDelegateProxy.primerWillCreatePaymentWithData(checkoutPaymentMethodData, decisionHandler: { paymentCreationDecision in
                
                guard paymentCreationDecision?.type != .abort else {
                    let message = paymentCreationDecision?.additionalInfo?[.message] as? String ?? ""
                    let error = PrimerError.generic(message: message, userInfo: nil)
                    seal.reject(error)
                    return
                }
                
                if let modifiedClientToken = paymentCreationDecision?.additionalInfo?[.clientToken] as? RawJWTToken {
                    ClientTokenService.storeClientToken(modifiedClientToken) { error in
                        guard error == nil else {
                            seal.reject(error!)
                            return
                        }
                        seal.fulfill(())
                    }
                } else {
                    seal.fulfill(())
                }
            })
        }
    }

    // Create payment with Payment method token

    private func handleCreatePaymentEvent(_ paymentMethodData: String) -> Promise<Payment.Response?> {
        
        return Promise { seal in
        
            let createResumePaymentService: CreateResumePaymentServiceProtocol = DependencyContainer.resolve()
            createResumePaymentService.createPayment(paymentRequest: Payment.CreateRequest(token: paymentMethodData)) { paymentResponse, error in
                
                guard error == nil else {
                    seal.reject(error!)
                    return
                }
                
                guard let status = paymentResponse?.status, status != .failed else {
                    seal.reject(PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]))
                    return
                }
                
                if let paymentFailureReason = paymentResponse?.paymentFailureReason,
                let paymentErrorCode = PaymentErrorCode(rawValue: paymentFailureReason),
                   let error = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                    seal.reject(error)
                    return
                }
                                
                seal.fulfill(paymentResponse)
            }
        }
    }
    
    // Resume payment with Resume payment ID
    
    private func handleResumePaymentEvent(_ resumePaymentId: String, resumeToken: String) -> Promise<Payment.Response?> {
        
        return Promise { seal in
            
            let createResumePaymentService: CreateResumePaymentServiceProtocol = DependencyContainer.resolve()
            createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId, paymentResumeRequest: Payment.ResumeRequest(token: resumeToken)) { paymentResponse, error in
                
                guard error == nil else {
                    seal.reject(error!)
                    return
                }
                
                guard let status = paymentResponse?.status, status != .failed else {
                    seal.reject(PrimerError.paymentFailed(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]))
                    return
                }
                
                if let paymentFailureReason = paymentResponse?.paymentFailureReason,
                let paymentErrorCode = PaymentErrorCode(rawValue: paymentFailureReason),
                   let error = PrimerError.simplifiedErrorFromErrorID(paymentErrorCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"]) {
                    seal.reject(error)
                    return
                }
                                
                seal.fulfill(paymentResponse)
            }
        }
    }
}

extension PaymentMethodTokenizationViewModel {
    
    internal func handleResumeStepsBasedOnSDKSettings(resumeToken: String) {
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if settings.isManualPaymentHandlingEnabled {
            
            PrimerDelegateProxy.onResumeSuccess(resumeToken, resumeHandler: self)
            
        } else {
            
            guard let resumePaymentId = self.resumePaymentId else {
                
                DispatchQueue.main.async {
                    let resumePaymentIdError = PrimerError.invalidValue(key: "resumePaymentId", value: "Resume Payment ID not valid", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: resumePaymentIdError)
                    self.handleErrorBasedOnSDKSettings(resumePaymentIdError, isOnResumeFlow: true)
                }
                
                return
            }
            
            firstly {
                self.handleResumePaymentEvent(resumePaymentId, resumeToken: resumeToken)
            }
            .done { paymentResponse -> Void in
                
                guard let paymentResponse = paymentResponse else {
                    return
                }

                if paymentResponse.status == .pending, let requiredAction = paymentResponse.requiredAction {
                    self.handle(newClientToken: requiredAction.clientToken)
                } else {
                    let checkoutData = CheckoutData(payment: CheckoutDataPayment(from: paymentResponse))
                    PrimerDelegateProxy.primerDidCompleteCheckoutWithData(checkoutData)
                    self.handleSuccess()
                }
            }
            .catch { error in
                self.handleErrorBasedOnSDKSettings(error)
            }
        }
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

#endif
