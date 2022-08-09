#if canImport(UIKit)

import Foundation
import WebKit
import UIKit

class KlarnaTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    private var sessionId: String?
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?
    
    private var klarnaUrl: URL!
    private var webViewController: PrimerWebViewController?
    private var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    private var authorizationToken: String!
    private var klarnaCustomerTokenAPIResponse: KlarnaCustomerTokenAPIResponse!
    
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self.self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        let klarnaSessionType: KlarnaSessionType = Primer.shared.intent == .vault ? .recurringPayment : .hostedPaymentPage
        
        if Primer.shared.intent == .checkout && AppState.current.amount == nil  {
            let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if case .hostedPaymentPage = klarnaSessionType {
            if AppState.current.amount == nil {
                let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if AppState.current.currency == nil {
                let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if (AppState.current.apiConfiguration?.clientSession?.order?.lineItems ?? []).isEmpty {
                let err = PrimerError.invalidValue(key: "lineItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if !(AppState.current.apiConfiguration?.clientSession?.order?.lineItems ?? []).filter({ $0.amount == nil }).isEmpty {
                let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
        }
    }
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.config.type,
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
            .then {
                return self.generateWebViewUrl()
            }
            .then { url -> Promise<Void> in
                self.klarnaUrl = url
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<KlarnaCustomerTokenAPIResponse> in
                return self.createKlarnaCustomerToken(authorizationToken: self.authorizationToken)
            }
            .done { klarnaCustomerTokenAPIResponse in
                self.klarnaCustomerTokenAPIResponse = klarnaCustomerTokenAPIResponse
                DispatchQueue.main.async {
                    self.willDismissExternalView?()
                }
                
                self.webViewController?.presentingViewController?.dismiss(animated: true, completion: {
                    DispatchQueue.main.async {
                        self.didDismissExternalView?()
                    }
                })
                
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.checkouEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.checkouEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    override func performPostTokenizationSteps() -> Promise<Void> {
        return Promise { seal in
            seal.fulfill()
        }
    }
    
    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                self.webViewController = PrimerWebViewController(with: self.klarnaUrl)
                self.webViewController!.navigationDelegate = self
                self.webViewController!.modalPresentationStyle = .fullScreen
                                
                self.willPresentExternalView?()
                Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: {
                    DispatchQueue.main.async {
                        self.didPresentExternalView?()
                        seal.fulfill()
                    }
                })
            }
        }
    }
    
    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.webViewCompletion = { authorizationToken, err in
                if let err = err {
                    seal.reject(err)
                } else if let authorizationToken = authorizationToken {
                    self.authorizationToken = authorizationToken
                    seal.fulfill()
                } else {
                    precondition(false, "Should never end up in here")
                }
            }
        }
    }
    
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            var instrument: PaymentInstrument
            var request: PaymentMethodTokenizationRequest
            
            if Primer.shared.intent == .vault {
                instrument = PaymentInstrument(
                    klarnaAuthorizationToken: self.authorizationToken!,
                    sessionData: self.klarnaCustomerTokenAPIResponse.sessionData)
                
                request = PaymentMethodTokenizationRequest(
                    paymentInstrument: instrument,
                    paymentFlow: .vault)
                
            } else {
                instrument = PaymentInstrument(
                    klarnaCustomerToken: self.klarnaCustomerTokenAPIResponse.customerTokenId,
                    sessionData: self.klarnaCustomerTokenAPIResponse.sessionData)
                
                request = PaymentMethodTokenizationRequest(
                    paymentInstrument: instrument,
                    paymentFlow: .checkout)
            }
            
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            
            firstly {
                tokenizationService.tokenize(request: request)
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func generateWebViewUrl() -> Promise<URL> {
        return Promise { seal in
            self.generateWebViewUrl { result in
                switch result {
                case .success(let url):
                    seal.fulfill(url)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    private func generateWebViewUrl(completion: @escaping (Result<URL, Error>) -> Void) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            completion(.failure(PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)))
            return
        }
                
        guard let configId = config.id else {
            let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let klarnaSessionType: KlarnaSessionType = Primer.shared.intent == .vault ? .recurringPayment : .hostedPaymentPage

        var amount = AppState.current.amount
        if amount == nil && Primer.shared.intent == .checkout {
            let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        var orderItems: [OrderItem]? = nil
        
        if case .hostedPaymentPage = klarnaSessionType {
            if amount == nil {
                let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            if AppState.current.currency == nil {
                let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            if (AppState.current.apiConfiguration?.clientSession?.order?.lineItems ?? []).isEmpty {
                let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            if !(AppState.current.apiConfiguration?.clientSession?.order?.lineItems ?? []).filter({ $0.amount == nil }).isEmpty {
                let err = PrimerError.invalidValue(key: "settings.orderItems.amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            orderItems = AppState.current.apiConfiguration?.clientSession?.order?.lineItems?.compactMap({ try? $0.toOrderItem() })
            
            log(logLevel: .info, message: "Klarna amount: \(amount!) \(AppState.current.currency!.rawValue)")
            
        } else if case .recurringPayment = klarnaSessionType {
            // Do not send amount for recurring payments, even if it's set
            amount = nil
        }
        
        var body: KlarnaCreatePaymentSessionAPIRequest
        
        if AppState.current.apiConfiguration?.clientSession?.order?.countryCode != nil || AppState.current.currency != nil {
            body = KlarnaCreatePaymentSessionAPIRequest(
                paymentMethodConfigId: configId,
                sessionType: klarnaSessionType,
                localeData: PrimerSettings.current.localeData,
                description: klarnaSessionType == .recurringPayment ? PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription : nil,
                redirectUrl: "https://primer.io/success",
                totalAmount: amount,
                orderItems: orderItems)
        } else {
            body = KlarnaCreatePaymentSessionAPIRequest(
                paymentMethodConfigId: configId,
                sessionType: klarnaSessionType,
                localeData: PrimerSettings.current.localeData,
                description: klarnaSessionType == .recurringPayment ? PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription : nil,
                redirectUrl: "https://primer.io/success",
                totalAmount: amount,
                orderItems: orderItems)
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.createKlarnaPaymentSession(clientToken: decodedClientToken, klarnaCreatePaymentSessionAPIRequest: body) { [weak self] (result) in
            switch result {
            case .failure(let err):
                completion(.failure(err))
                
            case .success(let res):
                log(
                    logLevel: .info,
                    message: "\(res)",
                    className: "\(String(describing: self.self))",
                    function: #function
                )
                
                self?.sessionId = res.sessionId
                
                guard let url = URL(string: res.hppRedirectUrl) else {
                    let err = PrimerError.invalidValue(key: "hppRedirectUrl", value: res.hppRedirectUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    completion(.failure(err))
                    return
                }
                
                completion(.success(url))
            }
        }
    }
    
    private func createKlarnaCustomerToken(authorizationToken: String) -> Promise<KlarnaCustomerTokenAPIResponse> {
        return Promise { seal in
            self.createKlarnaCustomerToken(authorizationToken: authorizationToken) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let res):
                    seal.fulfill(res)
                }
            }
        }
    }
    
    private func createKlarnaCustomerToken(authorizationToken: String, completion: @escaping (Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
                
        guard let configId = AppState.current.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.klarna.rawValue),
              let sessionId = self.sessionId else {
                  let err = PrimerError.missingPrimerConfiguration(
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: nil)
                  ErrorHandler.handle(error: err)
                  completion(.failure(err))
                  return
              }
        
        let body = CreateKlarnaCustomerTokenAPIRequest(
            paymentMethodConfigId: configId,
            sessionId: sessionId,
            authorizationToken: authorizationToken,
            description: PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            localeData: PrimerSettings.current.localeData
        )
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.createKlarnaCustomerToken(clientToken: decodedClientToken, klarnaCreateCustomerTokenAPIRequest: body) { (result) in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let response):
                completion(.success(response))
            }
        }
    }
    
    private func finalizePaymentSession() -> Promise<KlarnaCustomerTokenAPIResponse> {
        return Promise { seal in
            self.finalizePaymentSession { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let res):
                    seal.fulfill(res)
                }
            }
        }
    }
    
    private func finalizePaymentSession(completion: @escaping (Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard let configId = AppState.current.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.klarna.rawValue),
              let sessionId = self.sessionId else {
                  let err = PrimerError.missingPrimerConfiguration(
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: nil)
                  ErrorHandler.handle(error: err)
                  completion(.failure(err))
                  return
              }
        
        let body = KlarnaFinalizePaymentSessionRequest(paymentMethodConfigId: configId, sessionId: sessionId)
        log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "finalizePaymentSession")
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.finalizeKlarnaPaymentSession(clientToken: decodedClientToken, klarnaFinalizePaymentSessionRequest: body) { (result) in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let response):
                log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createPaymentSession")
                completion(.success(response))
            }
        }
    }
}

extension KlarnaTokenizationViewModel: WKNavigationDelegate {
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {        
        if var urlStr = navigationAction.request.url?.absoluteString,
           urlStr.hasPrefix("bankid://") == true {
            // This is a redirect to the BankId app
            
            
            if urlStr.contains("redirect=null"), let urlScheme = PrimerSettings.current.paymentMethodOptions.urlScheme {
                // Klarna's redirect param should contain our URL scheme, replace null with urlScheme if we have a urlScheme if present.
                urlStr = urlStr.replacingOccurrences(of: "redirect=null", with: "redirect=\(urlScheme)")
            }
            
            // The bankid redirection URL looks like the one below
            /// bankid:///?autostarttoken=197701116050-fa74-49cf-b98c-bfe651f9a7c6&redirect=null
            if UIApplication.shared.canOpenURL(URL(string: urlStr)!) {
                decisionHandler(.allow)
                UIApplication.shared.open(URL(string: urlStr)!, options: [:]) { (isFinished) in
                    
                }
                return
            }
        }
        
        let allowedHosts: [String] = [
            "primer.io",
            "livedemostore.primer.io"
        ]
        
        if let url = navigationAction.request.url, let host = url.host, allowedHosts.contains(host) {
            let urlStateParameter = url.queryParameterValue(for: "state")
            if urlStateParameter == "cancel" {
                let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                webViewCompletion?(nil, err)
                webViewCompletion = nil
                decisionHandler(.cancel)
                return
            }
            
            let token = url.queryParameterValue(for: "token")
            
            if (token ?? "").isEmpty || token == "undefined" || token == "null" {
                let err = PrimerError.invalidValue(key: "paymentMethodToken", value: token, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                webViewCompletion?(nil, err)
                webViewCompletion = nil
                decisionHandler(.cancel)
                return
            }
            
            log(logLevel: .info, message: "🚀🚀 \(url)")
            log(logLevel: .info, message: "🚀🚀 token \(token!)")
            
            webViewCompletion?(token, nil)
            webViewCompletion = nil
            
            log(logLevel: .info, message: "🚀🚀🚀 \(token!)")
            
            // Cancels navigation
            decisionHandler(.cancel)
            
        } else {
            // Allow navigation to continue
            decisionHandler(.allow)
        }
    }
    
    func webView(_ webView: WKWebView, didFailProvisionalNavigation navigation: WKNavigation!, withError error: Error) {
        let nsError = error as NSError
        if !(nsError.domain == "NSURLErrorDomain" && nsError.code == -1002) {
            // Code -1002 means bad URL redirect. Klarna is redirecting to bankid:// which is considered a bad URL
            // Not sure yet if we have to do that only for bankid://
            webViewCompletion?(nil, error)
            webViewCompletion = nil
        }
    }
    
}

#endif
