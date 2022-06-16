#if canImport(UIKit)

import Foundation
import WebKit
import UIKit

class KlarnaTokenizationViewModel: PaymentMethodTokenizationViewModel, ExternalPaymentMethodTokenizationViewModelProtocol {
    
    private var sessionId: String?
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?
    
    private var webViewController: PrimerWebViewController?
    private var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    private var authorizationToken: String?
    
    private lazy var _title: String = { return "Klarna" }()
    override var title: String  {
        get { return _title }
        set { _title = newValue }
    }
    
    private lazy var _buttonImage: UIImage? = {
        switch config.type {
        case .klarna:
            return UIImage(named: "klarna-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
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
        case .klarna:
            return UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1.0)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonColor: UIColor? {
        get { return _buttonColor }
        set { _buttonColor = newValue }
    }
    
    
    private lazy var _buttonTintColor: UIColor? = {
        switch config.type {
        case .klarna:
            return .black
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
        log(logLevel: .debug, message: "🧨 deinit: \(self.self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard let klarnaSessionType = settings.klarnaSessionType else {
            let err = PrimerError.invalidValue(key: "settings.klarnaSessionType", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if Primer.shared.flow == .checkoutWithKlarna && settings.amount == nil  {
            let err = PrimerError.invalidSetting(name: "amount", value: settings.amount != nil ? "\(settings.amount!)" : nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if case .hostedPaymentPage = klarnaSessionType {
            if settings.amount == nil {
                let err = PrimerError.invalidSetting(name: "amount", value: settings.amount != nil ? "\(settings.amount!)" : nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if settings.currency == nil {
                let err = PrimerError.invalidSetting(name: "currency", value: settings.currency?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if (settings.orderItems ?? []).isEmpty {
                let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if !(settings.orderItems ?? []).filter({ $0.unitAmount == nil }).isEmpty {
                let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
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
                PrimerDelegateProxy.checkoutFailed(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        firstly {
            self.generateWebViewUrl()
        }
        .then { url -> Promise<String> in
            self.presentKlarnaController(with: url)
        }
        .then { authorizationToken -> Promise<KlarnaCustomerTokenAPIResponse> in
            self.authorizationToken = authorizationToken
            return self.createKlarnaCustomerToken(authorizationToken: authorizationToken)
        }
        .then { customerTokenResponse -> Promise<PaymentMethodToken> in
            DispatchQueue.main.async {
                self.willDismissExternalView?()
            }
            self.webViewController?.presentingViewController?.dismiss(animated: true, completion: {
                DispatchQueue.main.async {
                    self.didDismissExternalView?()
                }
            })
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            var instrument: PaymentInstrument
            var request: PaymentMethodTokenizationRequest
            
            if Primer.shared.flow.internalSessionFlow.vaulted {
                instrument = PaymentInstrument(
                    klarnaCustomerToken: customerTokenResponse.customerTokenId!,
                    sessionData: customerTokenResponse.sessionData)
                
                request = PaymentMethodTokenizationRequest(
                    paymentInstrument: instrument,
                    paymentFlow: .vault,
                    customerId: nil)
                
            } else {
                instrument = PaymentInstrument(
                    klarnaCustomerToken: customerTokenResponse.customerTokenId!,
                    sessionData: customerTokenResponse.sessionData)
                
                request = PaymentMethodTokenizationRequest(
                    paymentInstrument: instrument,
                    paymentFlow: .checkout,
                    customerId: settings.customerId)
            }
            
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            return tokenizationService.tokenize(request: request)
        }
        .done { paymentMethod in
            self.paymentMethod = paymentMethod
            
            DispatchQueue.main.async {
                PrimerDelegateProxy.onTokenizeSuccess(paymentMethod, resumeHandler: self)
                PrimerDelegateProxy.onTokenizeSuccess(paymentMethod, { err in
                    if let err = err {
                        self.handleFailedTokenizationFlow(error: err)
                    } else {
                        self.handleSuccessfulTokenizationFlow()
                    }
                })
            }
        }
        .ensure {
            
        }
        .catch { err in
            DispatchQueue.main.async {
                PrimerDelegateProxy.checkoutFailed(with: err)
                self.handleFailedTokenizationFlow(error: err)
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
            completion(.failure(PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])))
            return
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let configId = config.id else {
            let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard let klarnaSessionType = settings.klarnaSessionType else {
            let err = PrimerError.invalidValue(key: "settings.klarnaSessionType", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        var amount = settings.amount
        if amount == nil && Primer.shared.flow == .checkoutWithKlarna {
            let err = PrimerError.invalidSetting(name: "amount", value: settings.amount != nil ? "\(settings.amount!)" : nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        var orderItems: [OrderItem]? = nil
        
        if case .hostedPaymentPage = klarnaSessionType {
            if amount == nil {
                let err = PrimerError.invalidSetting(name: "amount", value: settings.amount != nil ? "\(settings.amount!)" : nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            if settings.currency == nil {
                let err = PrimerError.invalidSetting(name: "currency", value: settings.currency?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            if (settings.orderItems ?? []).isEmpty {
                let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            if !(settings.orderItems ?? []).filter({ $0.unitAmount == nil }).isEmpty {
                let err = PrimerError.invalidValue(key: "settings.orderItems.amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                completion(.failure(err))
                return
            }
            
            orderItems = settings.orderItems
            
            log(logLevel: .info, message: "Klarna amount: \(amount!) \(settings.currency!.rawValue)")
            
        } else if case .recurringPayment = klarnaSessionType {
            // Do not send amount for recurring payments, even if it's set
            amount = nil
        }
        
        var body: KlarnaCreatePaymentSessionAPIRequest
        
        if settings.countryCode != nil || settings.currency != nil {
            body = KlarnaCreatePaymentSessionAPIRequest(
                paymentMethodConfigId: configId,
                sessionType: klarnaSessionType,
                localeData: settings.localeData,
                description: klarnaSessionType == .recurringPayment ? settings.klarnaPaymentDescription : nil,
                redirectUrl: "https://primer.io/success",
                totalAmount: amount,
                orderItems: orderItems)
        } else {
            body = KlarnaCreatePaymentSessionAPIRequest(
                paymentMethodConfigId: configId,
                sessionType: klarnaSessionType,
                localeData: settings.localeData,
                description: klarnaSessionType == .recurringPayment ? settings.klarnaPaymentDescription : nil,
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
                    let err = PrimerError.invalidValue(key: "hppRedirectUrl", value: res.hppRedirectUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    completion(.failure(err))
                    return
                }
                
                completion(.success(url))
            }
        }
    }
    
    private func presentKlarnaController(with url: URL) -> Promise<String> {
        return Promise { seal in
            self.presentKlarnaController(with: url) { (token, err) in
                if let err = err {
                    seal.reject(err)
                } else if let token = token {
                    seal.fulfill(token)
                }
            }
        }
    }
    
    private func presentKlarnaController(with url: URL, completion: @escaping (_ authorizationToken: String?, _ err: Error?) -> Void) {
        DispatchQueue.main.async {
            self.webViewController = PrimerWebViewController(with: url)
            self.webViewController!.navigationDelegate = self
            self.webViewController!.modalPresentationStyle = .fullScreen
            
            self.webViewCompletion = completion
            
            self.willPresentExternalView?()
            Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: {
                DispatchQueue.main.async {
                    self.didPresentExternalView?()
                }
            })
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
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let configId = state.primerConfiguration?.getConfigId(for: .klarna),
              let sessionId = self.sessionId else {
                  let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                  ErrorHandler.handle(error: err)
                  completion(.failure(err))
                  return
              }
        
        let body = CreateKlarnaCustomerTokenAPIRequest(
            paymentMethodConfigId: configId,
            sessionId: sessionId,
            authorizationToken: authorizationToken,
            description: settings.klarnaPaymentDescription,
            localeData: settings.localeData
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
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard let configId = state.primerConfiguration?.getConfigId(for: .klarna),
              let sessionId = self.sessionId else {
                  let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
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
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if var urlStr = navigationAction.request.url?.absoluteString,
           urlStr.hasPrefix("bankid://") == true {
            // This is a redirect to the BankId app
            
            
            if urlStr.contains("redirect=null"), let urlScheme = settings.urlScheme {
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
            //            "api.playground.klarna.com",
            //            "api.sandbox.primer.io"
        ]
        
        if let url = navigationAction.request.url, let host = url.host, allowedHosts.contains(host) {
            let urlStateParameter = url.queryParameterValue(for: "state")
            if urlStateParameter == "cancel" {
                let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                webViewCompletion?(nil, err)
                webViewCompletion = nil
                decisionHandler(.cancel)
                return
            }
            
            let token = url.queryParameterValue(for: "token")
            
            if (token ?? "").isEmpty || token == "undefined" || token == "null" {
                let err = PrimerError.invalidValue(key: "paymentMethodToken", value: token, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
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

extension KlarnaTokenizationViewModel {
    
    override func handle(error: Error) {
        ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
        self.completion?(nil, error)
        self.completion = nil
    }
    
    override func handle(newClientToken clientToken: String) {
        
        firstly {
            ClientTokenService.storeClientToken(clientToken)
        }
        .then{ () -> Promise<Void> in
            let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            return configService.fetchConfig()
        }
        .done {
            self.continueTokenizationFlow()
        }
        .catch { error in
            DispatchQueue.main.async {
                PrimerDelegateProxy.checkoutFailed(with: error)
            }
            self.handle(error: error)
        }
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

#endif
