//
//  ApayaTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 12/10/21.
//

import Foundation
import WebKit

class ApayaTokenizationViewModel: PaymentMethodTokenizationViewModel, AsyncPaymentMethodTokenizationViewModelProtocol {
    
    var willPresentPaymentMethod: (() -> Void)?
    var didPresentPaymentMethod: (() -> Void)?
    var willDismissPaymentMethod: (() -> Void)?
    var didDismissPaymentMethod: (() -> Void)?
    
    private var webViewController: PrimerWebViewController?
    private var webViewCompletion: ((_ res: Apaya.WebViewResponse?, _ error: Error?) -> Void)?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
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
            generateWebViewUrl()
        }
        .then { url -> Promise<Apaya.WebViewResponse> in
            self.presentApayaController(with: url)
        }
        .then { apayaWebViewResponse -> Promise<PaymentMethodToken> in
            self.tokenize(apayaWebViewResponse: apayaWebViewResponse)
        }
        .done { paymentMethod in
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, resumeHandler: self)
            Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, { err in
                if let err = err {
                    self.handleFailedTokenizationFlow(error: err)
                } else {
                    self.handleSuccessfulTokenizationFlow()
                }
            })
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
                    seal.fulfill(URL(string: url)!)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    private func generateWebViewUrl(_ completion: @escaping (Result<String, Error>) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let clientToken = state.decodedClientToken,
              let merchantAccountId = state.paymentMethodConfig?.getProductId(for: .apaya)
        else {
            return completion(.failure(ApayaException.noToken))
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        guard let currency = settings.currency else {
            return completion(.failure(PaymentException.missingCurrency))
        }
                
        let body = Apaya.CreateSessionAPIRequest(merchantAccountId: merchantAccountId,
                                                 language: settings.localeData.languageCode ?? "en",
                                                 currencyCode: currency.rawValue,
                                                 phoneNumber: settings.customer?.mobilePhoneNumber)
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.apayaCreateSession(clientToken: clientToken, request: body) { [weak self] result in
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
                completion(.success(res.url))
            }
        }
    }
    
    private func presentApayaController(with url: URL) -> Promise<Apaya.WebViewResponse> {
        return Promise { seal in
            self.presentApayaController(with: url) { (apayaWebViewResponse, err) in
                if let err = err {
                    seal.reject(err)
                } else if let apayaWebViewResponse = apayaWebViewResponse {
                    seal.fulfill(apayaWebViewResponse)
                } else {
                    assert(true, "Should always return a response or an error.")
                }
            }
        }
    }
    
    private func presentApayaController(with url: URL, completion: @escaping (Apaya.WebViewResponse?, Error?) -> Void) {
        webViewController = PrimerWebViewController(with: url)
        webViewController!.navigationDelegate = self
        webViewController!.modalPresentationStyle = .fullScreen
        
        
        
        
        
        
//        webViewController.onRedirect = { url in
//            do {
//                let apayaWebViewResponse = try Apaya.WebViewResponse(url: url)
//                completion(apayaWebViewResponse, nil)
//
//            } catch {
//                completion(nil, error)
//            }
//        }
//        webViewController.onError = { err in
//            completion(nil, err)
//        }
        
        self.willPresentPaymentMethod?()
        Primer.shared.primerRootVC?.present(webViewController!, animated: true, completion: {
            self.didPresentPaymentMethod?()
        })
    }
    
    private func tokenize(apayaWebViewResponse: Apaya.WebViewResponse) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            self.tokenize(apayaWebViewResponse: apayaWebViewResponse) { paymentMethod, err in
                self.willDismissPaymentMethod?()
                self.webViewController?.presentingViewController?.dismiss(animated: true, completion: {
                    self.didDismissPaymentMethod?()
                })
                
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethod = paymentMethod {
                    seal.fulfill(paymentMethod)
                } else {
                    assert(true, "Should always receive a payment method or an error")
                }
            }
        }
    }

    private func tokenize(apayaWebViewResponse: Apaya.WebViewResponse, completion: @escaping (_ paymentMethod: PaymentMethodToken?, _ err: Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let currencyStr = settings.currency?.rawValue else {
            completion(nil, PaymentException.missingCurrency)
            return
        }

        let instrument = PaymentInstrument(mx: apayaWebViewResponse.mxNumber,
                                           mnc: apayaWebViewResponse.mnc,
                                           mcc: apayaWebViewResponse.mcc,
                                           hashedIdentifier: apayaWebViewResponse.hashedIdentifier,
                                           productId: apayaWebViewResponse.productId,
                                           currencyCode: currencyStr)
        
        let request = PaymentMethodTokenizationRequest(
            paymentInstrument: instrument,
            state: state
        )
        
        guard let clientToken = state.decodedClientToken else {
            completion(nil, PrimerError.clientTokenNull)
            return
        }
        
        let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
        apiClient.tokenizePaymentMethod(
            clientToken: clientToken,
            paymentMethodTokenizationRequest: request) { result in
                switch result {
                case .success(let paymentMethod):
                    self.paymentMethod = paymentMethod
                    completion(paymentMethod, nil)
                case .failure(let err):
                    completion(nil, err)
                }
            }
    }
    
}

extension ApayaTokenizationViewModel: WKNavigationDelegate {
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let allowedHosts: [String] = [
            "primer.io",
            "livedemostore.primer.io"
        ]
        
        if let host = navigationAction.request.url?.host, allowedHosts.contains(host) {
            do {
                let apayaWebViewResponse = try Apaya.WebViewResponse(url: navigationAction.request.url!)
                webViewCompletion?(apayaWebViewResponse, nil)

            } catch {
                webViewCompletion?(nil, error)
            }
            
            webViewCompletion = nil
            decisionHandler(.cancel)
            
        } else {
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

extension ApayaTokenizationViewModel {
    
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
