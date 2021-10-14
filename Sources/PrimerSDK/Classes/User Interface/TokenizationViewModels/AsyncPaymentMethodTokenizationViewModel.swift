//
//  AsyncPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 11/10/21.
//

import Foundation
import WebKit

class AsyncPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel, AsyncPaymentMethodTokenizationViewModelProtocol {
    
    var willPresentPaymentMethod: (() -> Void)?
    var didPresentPaymentMethod: (() -> Void)?
    var willDismissPaymentMethod: (() -> Void)?
    var didDismissPaymentMethod: (() -> Void)?
    private var webViewController: PrimerWebViewController?
    private var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    private let theme: PrimerThemeProtocol = DependencyContainer.resolve()
    
    private var onClientToken: ((_ clientToken: String?, _ err: Error?) -> Void)?
    
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
        
        var pollingURLs: PollingURLs!
        
        firstly {
            self.tokenize()
        }
        .then { paymentMethod -> Promise<PollingURLs> in
            self.paymentMethod = paymentMethod
            return self.fetchPollingURLs(for: paymentMethod)
        }
        .then { pollingURLsResponse -> Promise<Void> in
            pollingURLs = pollingURLsResponse
            
            guard let redirectUrl = pollingURLs.redirectUrl else {
                throw PrimerError.invalidValue(key: "redirectUrl")
            }
            
            return self.presentAsyncPaymentMethod(with: redirectUrl)
        }
        .then { () -> Promise<String> in
            guard let statusUrl = pollingURLs.statusUrl else {
                throw PrimerError.invalidValue(key: "statusUrl")
            }
            
            return self.startPolling(on: statusUrl)
        }
        .then { resumeToken -> Promise<PaymentMethodToken> in
            self.willDismissPaymentMethod?()
            self.webViewController?.presentingViewController?.dismiss(animated: true, completion: {
                self.didDismissPaymentMethod?()
            })
            return self.passResumeToken(resumeToken)
        }
        .done { paymentMethod in
            DispatchQueue.main.async {
                self.paymentMethod = paymentMethod
                
                if Primer.shared.flow.internalSessionFlow.vaulted {
                    Primer.shared.delegate?.tokenAddedToVault?(paymentMethod)
                }
                
                self.handleSuccessfulTokenizationFlow()
            }
        }
        .catch { err in
            DispatchQueue.main.async {
                Primer.shared.delegate?.checkoutFailed?(with: err)
                self.handleFailedTokenizationFlow(error: err)
            }
        }
    }
    
    private func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            guard let configId = config.id else {
                seal.reject(PrimerError.configFetchFailed)
                return
            }

            let request = AsyncPaymentMethodTokenizationRequest(
                paymentInstrument: AsyncPaymentMethodOptions(
                    paymentMethodType: config.type, paymentMethodConfigId: configId))
            
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            firstly {
                tokenizationService.tokenize(request: request)
            }
            .done{ paymentMethod in
                seal.fulfill(paymentMethod)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func fetchPollingURLs(for paymentMethod: PaymentMethodToken) -> Promise<PollingURLs> {
        return Promise { seal in
            self.onClientToken = { (clientToken, err) in
                if let err = err {
                    seal.reject(err)
                } else if let clientToken = clientToken {
                    let state: AppStateProtocol = DependencyContainer.resolve()
                    if let decodedClientToken = state.decodedClientToken {
                        if let intent = decodedClientToken.intent {
                            if let redirectUrl = decodedClientToken.redirectUrl,
                               let statusUrl = decodedClientToken.statusUrl {
                                seal.fulfill(PollingURLs(status: statusUrl, redirect: redirectUrl, complete: nil))
                                return
                            }
                        }
                        
                    }
                    
                    let err = PrimerError.invalidValue(key: "polling params")
                    seal.reject(err)
                } else {
                    assert(true, "Should have received one parameter")
                }
            }
            
            DispatchQueue.main.async {
                Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, resumeHandler: self)
            }
        }
    }
    
    private func presentAsyncPaymentMethod(with url: URL) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.webViewController = PrimerWebViewController(with: url)
                self.webViewController?.navigationDelegate = self
                self.webViewController!.modalPresentationStyle = .fullScreen
                
                self.willPresentPaymentMethod?()
                Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: {
                    self.didPresentPaymentMethod?()
                    seal.fulfill(())
                })
            }
        }
    }
    
    private func startPolling(on url: URL) -> Promise<String> {
        return Promise { seal in
            self.startPolling(on: url) { (id, err) in
                if let err = err {
                    seal.reject(err)
                } else if let id = id {
                    seal.fulfill(id)
                } else {
                    assert(true, "Should have received one parameter")
                }
            }
        }
    }
    
    private func startPolling(on url: URL, completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.poll(clientToken: state.decodedClientToken, url: url.absoluteString) { result in
            switch result {
            case .success(let res):
                if res.status == .pending {
                    self.startPolling(on: url, completion: completion)
                } else if res.status == .complete {
                    completion(res.id, nil)
                } else {
                    // Do what here?
                    fatalError()
                }
            case .failure(let err):
                let nsErr = err as NSError
                if nsErr.domain == NSURLErrorDomain && nsErr.code == -1001 {
                    // Retry
                    self.startPolling(on: url, completion: completion)
                } else {
                    completion(nil, err)
                }
            }
        }
    }
    
    private func passResumeToken(_ resumeToken: String) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            self.completion = { (paymentMethod, err) in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethod = paymentMethod {
                    seal.fulfill(paymentMethod)
                } else {
                    assert(true, "Should have received one parameter")
                }
            }
            
            DispatchQueue.main.async {
                Primer.shared.delegate?.onResumeSuccess?(resumeToken, resumeHandler: self)
            }
        }
    }
    
}

extension AsyncPaymentMethodTokenizationViewModel: WKNavigationDelegate {
    
    func webView(
        _ webView: WKWebView,
        decidePolicyFor navigationAction: WKNavigationAction,
        decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
    ) {
        let allowedHosts: [String] = [
            "primer.io",
            "livedemostore.primer.io"
        ]

        if let url = navigationAction.request.url, let host = url.host, allowedHosts.contains(host) {
            decisionHandler(.allow)
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

extension AsyncPaymentMethodTokenizationViewModel {
    
    override func handle(error: Error) {
        // onClientToken will be created when we're awaiting a new client token from the developer
        onClientToken?(nil, error)
        onClientToken = nil
        // completion will be created when we're awaiting the payment response
        completion?(nil, error)
        completion = nil
    }
    
    override func handle(newClientToken clientToken: String) {
        do {
            try ClientTokenService.storeClientToken(clientToken)
            onClientToken?(clientToken, nil)
            onClientToken = nil
        } catch {
            onClientToken?(nil, error)
            onClientToken = nil
        }
    }
    
    override func handleSuccess() {
        // completion will be created when we're awaiting the payment response
        completion?(self.paymentMethod, nil)
        completion = nil
    }
    
}

enum PollingStatus: String, Codable {
    case pending = "PENDING"
    case complete = "COMPLETE"
}

struct PollingResponse: Decodable {
    let status: PollingStatus
    let id: String
    let source: String
    let urls: PollingURLs
}

struct PollingURLs: Decodable {
    let status: String
    lazy var statusUrl: URL? = {
        return URL(string: status)
    }()
    let redirect: String
    lazy var redirectUrl: URL? = {
        return URL(string: redirect)
    }()
    let complete: String?
}

