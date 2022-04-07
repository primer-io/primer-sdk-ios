#if canImport(UIKit)

import UIKit
import AuthenticationServices
import SafariServices

class PayPalTokenizationViewModel: PaymentMethodTokenizationViewModel, ExternalPaymentMethodTokenizationViewModelProtocol {
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?
    
    private var session: Any!
    private var orderId: String?
    private var confirmBillingAgreementResponse: PayPalConfirmBillingAgreementResponse?
    
    private lazy var _title: String = { return "PayPal" }()
    override var title: String  {
        get { return _title }
        set { _title = newValue }
    }
    
    private lazy var _buttonTitle: String? = { return nil }()
    override var buttonTitle: String? {
        get { return _buttonTitle }
        set { _buttonTitle = newValue }
    }
    
    private lazy var _buttonImage: UIImage? = {
        switch config.type {
        case .payPal:
            return UIImage(named: "paypal-logo", in: Bundle.primerResources, compatibleWith: nil)
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
        case .payPal:
            return UIColor(red: 0.0/255, green: 156.0/255, blue: 222.0/255, alpha: 1)
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
        case .payPal:
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
        case .payPal:
            return 0.0
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
        case .payPal:
            return nil
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
        case .payPal:
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
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.coreUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.coreUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
    }
    
    @objc
    override func startTokenizationFlow() {
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
                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                PrimerDelegateProxy.checkoutFailed(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
        
        firstly {
            configService.fetchConfig()
        }
        .then {
            self.tokenize()
        }
        .done { paymentMethod in
            
            self.paymentMethod = paymentMethod
            self.handleContinuePaymentFlowWithPaymentMethod(paymentMethod)
        }
        .catch { err in
            ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
            PrimerDelegateProxy.checkoutFailed(with: err)
            self.handleFailedTokenizationFlow(error: err)
        }
    }
    
    func tokenize() -> Promise <PaymentMethodToken> {
        return Promise { seal in
            firstly {
                self.fetchOAuthURL()
            }
            .then { url -> Promise<URL> in
                self.willPresentExternalView?()
                return self.createOAuthSession(url)
            }
            .then { url -> Promise<PaymentInstrument> in
                return self.generatePaypalPaymentInstrument()
            }
            .then { instrument -> Promise<PaymentMethodToken> in
                return self.tokenize(instrument: instrument)
            }
            .done { token in
                seal.fulfill(token)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func fetchOAuthURL() -> Promise<URL> {
        return Promise { seal in
            let paypalService: PayPalServiceProtocol = DependencyContainer.resolve()
            
            switch Primer.shared.flow.internalSessionFlow.uxMode {
            case .CHECKOUT:
                paypalService.startOrderSession { result in
                    switch result {
                    case .success(let res):
                        guard let url = URL(string: res.approvalUrl) else {
                            let err = PrimerError.invalidValue(key: "res.approvalUrl", value: res.approvalUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        self.orderId = res.orderId
                        seal.fulfill(url)
                        
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            case .VAULT:
                paypalService.startBillingAgreementSession { result in
                    switch result {
                    case .success(let urlStr):
                        guard let url = URL(string: urlStr) else {
                            let err = PrimerError.invalidValue(key: "billingAgreement.response.url", value: urlStr, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        seal.fulfill(url)
                        
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            }
        }
    }
    
    private func createOAuthSession(_ url: URL) -> Promise<URL> {
        return Promise { seal in
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            guard var urlScheme = settings.urlScheme else {
                let err = PrimerError.invalidValue(key: "settings.urlScheme", value: settings.urlScheme, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if urlScheme.contains("://")  {
                urlScheme = urlScheme.components(separatedBy: "://").first!
            }
            
            if #available(iOS 13, *) {
                let webAuthSession =  ASWebAuthenticationSession(
                    url: url,
                    callbackURLScheme: urlScheme,
                    completionHandler: { (url, error) in
                        if let error = error {
                            seal.reject(error)
                            
                        } else if let url = url {
                            seal.fulfill(url)
                        }

                        (self.session as! ASWebAuthenticationSession).cancel()
                    }
                )
                session = webAuthSession
                
                webAuthSession.presentationContextProvider = self
                webAuthSession.start()
                
            } else if #available(iOS 11, *) {
                session = SFAuthenticationSession(
                    url: url,
                    callbackURLScheme: urlScheme,
                    completionHandler: { (url, err) in
                        if let err = err {
                            seal.reject(err)
                            
                        } else if let url = url {
                            seal.fulfill(url)
                        }
                    }
                )

                (session as! SFAuthenticationSession).start()
            }
            
            didPresentExternalView?()
        }
    }
    
    func fetchPayPalExternalPayerInfo(orderId: String) -> Promise<PayPal.PayerInfo.Response> {
        return Promise { seal in
            let paypalService: PayPalServiceProtocol = DependencyContainer.resolve()
            paypalService.fetchPayPalExternalPayerInfo(orderId: orderId) { result in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    private func generatePaypalPaymentInstrument() -> Promise<PaymentInstrument> {
        return Promise { seal in
            guard let orderId = orderId else {
                let err = PrimerError.invalidValue(key: "orderId", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            firstly {
                self.fetchPayPalExternalPayerInfo(orderId: orderId)
            }
            .done { response in
                self.generatePaypalPaymentInstrument(externalPayerInfo: response.externalPayerInfo) { result in
                    switch result {
                    case .success(let paymentInstrument):
                        seal.fulfill(paymentInstrument)
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func generatePaypalPaymentInstrument(externalPayerInfo: ExternalPayerInfo, completion: @escaping (Result<PaymentInstrument, Error>) -> Void) {
        switch Primer.shared.flow.internalSessionFlow.uxMode {
        case .CHECKOUT:
            guard let orderId = orderId else {
                let err = PrimerError.invalidValue(key: "orderId", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            let paymentInstrument = PaymentInstrument(paypalOrderId: orderId, externalPayerInfo: externalPayerInfo)
            completion(.success(paymentInstrument))
            
        case .VAULT:
            guard let confirmedBillingAgreement = self.confirmBillingAgreementResponse else {
                generateBillingAgreementConfirmation { [weak self] err in
                    if let err = err {
                        completion(.failure(err))
                    } else {
                        self?.generatePaypalPaymentInstrument(externalPayerInfo: externalPayerInfo, completion: completion)
                    }
                }
                return
            }
            let paymentInstrument = PaymentInstrument(
                paypalBillingAgreementId: confirmedBillingAgreement.billingAgreementId,
                shippingAddress: confirmedBillingAgreement.shippingAddress,
                externalPayerInfo: confirmedBillingAgreement.externalPayerInfo
            )
            
            completion(.success(paymentInstrument))
        }
    }
    
    private func generateBillingAgreementConfirmation(_ completion: @escaping (Error?) -> Void) {
        let paypalService: PayPalServiceProtocol = DependencyContainer.resolve()
        paypalService.confirmBillingAgreement({ result in
            switch result {
            case .failure(let err):
                let contaiinerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                completion(contaiinerErr)
            case .success(let res):
                self.confirmBillingAgreementResponse = res
                completion(nil)
            }
        })
    }
    
    private func tokenize(instrument: PaymentInstrument) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            let state: AppStateProtocol = DependencyContainer.resolve()
            let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
            
            let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
            tokenizationService.tokenize(request: request) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                    
                case .success(let token):
                    seal.fulfill(token)
                }
            }
        }
    }
}

extension PayPalTokenizationViewModel {
    
    override func handle(error: Error) {
        ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
        self.completion?(nil, error)
        self.completion = nil
    }

    override func handle(newClientToken clientToken: String) {
        
        firstly {
            ClientTokenService.storeClientToken(clientToken)
        }
        .done {
            self.continueTokenizationFlow()
        }
        .catch { error in
            DispatchQueue.main.async {
                self.handle(error: error)
                self.handleErrorBasedOnSDKSettings(error, isOnResumeFlow: true)
            }
        }
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

@available(iOS 11.0, *)
extension PayPalTokenizationViewModel: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 12.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow ?? ASPresentationAnchor()
    }
    
}

#endif
