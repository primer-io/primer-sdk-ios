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
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
        
        return Promise { seal in
            firstly {
                self.validateReturningPromise()
            }
            .then { () -> Promise<Void> in
                ClientSessionAPIResponse.Action.selectPaymentMethodWithParametersIfNeeded(["paymentMethodType": self.config.type.rawValue])
            }
            .then { () -> Promise<Void> in
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then {
                self.tokenize()
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
            case .VAULT:
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
    
    private func generatePaypalPaymentInstrument() -> Promise<PaymentInstrument> {
        return Promise { seal in
            guard let orderId = orderId else {
                let err = PrimerError.invalidValue(key: "orderId", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
                let err = PrimerError.invalidValue(key: "orderId", value: orderId, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
                let contaiinerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
