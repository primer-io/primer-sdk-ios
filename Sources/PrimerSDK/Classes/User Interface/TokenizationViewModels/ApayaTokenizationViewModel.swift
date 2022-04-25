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
    
    private lazy var _title: String = { return "Apaya" }()
    override var title: String  {
        get { return _title }
        set { _title = newValue }
    }
    
    private lazy var _buttonTitle: String? = {
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
    override var buttonTitle: String? {
        get { return _buttonTitle }
        set { _buttonTitle = newValue }
    }
    
    private lazy var _buttonImage: UIImage? = {
        switch config.type {
        case .apaya:
            return UIImage(named: "mobile", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
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
        case .apaya:
            return theme.paymentMethodButton.color(for: .enabled)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonColor: UIColor? {
        get { return _buttonColor }
        set { _buttonColor = newValue }
    }
    
    private lazy var _buttonTitleColor: UIColor? = {
        switch config.type {
        case .apaya:
            return theme.paymentMethodButton.text.color
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonTitleColor: UIColor? {
        get { return _buttonTitleColor }
        set { _buttonTitleColor = newValue }
    }
    
    private lazy var _buttonBorderWidth: CGFloat = {
        switch config.type {
        case .apaya:
            return 1.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    override var buttonBorderWidth: CGFloat {
        get { return _buttonBorderWidth }
        set { _buttonBorderWidth = newValue }
    }
    
    private lazy var _buttonBorderColor: UIColor? = {
        switch config.type {
        case .apaya:
            return theme.paymentMethodButton.text.color
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonBorderColor: UIColor? {
        get { return _buttonBorderColor }
        set { _buttonBorderColor = newValue }
    }
    
    private lazy var _buttonTintColor: UIColor? = {
        switch config.type {
        case .apaya:
            return theme.paymentMethodButton.text.color
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    private var webViewController: PrimerWebViewController?
    private var webViewCompletion: ((_ res: Apaya.WebViewResponse?, _ error: Error?) -> Void)?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard let configuration = state.primerConfiguration else {
            let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
                
                
        guard configuration.getProductId(for: .apaya) != nil else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard settings.currency != nil else {
            let err = PrimerError.invalidSetting(name: "currency", value: settings.currency?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
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
            self.selectPaymentMethodWithParameters(params)
        } else {
            continueTokenizationFlow()
        }
    }
    
    fileprivate func continueTokenizationFlow() {
        
        do {
            try self.validate()
        } catch {
            DispatchQueue.main.async {
                self.unselectPaymentMethodWithError(error)
            }
            return
        }
        
        firstly {
            self.handlePrimerWillCreatePaymentEvent(PaymentMethodData(type: config.type))
        }
        .then {
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
                self.handleContinuePaymentFlowWithPaymentMethod(paymentMethod)
            }
        }
        .catch { error in
            DispatchQueue.main.async {
                self.unselectPaymentMethodWithError(error)
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
        guard let decodedClientToken = ClientTokenService.decodedClientToken,
              let merchantAccountId = state.primerConfiguration?.getProductId(for: .apaya)
        else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            return completion(.failure(err))
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        guard let currency = settings.currency else {
            let err = PrimerError.invalidSetting(name: "currency", value: settings.currency?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            return completion(.failure(err))
        }
        
        let body = Apaya.CreateSessionAPIRequest(merchantAccountId: merchantAccountId,
                                                 language: settings.localeData.languageCode ?? "en",
                                                 currencyCode: currency.rawValue,
                                                 phoneNumber: settings.customer?.mobilePhoneNumber)
        
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
            let err = PrimerError.invalidSetting(name: "currency", value: settings.currency?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
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
            state: state
        )
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
        apiClient.tokenizePaymentMethod(
            clientToken: decodedClientToken,
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

extension ApayaTokenizationViewModel {
    
    private func executeCompletionAndNullifyAfter(error: Error? = nil) {
        self.completion?(nil, error)
        self.completion = nil
    }
    
    private func selectPaymentMethodWithParameters(_ parameters: [String: Any]) {
        
        firstly {
            ClientSession.Action.selectPaymentMethodWithParameters(parameters)
        }
        .done {}
        .catch { error in
            self.handle(error: error)
        }
    }
        
    private func unselectPaymentMethodWithError(_ error: Error) {
        firstly {
            ClientSession.Action.unselectPaymentMethod()
        }
        .done {
            PrimerDelegateProxy.checkoutFailed(with: error)
            self.handleFailedTokenizationFlow(error: error)
        }
        .catch { error in
            self.handle(error: error)
        }
    }
}

extension ApayaTokenizationViewModel {
    
    override func handle(error: Error) {
        
        firstly {
            ClientSession.Action.unselectPaymentMethod()
        }
        .done {
            self.executeCompletionAndNullifyAfter(error: error)
        }
        .catch { error in
            self.executeCompletionAndNullifyAfter(error: error)
        }
    }
    
    override func handle(newClientToken clientToken: String) {
        
        // For Apaya there's no redirection URL, once the webview is presented it will get its response from a URL redirection.
        // We'll end up in here only for surcharge.

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
                self.handleErrorBasedOnSDKSettings(error, isOnResumeFlow: true)
            }
        }
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

#endif
