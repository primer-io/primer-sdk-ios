#if canImport(UIKit)

import Foundation
import WebKit

class KlarnaTokenizationViewModel: PaymentMethodTokenizationViewModel, AsyncPaymentMethodTokenizationViewModelProtocol {
    
    var willPresentPaymentMethod: (() -> Void)?
    var didPresentPaymentMethod: (() -> Void)?
    var willDismissPaymentMethod: (() -> Void)?
    var didDismissPaymentMethod: (() -> Void)?
    private var webViewController: PrimerWebViewController?
    private var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    private var authorizationToken: String?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self.self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {

    }
    
    @objc
    override func startTokenizationFlow() {
        super.startTokenizationFlow()
        
        do {
            try validate()
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
                self.willDismissPaymentMethod?()
            }
            self.webViewController?.presentingViewController?.dismiss(animated: true, completion: {
                DispatchQueue.main.async {
                    self.didDismissPaymentMethod?()
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
            Primer.shared.delegate?.checkoutFailed?(with: err)
            self.handleFailedTokenizationFlow(error: err)
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
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(ApayaException.noToken))
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let configId = state.paymentMethodConfig?.getConfigId(for: .klarna) else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        guard let klarnaSessionType = settings.klarnaSessionType else {
            return completion(.failure(KlarnaException.undefinedSessionType))
        }
        
        var amount = settings.amount
        if amount == nil && Primer.shared.flow == .checkoutWithKlarna {
            return completion(.failure(KlarnaException.noAmount))
        }
        
        var orderItems: [OrderItem]? = nil
                        
        if case .hostedPaymentPage = klarnaSessionType {
            if amount == nil {
                return completion(.failure(KlarnaException.noAmount))
            }
            
            if settings.currency == nil {
                return completion(.failure(KlarnaException.noCurrency))
            }
            
            if settings.orderItems.isEmpty {
                return completion(.failure(KlarnaException.missingOrderItems))
            }
            
            if !settings.orderItems.filter({ $0.unitAmount == nil }).isEmpty {
                return completion(.failure(KlarnaException.orderItemMissesAmount))
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

        api.klarnaCreatePaymentSession(clientToken: clientToken, klarnaCreatePaymentSessionAPIRequest: body) { [weak self] (result) in
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
                
                state.sessionId = res.sessionId
                
                guard let url = URL(string: res.hppRedirectUrl) else {
                    completion(.failure(PrimerError.generic))
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
        webViewController = PrimerWebViewController(with: url)
        webViewController!.navigationDelegate = self
        webViewController!.modalPresentationStyle = .fullScreen
        
        webViewCompletion = completion
        
        self.willPresentPaymentMethod?()
        Primer.shared.primerRootVC?.present(webViewController!, animated: true, completion: {
            self.didPresentPaymentMethod?()
        })
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
        
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(KlarnaException.noToken))
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .klarna),
              let sessionId = state.sessionId else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        let body = CreateKlarnaCustomerTokenAPIRequest(
            paymentMethodConfigId: configId,
            sessionId: sessionId,
            authorizationToken: authorizationToken,
            description: settings.klarnaPaymentDescription,
            localeData: settings.localeData
        )
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.klarnaCreateCustomerToken(clientToken: clientToken, klarnaCreateCustomerTokenAPIRequest: body) { (result) in
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
        
        guard let clientToken = state.decodedClientToken else {
            return completion(.failure(KlarnaException.noToken))
        }

        guard let configId = state.paymentMethodConfig?.getConfigId(for: .klarna),
              let sessionId = state.sessionId else {
            return completion(.failure(KlarnaException.noPaymentMethodConfigId))
        }

        let body = KlarnaFinalizePaymentSessionRequest(paymentMethodConfigId: configId, sessionId: sessionId)

        log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "finalizePaymentSession")
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.klarnaFinalizePaymentSession(clientToken: clientToken, klarnaFinalizePaymentSessionRequest: body) { (result) in
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
                let err = PrimerError.userCancelled
                webViewCompletion?(nil, err)
                webViewCompletion = nil
                decisionHandler(.cancel)
                return
            }
            
            let token = url.queryParameterValue(for: "token")
            
            if (token ?? "").isEmpty || token == "undefined" || token == "null" {
                let err = PrimerError.clientTokenNull
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
        self.completion?(nil, error)
        self.completion = nil
    }
    
    override func handle(newClientToken clientToken: String) {
        try? ClientTokenService.storeClientToken(clientToken)
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

#endif
