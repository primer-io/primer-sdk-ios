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

    private var apayaUrl: URL!
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
                return self.handlePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.config.type))
            }
            .then { () -> Promise<URL> in
                return self.generateWebViewUrl()
            }
            .then { url -> Promise<Void> in
                self.apayaUrl = url
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .done {
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
            .done { dat in
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
        
        let body = Request.Body.Apaya.CreateSession(
            merchantAccountId: merchantAccountId,
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
    
    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
                self.webViewController = PrimerWebViewController(with: self.apayaUrl)
                self.webViewController!.navigationDelegate = self
                self.webViewController!.modalPresentationStyle = .fullScreen
                
                self.willPresentPaymentMethodUI?()
                Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: {
                    DispatchQueue.main.async {
                        self.didPresentPaymentMethodUI?()
                        seal.fulfill()
                    }
                })
            }
        }
    }
    
    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.webViewCompletion = { (res, err) in
                if let err = err {
                    seal.reject(err)
                } else if let res = res {
                    self.apayaWebViewResponse = res
                    seal.fulfill()
                } else {
                    precondition(false, "Should always return a response or an error.")
                }
            }
        }
    }
    
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            self.tokenize(apayaWebViewResponse: self.apayaWebViewResponse) { paymentMethod, err in
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
    
    private func tokenize(apayaWebViewResponse: Apaya.WebViewResponse, completion: @escaping (_ paymentMethod: PrimerPaymentMethodTokenData?, _ err: Error?) -> Void) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        guard let currencyStr = AppState.current.currency?.rawValue else {
            let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        let paymentInstrument = ApayaPaymentInstrument(
            mx: apayaWebViewResponse.mxNumber,
            mnc: apayaWebViewResponse.mnc,
            mcc: apayaWebViewResponse.mcc,
            hashedIdentifier: apayaWebViewResponse.hashedIdentifier,
            productId: apayaWebViewResponse.productId,
            currencyCode: currencyStr)
        
        let tokenizationService: TokenizationServiceProtocol = TokenizationService()
        let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
        
        firstly {
            tokenizationService.tokenize(requestBody: requestBody)
        }
        .done { paymentMethodTokenData in
            self.paymentMethodTokenData = paymentMethodTokenData
            completion(self.paymentMethodTokenData, nil)
        }
        .catch { err in
            completion(nil, err)
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
