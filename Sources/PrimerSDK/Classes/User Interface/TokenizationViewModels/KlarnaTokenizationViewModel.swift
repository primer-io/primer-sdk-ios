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
    
    override lazy var title: String = {
        return "Klarna"
    }()
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        case .klarna:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
        switch config.type {
        case .klarna:
            return UIImage(named: "klarna-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonColor: UIColor? = {
        switch config.type {
        case .klarna:
            return UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1.0)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .klarna:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .klarna:
            return 0.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .klarna:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .klarna:
            return .black
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
        log(logLevel: .debug, message: "🧨 deinit: \(self.self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerInternalError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerInternalError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PaymentError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard let klarnaSessionType = settings.klarnaSessionType else {
            let err = PaymentError.invalidValue(key: "settings.klarnaSessionType", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        if Primer.shared.flow == .checkoutWithKlarna && settings.amount == nil  {
            let err = PaymentError.invalidAmount(amount: settings.amount, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        if case .hostedPaymentPage = klarnaSessionType {
            if settings.amount == nil {
                let err = PaymentError.invalidAmount(amount: settings.amount, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
                throw err
            }
            
            if settings.currency == nil {
                let err = PaymentError.invalidCurrency(currency: settings.currency?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
                throw err
            }
            
            if (settings.orderItems ?? []).isEmpty {
                let err = PaymentError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
                throw err
            }
            
            if !(settings.orderItems ?? []).filter({ $0.unitAmount == nil }).isEmpty {
                let err = PaymentError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
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
                Primer.shared.delegate?.checkoutFailed?(with: error)
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
            
            if Primer.shared.flow.internalSessionFlow.vaulted {
                return self.createKlarnaCustomerToken(authorizationToken: authorizationToken)
            } else {
                return self.finalizePaymentSession()
            }
        }
        .then { res -> Promise<PaymentMethodToken> in
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
                instrument = PaymentInstrument(klarnaCustomerToken: res.customerTokenId, sessionData: res.sessionData)
                request = PaymentMethodTokenizationRequest(
                    paymentInstrument: instrument,
                    paymentFlow: .vault,
                    customerId: settings.customerId)
                
            } else {
                instrument = PaymentInstrument(klarnaAuthorizationToken: self.authorizationToken!, sessionData: res.sessionData)
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
                if Primer.shared.flow.internalSessionFlow.vaulted {
                    Primer.shared.delegate?.tokenAddedToVault?(paymentMethod)
                }
                
                Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, resumeHandler: self)
                Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, { err in
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
                Primer.shared.delegate?.checkoutFailed?(with: err)
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
            completion(.failure(PrimerInternalError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])))
            return
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let configId = config.id else {
            let err = PrimerInternalError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard let klarnaSessionType = settings.klarnaSessionType else {
            let err = PaymentError.invalidValue(key: "settings.klarnaSessionType", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }
        
        var amount = settings.amount
        if amount == nil && Primer.shared.flow == .checkoutWithKlarna {
            let err = PaymentError.invalidAmount(amount: amount, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }
        
        var orderItems: [OrderItem]? = nil
        
        if case .hostedPaymentPage = klarnaSessionType {
            if amount == nil {
                let err = PaymentError.invalidAmount(amount: amount, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
                completion(.failure(err))
                return
            }
            
            if settings.currency == nil {
                let err = PaymentError.invalidCurrency(currency: settings.currency?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
                completion(.failure(err))
                return
            }
            
            if (settings.orderItems ?? []).isEmpty {
                let err = PaymentError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
                completion(.failure(err))
                return
            }
            
            if !(settings.orderItems ?? []).filter({ $0.unitAmount == nil }).isEmpty {
                let err = PaymentError.invalidValue(key: "settings.orderItems.amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
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
        
        api.klarnaCreatePaymentSession(clientToken: decodedClientToken, klarnaCreatePaymentSessionAPIRequest: body) { [weak self] (result) in
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
                    let err = PaymentError.invalidValue(key: "hppRedirectUrl", value: res.hppRedirectUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    _ = ErrorHandler.shared.handle(error: err)
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
            let err = PrimerInternalError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let configId = state.primerConfiguration?.getConfigId(for: .klarna),
              let sessionId = self.sessionId else {
                  let err = PrimerInternalError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                  _ = ErrorHandler.shared.handle(error: err)
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
        
        api.klarnaCreateCustomerToken(clientToken: decodedClientToken, klarnaCreateCustomerTokenAPIRequest: body) { (result) in
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
            let err = PrimerInternalError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            _ = ErrorHandler.shared.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard let configId = state.primerConfiguration?.getConfigId(for: .klarna),
              let sessionId = self.sessionId else {
                  let err = PrimerInternalError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                  _ = ErrorHandler.shared.handle(error: err)
                  completion(.failure(err))
                  return
              }
        
        let body = KlarnaFinalizePaymentSessionRequest(paymentMethodConfigId: configId, sessionId: sessionId)
        
        log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "finalizePaymentSession")
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        api.klarnaFinalizePaymentSession(clientToken: decodedClientToken, klarnaFinalizePaymentSessionRequest: body) { (result) in
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
                let err = PaymentError.cancelled(paymentMethodType: self.config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
                webViewCompletion?(nil, err)
                webViewCompletion = nil
                decisionHandler(.cancel)
                return
            }
            
            let token = url.queryParameterValue(for: "token")
            
            if (token ?? "").isEmpty || token == "undefined" || token == "null" {
                let err = PaymentError.invalidValue(key: "paymentMethodToken", value: token, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                _ = ErrorHandler.shared.handle(error: err)
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
        do {
            try ClientTokenService.storeClientToken(clientToken)
            
            let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            
            firstly {
                configService.fetchConfig()
            }
            .done {
                self.continueTokenizationFlow()
            }
            .catch { err in
                self.handle(error: err)
            }
            
        } catch {
            Primer.shared.delegate?.checkoutFailed?(with: error)
            self.handle(error: error)
        }
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

#endif
