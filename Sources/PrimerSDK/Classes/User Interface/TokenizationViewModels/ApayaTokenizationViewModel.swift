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

class ApayaTokenizationViewModel: PaymentMethodTokenizationViewModel, ExternalPaymentMethodTokenizationViewModelProtocol {
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?
    
    override lazy var title: String = {
        return "Apaya"
    }()
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        case .apaya:
            return NSLocalizedString("payment-method-type-pay-by-mobile",
                                     tableName: nil,
                                     bundle: Bundle.primerResources,
                                     value: "Pay by mobile",
                                     comment: "Pay by mobile - Payment By Mobile (Apaya)")
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
        switch config.type {
        case .apaya:
            return UIImage(named: "mobile", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonColor: UIColor? = {
        switch config.type {
        case .apaya:
            return theme.paymentMethodButton.color(for: .enabled)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .apaya:
            return theme.paymentMethodButton.text.color
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .apaya:
            return 1.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .apaya:
            return theme.paymentMethodButton.text.color
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .apaya:
            return theme.paymentMethodButton.text.color
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
    
    private var webViewController: PrimerWebViewController?
    private var webViewCompletion: ((_ res: Apaya.WebViewResponse?, _ error: Error?) -> Void)?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = state.decodedClientToken, decodedClientToken.isValid else {
            let err = PaymentException.missingClientToken
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.tokenizationPreRequestFailed
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard state.paymentMethodConfig?.getProductId(for: .apaya) != nil else {
            let err = ApayaException.noToken
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard settings.currency != nil else {
            let err = PaymentException.missingCurrency
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
    }
    
    @objc
    override func startTokenizationFlow() {
        super.startTokenizationFlow()
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
        
        if let onClientSessionActions = Primer.shared.delegate?.onClientSessionActions {
            let params: [String: Any] = ["paymentMethodType": config.type.rawValue]
            let actions: [ClientSession.Action] = [ClientSession.Action(type: "SELECT_PAYMENT_METHOD", params: params)]
            onClientSessionActions(actions, self)
        } else {
            continueTokenizationFlow()
        }
        
        let params: [String: Any] = ["paymentMethodType": config.type.rawValue]
        let actions: [ClientSession.Action] = [ClientSession.Action(type: "SELECT_PAYMENT_METHOD", params: params)]
        Primer.shared.delegate?.onClientSessionActions?(actions, resumeHandler: self)
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
        .then { url -> Promise<Apaya.WebViewResponse> in
            self.presentApayaController(with: url)
        }
        .then { apayaWebViewResponse -> Promise<PaymentMethodToken> in
            self.tokenize(apayaWebViewResponse: apayaWebViewResponse)
        }
        .done { paymentMethod in
            DispatchQueue.main.async {
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
        DispatchQueue.main.async {
            self.webViewController = PrimerWebViewController(with: url)
            self.webViewController!.navigationDelegate = self
            self.webViewController!.modalPresentationStyle = .fullScreen
            
            self.webViewCompletion = { (res, err) in
                completion(res, err)
            }
            
            self.willPresentExternalView?()
            Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: {
                DispatchQueue.main.async {
                    self.didPresentExternalView?()
                }
            })
        }
    }
    
    private func tokenize(apayaWebViewResponse: Apaya.WebViewResponse) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            self.tokenize(apayaWebViewResponse: apayaWebViewResponse) { paymentMethod, err in
                self.willDismissExternalView?()
                self.webViewController?.dismiss(animated: true, completion: {
                    self.didDismissExternalView?()
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
        do {
            // For Apaya there's no redirection URL, once the webview is presented it will get its response from a URL redirection.
            // We'll end up in here only for surcharge.
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
            DispatchQueue.main.async {
                Primer.shared.delegate?.checkoutFailed?(with: error)
                self.handle(error: error)
            }
        }
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

#endif
