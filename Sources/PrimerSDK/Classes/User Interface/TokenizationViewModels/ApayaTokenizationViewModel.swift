//
//  ApayaTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 12/10/21.
//

#if canImport(UIKit)

import Foundation
import UIKit
import WebKit

class ApayaTokenizationViewModel: PaymentMethodTokenizationViewModel {

    private var webViewController: PrimerWebViewController?
    private var webViewCompletion: ((_ res: Apaya.WebViewResponse?, _ error: Error?) -> Void)?
    private var apayaWebViewResponse: Apaya.WebViewResponse!
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard let configuration = AppState.current.apiConfiguration else {
            let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
                
                
        guard configuration.getProductId(for: PrimerPaymentMethodType.apaya.rawValue) != nil else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard AppState.current.currency != nil else {
            let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
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
                self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then {
                self.generateWebViewUrl()
            }
            .then { url -> Promise<Apaya.WebViewResponse> in
                self.presentApayaController(with: url)
            }
            .done { apayaWebViewResponse in
                self.apayaWebViewResponse = apayaWebViewResponse
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
                self.tokenize(apayaWebViewResponse: self.apayaWebViewResponse)
            }
            .done { paymentMethodTokenData in
                self.paymentMethodTokenData = paymentMethodTokenData
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
    
    override func startTokenizationFlow() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            firstly {
                self.performPreTokenizationSteps()
            }
            .then { () -> Promise<Void> in
                return self.performTokenizationStep()
            }
            .then { () -> Promise<Void> in
                return self.performPostTokenizationSteps()
            }
            .done {
                seal.fulfill(self.paymentMethodTokenData!)
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
                    seal.fulfill(URL(string: url)!)
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    private func generateWebViewUrl(_ completion: @escaping (Result<String, Error>) -> Void) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken,
              let merchantAccountId = AppState.current.apiConfiguration?.getProductId(for: PrimerPaymentMethodType.apaya.rawValue)
        else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            return completion(.failure(err))
        }
        
        guard let currency = AppState.current.currency else {
            let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            return completion(.failure(err))
        }
        
        let body = Apaya.CreateSessionAPIRequest(merchantAccountId: merchantAccountId,
                                                 language: PrimerSettings.current.localeData.languageCode,
                                                 currencyCode: currency.rawValue,
                                                 phoneNumber: AppState.current.apiConfiguration?.clientSession?.customer?.mobileNumber)
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.createApayaSession(clientToken: decodedClientToken, request: body) { [weak self] result in
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
        DispatchQueue.main.async {
            self.webViewController = PrimerWebViewController(with: url)
            self.webViewController!.navigationDelegate = self
            self.webViewController!.modalPresentationStyle = .fullScreen
            
            self.webViewCompletion = { (res, err) in
                completion(res, err)
            }
            
            self.willPresentPaymentMethodUI?()
            Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: {
                DispatchQueue.main.async {
                    self.didPresentPaymentMethodUI?()
                }
            })
        }
    }
    
    private func tokenize(apayaWebViewResponse: Apaya.WebViewResponse) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            self.tokenize(apayaWebViewResponse: apayaWebViewResponse) { paymentMethod, err in
                self.willDismissPaymentMethodUI?()
                self.webViewController?.dismiss(animated: true, completion: {
                    self.didDismissPaymentMethodUI?()
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
        guard let currencyStr = AppState.current.currency?.rawValue else {
            let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
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
            state: AppState.current
        )
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
        apiClient.tokenizePaymentMethod(
            clientToken: decodedClientToken,
            paymentMethodTokenizationRequest: request) { result in
                switch result {
                case .success(let paymentMethodTokenData):
                    self.paymentMethodTokenData = paymentMethodTokenData
                    completion(self.paymentMethodTokenData, nil)
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
        if let host = navigationAction.request.url?.host, WebViewUtil.allowedHostsContain(host) {
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

#endif
