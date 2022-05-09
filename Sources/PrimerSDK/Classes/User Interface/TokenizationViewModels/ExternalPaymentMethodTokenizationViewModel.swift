//
//  AsyncPaymentMethodTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 11/10/21.
//

#if canImport(UIKit)

import Foundation
import SafariServices
import UIKit

class ExternalPaymentMethodTokenizationViewModel: PaymentMethodTokenizationViewModel, ExternalPaymentMethodTokenizationViewModelProtocol {
    
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?
    var webViewController: SFSafariViewController?
    /**
     This completion handler will return an authorization token, which must be returned to the merchant to resume the payment. **webViewCompletion**
     must be set before presenting the webview and nullified once polling returns a result. At the same time the webview should be dismissed.
     */
    var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    var onResumeTokenCompletion: ((_ paymentMethod: PaymentMethodToken?, _ error: Error?) -> Void)?
    var onClientToken: ((_ clientToken: String?, _ err: Error?) -> Void)?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        if ClientTokenService.decodedClientToken?.isValid != true {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
    }
    
    @objc
    override func startTokenizationFlow() {
        DispatchQueue.main.async {
            UIApplication.shared.beginIgnoringInteractionEvents()
        }
        
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
        
        self.continueTokenizationFlow()
    }
    
    fileprivate func continueTokenizationFlow() {
        
        firstly {
            self.validateReturningPromise()
        }
        .then { () -> Promise<Void> in
            ClientSession.Action.selectPaymentMethodWithParametersIfNeeded(["paymentMethodType": self.config.type.rawValue])
        }
        .then { () -> Promise<Void> in
            self.handlePrimerWillCreatePaymentEvent(PaymentMethodData(type: self.config.type))
        }
        .then {
            self.tokenize()
        }
        .then { tmpPaymentMethodTokenData -> Promise<PaymentMethodToken> in
            self.paymentMethodTokenData = tmpPaymentMethodTokenData
            return self.continueTokenizationFlow(for: tmpPaymentMethodTokenData)
        }
        .done { paymentMethodTokenData in
            self.paymentMethodTokenData = paymentMethodTokenData
            
            DispatchQueue.main.async {
                self.tokenizationCompletion?(self.paymentMethodTokenData, nil)
            }
        }
        .ensure { [unowned self] in
            DispatchQueue.main.async {
                UIApplication.shared.endIgnoringInteractionEvents()
            }
            DispatchQueue.main.async {
                self.willDismissExternalView?()
                self.webViewController?.dismiss(animated: true, completion: {
                    self.didDismissExternalView?()
                })
            }
            
            self.willPresentExternalView = nil
            self.didPresentExternalView = nil
            self.willDismissExternalView = nil
            self.didDismissExternalView = nil
            self.webViewController = nil
            self.webViewCompletion = nil
            self.onResumeTokenCompletion = nil
            self.onClientToken = nil
        }
        .catch { err in
            DispatchQueue.main.async {
                PrimerDelegateProxy.primerDidFailWithError(err, data: nil, decisionHandler: nil)
                self.handleFailureFlow(error: err)
            }
        }
    }
    
    internal func continueTokenizationFlow(for tmpPaymentMethod: PaymentMethodToken) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            var pollingURLs: PollingURLs!
            
            // Fallback when no **requiredAction** is returned.
            self.onResumeTokenCompletion = { (paymentMethod, err) in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethod = paymentMethod {
                    seal.fulfill(paymentMethod)
                } else {
                    assert(true, "Should have received one parameter")
                }
            }
            
            firstly {
                return self.fetchPollingURLs(for: tmpPaymentMethod)
            }
            .then { pollingURLsResponse -> Promise<Void> in
                pollingURLs = pollingURLsResponse
                
                guard let redirectUrl = pollingURLs.redirectUrl else {
                    let err = PrimerError.invalidValue(key: "redirectUrl", value: pollingURLs.redirectUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    throw err
                }
                
                DispatchQueue.main.async {
                    UIApplication.shared.endIgnoringInteractionEvents()
                }
                
                return self.presentAsyncPaymentMethod(with: redirectUrl)
            }
            .then { () -> Promise<String> in
                guard let statusUrl = pollingURLs.statusUrl else {
                    let err = PrimerError.invalidValue(key: "statusUrl", value: pollingURLs.redirectUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    throw err
                }
                
                return self.startPolling(on: statusUrl)
            }
            .then { resumeToken -> Promise<PaymentMethodToken> in
                DispatchQueue.main.async {
                    Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
                    
                    self.willDismissExternalView?()
                    self.webViewController?.dismiss(animated: true, completion: {
                        self.didDismissExternalView?()
                    })
                }
                return self.passResumeToken(resumeToken)
            }
            .done { paymentMethod in
                seal.fulfill(paymentMethod)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    fileprivate func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            guard let configId = config.id else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            var sessionInfo: AsyncPaymentMethodOptions.SessionInfo?
            if let localeCode = settings.localeData.localeCode {
                sessionInfo = AsyncPaymentMethodOptions.SessionInfo(locale: localeCode)
            }
            
            let request = AsyncPaymentMethodTokenizationRequest(
                paymentInstrument: AsyncPaymentMethodOptions(
                    paymentMethodType: config.type,
                    paymentMethodConfigId: configId,
                    sessionInfo: sessionInfo))
            
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
    
    internal func fetchPollingURLs(for paymentMethodTokenData: PaymentMethodTokenData) -> Promise<PollingURLs> {
        return Promise { seal in
            self.onClientToken = { (clientToken, error) in
                
                guard error == nil else {
                    seal.reject(error!)
                    return
                }
                
                if let clientToken = clientToken {
                    ClientTokenService.storeClientToken(clientToken) { error in
                        guard error == nil else {
                            seal.reject(error!)
                            return
                        }
                        
                        if let decodedClientToken = ClientTokenService.decodedClientToken,
                           let redirectUrl = decodedClientToken.redirectUrl,
                           let statusUrl = decodedClientToken.statusUrl,
                           decodedClientToken.intent != nil {
                            seal.fulfill(PollingURLs(status: statusUrl, redirect: redirectUrl, complete: nil))
                            return
                        }
                    }
                } else {
                    let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    seal.reject(error)
                    return
                }
            }
            
            DispatchQueue.main.async {
                // FIXME: This will not work, needs fixing
                self.paymentMethodTokenData = paymentMethodTokenData
                
                if Primer.shared.flow.internalSessionFlow.vaulted {
                    self.executeTokenizationCompletionAndNullifyAfter(paymentMethodTokenData: paymentMethodTokenData, error: nil)
                    self.executeCompletionAndNullifyAfter()
                } else {
                    self.startPaymentFlow(withPaymentMethodTokenData: self.paymentMethodTokenData!)
                }
            }
        }
    }
    
    internal func presentAsyncPaymentMethod(with url: URL) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.willPresentExternalView?()
                
                self.webViewCompletion = { (id, err) in
                    if let err = err {
                        seal.reject(err)
                    }
                }
                
                self.webViewController = SFSafariViewController(url: url)
                self.webViewController?.delegate = self
                
                self.willPresentExternalView?()
                Primer.shared.primerRootVC?.present(self.webViewController!, animated: true, completion: {
                    DispatchQueue.main.async {
                        PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutPaymentMethodPresented()
                        self.didPresentExternalView?()
                        seal.fulfill(())
                    }
                })
            }
        }
    }
    
    internal func startPolling(on url: URL) -> Promise<String> {
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
    
    fileprivate func startPolling(on url: URL, completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.poll(clientToken: ClientTokenService.decodedClientToken, url: url.absoluteString) { result in
            if self.webViewCompletion == nil {
                let err = PrimerError.cancelled(paymentMethodType: self.config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                completion(nil, err)
                return
            }
            
            switch result {
            case .success(let res):
                if res.status == .pending {
                    Timer.scheduledTimer(withTimeInterval: 1, repeats: false) { _ in
                        self.startPolling(on: url, completion: completion)
                    }
                } else if res.status == .complete {
                    completion(res.id, nil)
                } else {
                    let err = PrimerError.generic(message: "Should never end up here", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                }
            case .failure(let err):
                ErrorHandler.handle(error: err)
                // Retry
                Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                    self.startPolling(on: url, completion: completion)
                }
            }
        }
    }
    
    internal func passResumeToken(_ resumeToken: String) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            
            self.onResumeTokenCompletion = { (paymentMethod, err) in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethod = paymentMethod {
                    seal.fulfill(paymentMethod)
                } else {
                    assert(true, "Should have received one parameter")
                }
            }
            
            DispatchQueue.main.async {
                self.handleResumeStepsBasedOnSDKSettings(resumeToken: resumeToken)
            }
        }
    }
}

extension ExternalPaymentMethodTokenizationViewModel: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion = webViewCompletion {
            // Cancelled
            let err = PrimerError.cancelled(paymentMethodType: config.type, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            webViewCompletion(nil, err)
        }
        
        webViewCompletion = nil
    }
    
    func safariViewController(_ controller: SFSafariViewController, didCompleteInitialLoad didLoadSuccessfully: Bool) {
        if didLoadSuccessfully {
            self.didPresentExternalView?()
        }
    }
}

extension ExternalPaymentMethodTokenizationViewModel {
    
    override func handle(error: Error) {
        
        firstly {
            ClientSession.Action.unselectPaymentMethodIfNeeded()
        }
        .ensure {
            self.executeCompletionAndNullifyAfter(error: error)
            // onResumeTokenCompletion will be created when we're awaiting the payment response
            self.onResumeTokenCompletion?(nil, error)
            self.onResumeTokenCompletion = nil
        }
        .catch { _ in }
    }
    
    override func handle(newClientToken clientToken: String) {
        
        firstly {
            ClientTokenService.storeClientToken(clientToken)
        }
        .then{ () -> Promise<Void> in
            let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            return configService.fetchConfig()
        }
        .done { [weak self] in
            
            let decodedClientToken = ClientTokenService.decodedClientToken!
            
            if decodedClientToken.intent?.contains("_REDIRECTION") == true {
                self?.onClientToken?(clientToken, nil)
                self?.onClientToken = nil
                
            } else {
                let configService: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
                
                firstly {
                    configService.fetchConfig()
                }
                .done {
                    self?.continueTokenizationFlow()
                }
                .catch { error in
                    self?.raisePrimerDidFailWithError(error)
                }
            }
        }
        .catch { error in
            self.raisePrimerDidFailWithError(error)
        }
    }
    
    override func handleSuccess() {
        // completion will be created when we're awaiting the payment response
        onResumeTokenCompletion?(self.paymentMethodTokenData, nil)
        onResumeTokenCompletion = nil
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

struct QRCodePollingURLs: Decodable {
    let status: String
    lazy var statusUrl: URL? = {
        return URL(string: status)
    }()
    let complete: String?
}

#endif
