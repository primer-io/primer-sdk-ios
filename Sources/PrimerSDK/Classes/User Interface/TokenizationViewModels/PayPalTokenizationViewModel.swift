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
    
    override lazy var title: String = {
        return "PayPal"
    }()
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        case .payPal:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
        switch config.type {
        case .payPal:
            return UIImage(named: "paypal-logo", in: Bundle.primerResources, compatibleWith: nil)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonColor: UIColor? = {
        switch config.type {
        case .payPal:
            return UIColor(red: 0.0/255, green: 156.0/255, blue: 222.0/255, alpha: 1)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .payPal:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .payPal:
            return 0.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .payPal:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .payPal:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonFont: UIFont? = {
        return UIFont.systemFont(ofSize: 17.0, weight: .medium)
    }()
    
    override lazy var buttonCornerRadius: CGFloat? = {
        return 4.0
    }()
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerInternalError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PaymentError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PaymentError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.coreUrl != nil else {
            let err = PaymentError.invalidValue(key: "decodedClientToken.coreUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
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
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
        
        if Primer.shared.delegate?.onClientSessionActions != nil {
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
                Primer.shared.delegate?.checkoutFailed?(with: error)
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
            
            if Primer.shared.flow.internalSessionFlow.vaulted {
                Primer.shared.delegate?.tokenAddedToVault?(paymentMethod)
            }

            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, resumeHandler: self)
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, { [unowned self] err in
                if let err = err {
                    self.handleFailedTokenizationFlow(error: err)
                } else {
                    self.handleSuccessfulTokenizationFlow()
                }
            })
        }
        .catch { err in
            ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
            Primer.shared.delegate?.checkoutFailed?(with: err)
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
                            let err = PaymentError.invalidValue(key: "res.approvalUrl", value: res.approvalUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                            _ = ErrorHandler.shared.handle(error: err)
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
                            let err = PaymentError.invalidValue(key: "billingAgreement.response.url", value: urlStr, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                            _ = ErrorHandler.shared.handle(error: err)
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
            guard let urlScheme = settings.urlScheme else {
                let err = PaymentError.invalidValue(key: "settings.urlScheme", value: settings.urlScheme, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
                seal.reject(err)
                return
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
    
    private func generatePaypalPaymentInstrument() -> Promise<PaymentInstrument> {
        return Promise { seal in
            generatePaypalPaymentInstrument { result in
                switch result {
                case .success(let paymentInstrument):
                    seal.fulfill(paymentInstrument)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    private func generatePaypalPaymentInstrument(_ completion: @escaping (Result<PaymentInstrument, Error>) -> Void) {
        switch Primer.shared.flow.internalSessionFlow.uxMode {
        case .CHECKOUT:
            guard let orderId = orderId else {
                let err = PaymentError.invalidValue(key: "orderId", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
                completion(.failure(err))
                return
            }
            
            let paymentInstrument = PaymentInstrument(paypalOrderId: orderId)
            completion(.success(paymentInstrument))
            
        case .VAULT:
            guard let confirmedBillingAgreement = self.confirmBillingAgreementResponse else {
                generateBillingAgreementConfirmation { [weak self] err in
                    if let err = err {
                        completion(.failure(err))
                    } else {
                        self?.generatePaypalPaymentInstrument(completion)
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
                let contaiinerErr = PaymentError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
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
        do {
            try ClientTokenService.storeClientToken(clientToken)
            self.continueTokenizationFlow()
            
        } catch {
            DispatchQueue.main.async {
                Primer.shared.delegate?.onResumeError?(error)
            }
            self.handle(error: error)
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
