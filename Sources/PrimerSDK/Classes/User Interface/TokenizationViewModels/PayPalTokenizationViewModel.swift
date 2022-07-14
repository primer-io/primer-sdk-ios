#if canImport(UIKit)

import UIKit
import AuthenticationServices
import SafariServices

class PayPalTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?
    
    private var session: Any!
    private var orderId: String?
    private var confirmBillingAgreementResponse: PayPalConfirmBillingAgreementResponse?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.coreUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.coreUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
    }
    
    override func start() {
        self.didPresentExternalView = {
            PrimerDelegateProxy.primerHeadlessUniversalCheckoutPaymentMethodDidShow(for: self.config.type.rawValue)
        }
        
        super.start()
    }
    
    override func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
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
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.uiModule.makeIconImageView(withDimension: 24.0), message: nil)
        
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.config.type, cardNetwork: nil)
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                PrimerDelegateProxy.primerHeadlessUniversalCheckoutTokenizationDidStart(for: self.config.type.rawValue)
                return self.tokenize()
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
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
                self.didPresentExternalView?()
                return self.createPaypalPaymentInstrument()
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
            
            switch Primer.shared.intent {
            case .checkout:
                paypalService.startOrderSession { result in
                    switch result {
                    case .success(let res):
                        guard let url = URL(string: res.approvalUrl) else {
                            let err = PrimerError.invalidValue(key: "res.approvalUrl", value: res.approvalUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
            case .vault:
                paypalService.startBillingAgreementSession { result in
                    switch result {
                    case .success(let urlStr):
                        guard let url = URL(string: urlStr) else {
                            let err = PrimerError.invalidValue(key: "billingAgreement.response.url", value: urlStr, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }
                        
                        seal.fulfill(url)
                        
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            case .none:
                assert(true, "Intent should already be set")
            }
        }
    }
    
    private func createOAuthSession(_ url: URL) -> Promise<URL> {
        return Promise { seal in
            guard var urlScheme = PrimerSettings.current.paymentMethodOptions.urlScheme else {
                let err = PrimerError.invalidValue(key: "settings.urlScheme", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
    
    private func createPaypalPaymentInstrument() -> Promise<PaymentInstrument> {
        return Promise { seal in
            if Primer.shared.intent == .vault {
                firstly {
                    self.generateBillingAgreementConfirmation()
                }
                .done { billingAgreement in
                    let paymentInstrument = PaymentInstrument(
                        paypalBillingAgreementId: billingAgreement.billingAgreementId,
                        shippingAddress: billingAgreement.shippingAddress,
                        externalPayerInfo: billingAgreement.externalPayerInfo)
                    seal.fulfill(paymentInstrument)
                }
                .catch { err in
                    seal.reject(err)
                }
            } else {
                guard let orderId = orderId else {
                    let err = PrimerError.invalidValue(key: "orderId", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                firstly {
                    self.fetchPayPalExternalPayerInfo(orderId: orderId)
                }
                .then { res -> Promise<PaymentInstrument> in
                    return self.generatePaypalPaymentInstrument(externalPayerInfo: res.externalPayerInfo)
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
    }
    
    private func generatePaypalPaymentInstrument(externalPayerInfo: ExternalPayerInfo?) -> Promise<PaymentInstrument> {
        return Promise { seal in
            self.generatePaypalPaymentInstrument(externalPayerInfo: externalPayerInfo) { result in
                switch result {
                case .success(let paymentInstrument):
                    seal.fulfill(paymentInstrument)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    private func generatePaypalPaymentInstrument(externalPayerInfo: ExternalPayerInfo?, completion: @escaping (Result<PaymentInstrument, Error>) -> Void) {
        switch Primer.shared.intent {
        case .checkout:
            guard let orderId = orderId else {
                let err = PrimerError.invalidValue(key: "orderId", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            guard let externalPayerInfo = externalPayerInfo else {
                let err = PrimerError.invalidValue(key: "externalPayerInfo", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            let paymentInstrument = PaymentInstrument(paypalOrderId: orderId, externalPayerInfo: externalPayerInfo)
            completion(.success(paymentInstrument))
            
        case .vault:
            guard let confirmedBillingAgreement = self.confirmBillingAgreementResponse else {
                let err = PrimerError.invalidValue(key: "confirmedBillingAgreement", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            let paymentInstrument = PaymentInstrument(
                paypalBillingAgreementId: confirmedBillingAgreement.billingAgreementId,
                shippingAddress: confirmedBillingAgreement.shippingAddress,
                externalPayerInfo: confirmedBillingAgreement.externalPayerInfo
            )
            
            completion(.success(paymentInstrument))
            
        case .none:
            assert(true, "Intent should have been set.")
        }
    }
    
    private func generateBillingAgreementConfirmation() -> Promise<PayPalConfirmBillingAgreementResponse> {
        return Promise { seal in
            self.generateBillingAgreementConfirmation { (billingAgreementRes, err) in
                if let err = err {
                    seal.reject(err)
                } else if let billingAgreementRes = billingAgreementRes {
                    self.confirmBillingAgreementResponse = billingAgreementRes
                    seal.fulfill(billingAgreementRes)
                }
            }
        }
    }
    
    private func generateBillingAgreementConfirmation(_ completion: @escaping (PayPalConfirmBillingAgreementResponse?, Error?) -> Void) {
        let paypalService: PayPalServiceProtocol = DependencyContainer.resolve()
        paypalService.confirmBillingAgreement({ result in
            switch result {
            case .failure(let err):
                let contaiinerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(nil, contaiinerErr)
            case .success(let res):
                self.confirmBillingAgreementResponse = res
                completion(res, nil)
            }
        })
    }
    
    private func tokenize(instrument: PaymentInstrument) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: AppState.current)

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

@available(iOS 11.0, *)
extension PayPalTokenizationViewModel: ASWebAuthenticationPresentationContextProviding {
    @available(iOS 12.0, *)
    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        return UIApplication.shared.keyWindow ?? ASPresentationAnchor()
    }
    
}

#endif
