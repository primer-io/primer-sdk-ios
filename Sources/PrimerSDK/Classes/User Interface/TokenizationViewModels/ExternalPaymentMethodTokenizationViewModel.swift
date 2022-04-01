//
//  AsyncPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 11/10/21.
//

#if canImport(UIKit)

import Foundation
import SafariServices
import UIKit

class ExternalPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel, ExternalPaymentMethodTokenizationViewModelProtocol {
    
    private lazy var _title: String = {
        switch config.type {
        case .adyenAlipay:
            return "Adyen Ali Pay"
        case .adyenGiropay:
            return "Giropay"
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
        case .hoolah:
            return "Hoolah"
        case .adyenInterac:
            return "Interac"
        case .mollieBankcontact:
            return "Mollie Bancontact"
        case .mollieIdeal:
            return "Mollie iDeal"
        case .payNLBancontact:
            return "Pay NL Bancontact"
        case .payNLGiropay:
            return "Pay NL Giropay"
        case .payNLIdeal:
            return "Pay NL Ideal"
        case .payNLPayconiq:
            return "Pay NL Payconiq"
        case .adyenSofort:
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
        default:
            assert(true, "Shouldn't end up in here")
            return ""
        }
    }()
    override var title: String {
        get { return _title }
        set { _title = newValue }
    }
    
    private lazy var _buttonTitle: String? = {
        switch config.type {
        case .adyenAlipay,
                .adyenGiropay,
                .atome,
                .buckarooBancontact,
                .buckarooEps,
                .buckarooGiropay,
                .buckarooIdeal,
                .buckarooSofort,
                .hoolah,
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
                .adyenPayTrail:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonTitle: String? {
        get { return _buttonTitle }
        set { _buttonTitle = newValue }
    }
    
    private lazy var _buttonImage: UIImage? = {
        switch config.type {
        case .adyenAlipay:
            return UIImage(named: "alipay-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
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
                .adyenSofort:
            return UIImage(named: "sofort-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .adyenTrustly:
            return UIImage(named: "trustly-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenTwint:
            return UIImage(named: "twint-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .adyenVipps:
            return UIImage(named: "vipps-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonImage: UIImage? {
        get { return _buttonImage }
        set { _buttonImage = newValue }
    }
    
    private lazy var _buttonColor: UIColor? = {
        switch config.type {
        case .adyenAlipay:
            return UIColor(red: 49.0/255, green: 177.0/255, blue: 240.0/255, alpha: 1.0)
        case .adyenGiropay,
                .buckarooGiropay:
            return UIColor(red: 0, green: 2.0/255, blue: 104.0/255, alpha: 1.0)
        case .adyenInterac:
            return UIColor(red: 254.0/255, green: 185.0/255, blue: 43.0/255, alpha: 1.0)
        case .adyenSofort,
                .buckarooSofort:
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
        case .atome:
            return UIColor(red: 240.0/255, green: 255.0/255, blue: 95.0/255, alpha: 1.0)
        case .buckarooEps:
            return .white
        case .hoolah:
            return UIColor(red: 214.0/255, green: 55.0/255, blue: 39.0/255, alpha: 1.0)
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
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonColor: UIColor? {
        get { return _buttonColor }
        set { _buttonColor = newValue }
    }
    
    private lazy var _buttonTitleColor: UIColor? = {
        switch config.type {
        case .adyenAlipay,
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
                .mollieBankcontact,
                .mollieIdeal,
                .payNLBancontact,
                .payNLGiropay,
                .payNLIdeal,
                .payNLPayconiq:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonTitleColor: UIColor? {
        get { return _buttonTitleColor }
        set { _buttonTitleColor = newValue }
    }
    
    private lazy var _buttonBorderWidth: CGFloat = {
        switch config.type {
        case .adyenAlipay,
                .adyenGiropay,
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
                .mollieIdeal,
                .payNLGiropay,
                .payNLIdeal,
                .payNLPayconiq:
            return 0.0
        case .buckarooBancontact,
                .buckarooEps,
                .mollieBankcontact,
                .payNLBancontact:
            return 1.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    override var buttonBorderWidth: CGFloat {
        get { return _buttonBorderWidth }
        set { _buttonBorderWidth = newValue }
    }
    
    private lazy var _buttonBorderColor: UIColor? = {
        switch config.type {
        case .adyenAlipay,
                .adyenGiropay,
                .adyenMobilePay,
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
                .mollieIdeal,
                .payNLGiropay,
                .payNLIdeal,
                .payNLPayconiq:
            return nil
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
    override var buttonBorderColor: UIColor? {
        get { return _buttonBorderColor }
        set { _buttonBorderColor = newValue }
    }
    
    private lazy var _buttonTintColor: UIColor? = {
        switch config.type {
        case .adyenAlipay,
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
                .adyenPayTrail:
            return .white
        case .adyenTrustly:
            return .black
        case .adyenGiropay,
                .adyenTwint:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonTintColor: UIColor? {
        get { return _buttonTintColor }
        set { _buttonTintColor = newValue }
    }
    
    var resumePaymentId: String?
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?
    var webViewController: SFSafariViewController?
    /**
     This completion handler will return an authorization token, which must be returned to the merchant to resume the payment. **webViewCompletion**
     must be set before presenting the webview and nullified once polling returns a result. At the same time the webview should be dismissed.
     */
    var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    var onResumeTokenCompletion: ((_ paymentMethod: PaymentMethodToken?, _ error: Error?) -> Void)?
    var onClientToken: ((_ clientToken: String?, _ err: Error?) -> Void)?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        if ClientTokenService.decodedClientToken?.isValid != true {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
    }
    
    @objc
    override func startTokenizationFlow() {
        DispatchQueue.main.async {
            UIApplication.shared.beginIgnoringInteractionEvents()
        }
        
        super.startTokenizationFlow()
        
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type.rawValue,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .paymentMethodPopup))
        Analytics.Service.record(event: event)
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
        
        if PrimerDelegateProxy.isClientSessionActionsImplemented {
            let params: [String: Any] = ["paymentMethodType": config.type.rawValue]
            ClientSession.Action.selectPaymentMethod(resumeHandler: self, withParameters: params)
        } else {
            continueTokenizationFlow()
        }
    }
    
    fileprivate func continueTokenizationFlow() {
        do {
            try self.validate()
        } catch {
            DispatchQueue.main.async {
                UIApplication.shared.endIgnoringInteractionEvents()
                PrimerDelegateProxy.checkoutFailed(with: error)
                self.handleFailedTokenizationFlow(error: error)
                self.completion?(nil, error)
            }
            return
        }
        
        firstly {
            self.tokenize()
        }
        .then { tmpPaymentMethod -> Promise<PaymentMethodToken> in
            self.paymentMethod = tmpPaymentMethod
            return self.continueTokenizationFlow(for: tmpPaymentMethod)
        }
        .done { paymentMethod in
            self.paymentMethod = paymentMethod
            
            DispatchQueue.main.async {
                self.completion?(self.paymentMethod, nil)
            }
        }
        .ensure { [unowned self] in
            DispatchQueue.main.async {
                UIApplication.shared.endIgnoringInteractionEvents()
            }
            DispatchQueue.main.async {
                self.willDismissExternalView?()
                self.webViewController?.dismiss(animated: true, completion: {
                    self.didDismissExternalView?()
                })
            }
            
            self.willPresentExternalView = nil
            self.didPresentExternalView = nil
            self.willDismissExternalView = nil
            self.didDismissExternalView = nil
            self.webViewController = nil
            self.webViewCompletion = nil
            self.onResumeTokenCompletion = nil
            self.onClientToken = nil
        }
        .catch { err in
            DispatchQueue.main.async {
                PrimerDelegateProxy.checkoutFailed(with: err)
                self.handleFailedTokenizationFlow(error: err)
            }
        }
    }
    
    internal func continueTokenizationFlow(for tmpPaymentMethod: PaymentMethodToken) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            var pollingURLs: PollingURLs!
            
            // Fallback when no **requiredAction** is returned.
            self.onResumeTokenCompletion = { (paymentMethod, err) in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethod = paymentMethod {
                    seal.fulfill(paymentMethod)
                } else {
                    assert(true, "Should have received one parameter")
                }
            }
            
            firstly {
                return self.fetchPollingURLs(for: tmpPaymentMethod)
            }
            .then { pollingURLsResponse -> Promise<Void> in
                pollingURLs = pollingURLsResponse
                
                guard let redirectUrl = pollingURLs.redirectUrl else {
                    let err = PrimerError.invalidValue(key: "redirectUrl", value: pollingURLs.redirectUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    throw err
                }
                
                DispatchQueue.main.async {
                    UIApplication.shared.endIgnoringInteractionEvents()
                }
                
                return self.presentAsyncPaymentMethod(with: redirectUrl)
            }
            .then { () -> Promise<String> in
                guard let statusUrl = pollingURLs.statusUrl else {
                    let err = PrimerError.invalidValue(key: "statusUrl", value: pollingURLs.redirectUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    throw err
                }
                
                return self.startPolling(on: statusUrl)
            }
            .then { resumeToken -> Promise<PaymentMethodToken> in
                DispatchQueue.main.async {
                    Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
                    
                    self.willDismissExternalView?()
                    self.webViewController?.dismiss(animated: true, completion: {
                        self.didDismissExternalView?()
                    })
                }
                return self.passResumeToken(resumeToken)
            }
            .done { paymentMethod in
                seal.fulfill(paymentMethod)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    fileprivate func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            guard let configId = config.id else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            var sessionInfo: AsyncPaymentMethodOptions.SessionInfo?
            if let localeCode = settings.localeData.localeCode {
                sessionInfo = AsyncPaymentMethodOptions.SessionInfo(locale: localeCode)
            }
            
            let request = AsyncPaymentMethodTokenizationRequest(
                paymentInstrument: AsyncPaymentMethodOptions(
                    paymentMethodType: config.type,
                    paymentMethodConfigId: configId,
                    sessionInfo: sessionInfo))
            
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            firstly {
                tokenizationService.tokenize(request: request)
            }
            .done{ paymentMethod in
                seal.fulfill(paymentMethod)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    internal func fetchPollingURLs(for paymentMethod: PaymentMethodToken) -> Promise<PollingURLs> {
        return Promise { seal in
            self.onClientToken = { (clientToken, error) in
                
                guard error == nil else {
                    seal.reject(error!)
                    return
                }
                
                if let clientToken = clientToken {
                    ClientTokenService.storeClientToken(clientToken) { error in
                        guard error == nil else {
                            seal.reject(error!)
                            return
                        }

                        if let decodedClientToken = ClientTokenService.decodedClientToken,
                            let redirectUrl = decodedClientToken.redirectUrl,
                            let statusUrl = decodedClientToken.statusUrl,
                            decodedClientToken.intent != nil {
                            seal.fulfill(PollingURLs(status: statusUrl, redirect: redirectUrl, complete: nil))
                            return
                        }
                    }
                } else {
                    let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    seal.reject(error)
                    return
                }
            }
            
            DispatchQueue.main.async {
                self.handleContinuePaymentFlowWithPaymentMethod(paymentMethod)
            }
        }
    }
    
    internal func presentAsyncPaymentMethod(with url: URL) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.willPresentExternalView?()
                
                self.webViewCompletion = { (id, err) in
                    if let err = err {
                        seal.reject(err)
                    }
                }
                
                self.webViewController = SFSafariViewController(url: url)
                self.webViewController?.delegate = self
                
                self.willPresentExternalView?()
                Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: {
                    DispatchQueue.main.async {
                        PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutPaymentMethodPresented()
                        self.didPresentExternalView?()
                        seal.fulfill(())
                    }
                })
            }
        }
    }
    
    internal func startPolling(on url: URL) -> Promise<String> {
        return Promise { seal in
            self.startPolling(on: url) { (id, err) in
                if let err = err {
                    seal.reject(err)
                } else if let id = id {
                    seal.fulfill(id)
                } else {
                    assert(true, "Should have received one parameter")
                }
            }
        }
    }
    
    fileprivate func startPolling(on url: URL, completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.poll(clientToken: ClientTokenService.decodedClientToken, url: url.absoluteString) { result in
            if self.webViewCompletion == nil {
                let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                completion(nil, err)
                return
            }
            
            switch result {
            case .success(let res):
                if res.status == .pending {
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                        self.startPolling(on: url, completion: completion)
                    }
                } else if res.status == .complete {
                    completion(res.id, nil)
                } else {
                    let err = PrimerError.generic(message: "Should never end up here", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                }
            case .failure(let err):
                ErrorHandler.handle(error: err)
                // Retry
                Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                    self.startPolling(on: url, completion: completion)
                }
            }
        }
    }
    
    internal func passResumeToken(_ resumeToken: String) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            
            self.onResumeTokenCompletion = { (paymentMethod, err) in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethod = paymentMethod {
                    seal.fulfill(paymentMethod)
                } else {
                    assert(true, "Should have received one parameter")
                }
            }
            
            DispatchQueue.main.async {
                self.handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
            }
        }
    }
}

extension ExternalPaymentMethodTokenizationViewModel {
    
    private func handleResumeStepsBasedOnSDKSettings(resumeToken: String) {
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if settings.isManualPaymentHandlingEnabled {
            PrimerDelegateProxy.onResumeSuccess(resumeToken, resumeHandler: self)
        } else {
            
            // Resume payment with Payment method token
                            
            guard let resumePaymentId = self.resumePaymentId else {
                DispatchQueue.main.async {
                    // TODO: Raise appropriate error
                }
                return
            }
            
            let createResumePaymentService: CreateResumePaymentServiceProtocol = DependencyContainer.resolve()
            createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId, paymentResumeRequest: Payment.ResumeRequest(token: resumeToken)) { paymentResponse, error in
                
                guard let paymentResponse = paymentResponse,
                      let paymentResponseDict = try? paymentResponse.asDictionary(),
                      error == nil else {
                    self.handleErrorBasedOnSDKSettings(error!)
                    return
                }
                
                if paymentResponse.status == .pending, let requiredAction = paymentResponse.requiredAction {
                    Primer.shared.delegate?.onPaymentPending?(paymentResponseDict)
                    self.handle(newClientToken: requiredAction.clientToken)
                } else {
                    Primer.shared.delegate?.checkoutDidCompleteWithPayment?(paymentResponseDict)
                    self.handleSuccess()
                }
            }
        }
    }
}

extension ExternalPaymentMethodTokenizationViewModel {
    
    private func handleContinuePaymentFlowWithPaymentMethod(_ paymentMethod: PaymentMethodToken) {
                
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if settings.isManualPaymentHandlingEnabled {
            
            PrimerDelegateProxy.onTokenizeSuccess(paymentMethod, resumeHandler: self)
            
        } else {
                        
            guard let paymentMethodTokenString = paymentMethod.token else {
                
                DispatchQueue.main.async {
                    // TODO: Raise appropriate error
                }
                return
            }
            
            // Raise "payment creation started" event
            
            Primer.shared.delegate?.onPaymentWillCreate?(paymentMethodTokenString)
            
            // Create payment with Payment method token

            let createResumePaymentService: CreateResumePaymentServiceProtocol = DependencyContainer.resolve()
            createResumePaymentService.createPayment(paymentRequest: Payment.CreateRequest(token: paymentMethodTokenString)) { paymentResponse, error in
                
                guard let paymentResponse = paymentResponse,
                      let paymentResponseDict = try? paymentResponse.asDictionary(),
                      error == nil else {
                    self.handleErrorBasedOnSDKSettings(error!)
                    return
                }

                self.resumePaymentId = paymentResponse.id

                if paymentResponse.status == .pending, let requiredAction = paymentResponse.requiredAction {
                    Primer.shared.delegate?.onPaymentPending?(paymentResponseDict)
                    self.handle(newClientToken: requiredAction.clientToken)
                } else {
                    Primer.shared.delegate?.checkoutDidCompleteWithPayment?(paymentResponseDict)
                    self.handleSuccess()
                }
            }
        }
    }

    
}

extension ExternalPaymentMethodTokenizationViewModel: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion = webViewCompletion {
            // Cancelled
            let err = PrimerError.cancelled(paymentMethodType: config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            webViewCompletion(nil, err)
        }
        
        webViewCompletion = nil
    }
    
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        if didLoadSuccessfully {
            self.didPresentExternalView?()
        }
    }
    
}

extension ExternalPaymentMethodTokenizationViewModel {
    
    override func handle(error: Error) {
        DispatchQueue.main.async {
            ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
        }
        
        // onClientToken will be created when we're awaiting a new client token from the developer
        onClientToken?(nil, error)
        onClientToken = nil
        // onResumeTokenCompletion will be created when we're awaiting the payment response
        onResumeTokenCompletion?(nil, error)
        onResumeTokenCompletion = nil
    }
    
    override func handle(newClientToken clientToken: String) {
        
        firstly {
            ClientTokenService.storeClientToken(clientToken)
        }
        .then{ () -> Promise<Void> in
            let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            return configService.fetchConfig()
        }
        .done { [weak self] in
            
            let decodedClientToken = ClientTokenService.decodedClientToken!
            
            if decodedClientToken.intent?.contains("_REDIRECTION") == true {
                self?.onClientToken?(clientToken, nil)
                self?.onClientToken = nil
                
            } else {
                // intent = "CHECKOUT"
                // if decodedClientToken.intent == RequiredActionName.checkout.rawValue
                let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                
                firstly {
                    configService.fetchConfig()
                }
                .done {
                    self?.continueTokenizationFlow()
                }
                .catch { error in
                    DispatchQueue.main.async {
                        self.handleErrorBasedOnSDKSettings(error)
                    }
                }
            }
        }
        .catch { error in
            
            DispatchQueue.main.async {
                self.handleErrorBasedOnSDKSettings(error)
            }
            
            onClientToken?(nil, error)
            onClientToken = nil
        }
    }
    
    override func handleSuccess() {
        // completion will be created when we're awaiting the payment response
        onResumeTokenCompletion?(self.paymentMethod, nil)
        onResumeTokenCompletion = nil
    }
}

enum PollingStatus: String, Codable {
    case pending = "PENDING"
    case complete = "COMPLETE"
}

struct PollingResponse: Decodable {
    let status: PollingStatus
    let id: String
    let source: String
    let urls: PollingURLs
}

struct PollingURLs: Decodable {
    let status: String
    lazy var statusUrl: URL? = {
        return URL(string: status)
    }()
    let redirect: String
    lazy var redirectUrl: URL? = {
        return URL(string: redirect)
    }()
    let complete: String?
}

struct QRCodePollingURLs: Decodable {
    let status: String
    lazy var statusUrl: URL? = {
        return URL(string: status)
    }()
    let complete: String?
}

class MockAsyncPaymentMethodTokenizationViewModel: ExternalPaymentMethodTokenizationViewModel {
    
    var failValidation: Bool = false {
        didSet {
            let state: AppStateProtocol = DependencyContainer.resolve()
            state.clientToken = nil
        }
    }
    var returnedPaymentMethodJson: String?
    
    fileprivate override func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            guard let _ = config.id else {
                let err = PrimerError.invalidValue(key: "configuration.\(config.type.rawValue.lowercased()).id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if let returnedPaymentMethodJson = returnedPaymentMethodJson,
               let returnedPaymentMethodData = returnedPaymentMethodJson.data(using: .utf8),
               let paymentMethod = try? JSONDecoder().decode(PaymentMethodToken.self, from: returnedPaymentMethodData) {
                seal.fulfill(paymentMethod)
            } else {
                let err = ParserError.failedToDecode(message: "Failed to decode tokenization response.", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
            }
        }
    }
    
    internal override func presentAsyncPaymentMethod(with url: URL) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.webViewController = SFSafariViewController(url: url)
                self.webViewController?.delegate = self
                //                self.webViewController!.modalPresentationStyle = .fullScreen
                
                self.willPresentExternalView?()
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    self.didPresentExternalView?()
                    seal.fulfill(())
                }
            }
        }
    }
    
    internal override func startPolling(on url: URL, completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
        //        {
        //          "status" : "COMPLETE",
        //          "id" : "4474848f-721d-4c35-9325-e287196f7016",
        //          "source" : "WEBHOOK",
        //          "urls" : {
        //            "status" : "https:\/\/api.staging.primer.io\/resume-tokens\/4474848f-721d-4c35-9325-e287196f7016",
        //            "redirect" : "https:\/\/api.staging.primer.io\/resume-tokens\/4474848f-721d-4c35-9325-e287196f7016\/complete?api_key=9e66ba99-e154-4e34-9d96-91777859b85b",
        //            "complete" : "https:\/\/api.staging.primer.io\/resume-tokens\/4474848f-721d-4c35-9325-e287196f7016\/complete"
        //          }
        //        }
        completion("4474848f-721d-4c35-9325-e287196f7016", nil)
    }
    
}

#endif
