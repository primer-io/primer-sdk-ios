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
    
    override lazy var title: String = {
        switch config.type {
        case .aliPay:
            return "Ali Pay"
        case .giropay:
            return "Giropay"
        case .hoolah:
            return "Hoolah"
        case .payNLIdeal:
            return "Pay NL Ideal"
        case .sofort:
            return "Sofort"
        case .twint:
            return "Twint"
        case .trustly:
            return "Trustly"
        default:
            assert(true, "Shouldn't end up in here")
            return ""
        }
    }()
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        case .aliPay,
                .giropay,
                .hoolah,
                .payNLIdeal,
                .sofort,
                .twint,
                .trustly:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
        switch config.type {
        case .aliPay:
            return UIImage(named: "alipay-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .giropay:
            return UIImage(named: "giropay-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .hoolah:
            return UIImage(named: "hoolah-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .payNLIdeal:
            return UIImage(named: "iDeal-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .sofort:
            return UIImage(named: "sofort-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        case .twint:
            return UIImage(named: "twint-logo", in: Bundle.primerResources, compatibleWith: nil)
        case .trustly:
            return UIImage(named: "trustly-logo", in: Bundle.primerResources, compatibleWith: nil)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonColor: UIColor? = {
        switch config.type {
        case .aliPay:
            return UIColor(red: 49.0/255, green: 177.0/255, blue: 240.0/255, alpha: 1.0)
        case .giropay:
            return UIColor(red: 0, green: 2.0/255, blue: 104.0/255, alpha: 1.0)
        case .hoolah:
            return UIColor(red: 214.0/255, green: 55.0/255, blue: 39.0/255, alpha: 1.0)
        case .payNLIdeal:
            return UIColor(red: 204.0/255, green: 0.0, blue: 102.0/255, alpha: 1.0)
        case .sofort:
            return UIColor(red: 239.0/255, green: 128.0/255, blue: 159.0/255, alpha: 1.0)
        case .twint:
            return .black
        case .trustly:
            return UIColor(red: 14.0/255, green: 224.0/255, blue: 110.0/255, alpha: 1.0)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .aliPay,
                .giropay,
                .hoolah,
                .payNLIdeal,
                .twint,
                .trustly:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .aliPay,
                .giropay,
                .hoolah,
                .payNLIdeal,
                .twint,
                .trustly:
            return 0.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .aliPay,
                .giropay,
                .hoolah,
                .payNLIdeal,
                .twint,
                .trustly:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .aliPay,
                .hoolah,
                .payNLIdeal,
                .sofort:
            return .white
        case .trustly:
            return .black
        case .giropay,
                .twint:
            return nil
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
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?
    fileprivate var webViewController: SFSafariViewController?
    /// I n this case the **webViewCompletion** won't return an authorzation token, a **resumeToken** will be return
    /// from polling.
    fileprivate var webViewCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    fileprivate var onResumeTokenCompletion: ((_ paymentMethod: PaymentMethodToken?, _ error: Error?) -> Void)?
    fileprivate var onClientToken: ((_ clientToken: String?, _ err: Error?) -> Void)?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        if state.decodedClientToken?.isValid != true {
            throw PrimerError.clientTokenNull
        }
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
                self.completion?(nil, error)
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
            DispatchQueue.main.async {
                self.willDismissExternalView?()
                self.webViewController?.dismiss(animated: true, completion: {
                    self.didDismissExternalView?()
                })
            }
            return self.passResumeToken(resumeToken)
        }
        .done { paymentMethod in
            self.paymentMethod = paymentMethod
            
            DispatchQueue.main.async {
                if Primer.shared.flow.internalSessionFlow.vaulted {
                    Primer.shared.delegate?.tokenAddedToVault?(paymentMethod)
                }
                
                self.completion?(self.paymentMethod, nil)
                self.handleSuccessfulTokenizationFlow()
            }
        }
        .ensure { [unowned self] in
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
                Primer.shared.delegate?.checkoutFailed?(with: err)
                self.handleFailedTokenizationFlow(error: err)
            }
        }
    }
    
    fileprivate func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            guard let configId = config.id else {
                seal.reject(PrimerError.configFetchFailed)
                return
            }
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            var sessionInfo: PaymentMethod.AsyncPaymentMethod.SessionInfo?
            if let localeCode = settings.localeData.localeCode {
                sessionInfo = PaymentMethod.AsyncPaymentMethod.SessionInfo(locale: localeCode)
            }
            
            let request = PaymentMethodTokenizationRequest(
                paymentInstrument: PaymentMethod.AsyncPaymentMethod(
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
    
    fileprivate func fetchPollingURLs(for paymentMethod: PaymentMethodToken) -> Promise<PollingURLs> {
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
    
    fileprivate func presentAsyncPaymentMethod(with url: URL) -> Promise<Void> {
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
                    self.didPresentExternalView?()
                    seal.fulfill(())
                })
            }
        }
    }
    
    fileprivate func startPolling(on url: URL) -> Promise<String> {
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
        let state: AppStateProtocol = DependencyContainer.resolve()
        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.poll(clientToken: state.decodedClientToken, url: url.absoluteString) { result in
            if self.webViewCompletion == nil {
                completion(nil, PrimerError.userCancelled)
                return
            }
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
    
    fileprivate func passResumeToken(_ resumeToken: String) -> Promise<PaymentMethodToken> {
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
                Primer.shared.delegate?.onResumeSuccess?(resumeToken, resumeHandler: self)
            }
        }
    }
    
}

extension ExternalPaymentMethodTokenizationViewModel: SFSafariViewControllerDelegate {
    
    func safariViewControllerDidFinish(_ controller: SFSafariViewController) {
        if let webViewCompletion = webViewCompletion {
            // Cancelled
            webViewCompletion(nil, PrimerError.userCancelled)
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
        // onClientToken will be created when we're awaiting a new client token from the developer
        onClientToken?(nil, error)
        onClientToken = nil
        // onResumeTokenCompletion will be created when we're awaiting the payment response
        onResumeTokenCompletion?(nil, error)
        onResumeTokenCompletion = nil
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
        onResumeTokenCompletion?(self.paymentMethod, nil)
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

class MockAsyncPaymentMethodTokenizationViewModel: ExternalPaymentMethodTokenizationViewModel {
    
    var failValidation: Bool = false {
        didSet {
            let state: AppStateProtocol = DependencyContainer.resolve()
            state.decodedClientToken = nil
        }
    }
    var returnedPaymentMethodJson: String?
    
    fileprivate override func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            guard let _ = config.id else {
                seal.reject(PrimerError.configFetchFailed)
                return
            }

            if let returnedPaymentMethodJson = returnedPaymentMethodJson,
               let returnedPaymentMethodData = returnedPaymentMethodJson.data(using: .utf8),
                let paymentMethod = try? JSONDecoder().decode(PaymentMethodToken.self, from: returnedPaymentMethodData) {
                seal.fulfill(paymentMethod)
            } else {
                seal.reject(PrimerError.tokenizationRequestFailed)
            }
        }
    }
    
    fileprivate override func presentAsyncPaymentMethod(with url: URL) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.webViewController = SFSafariViewController(url: url)
                self.webViewController?.delegate = self
//                self.webViewController!.modalPresentationStyle = .fullScreen
                
                self.willPresentExternalView?()
                Timer.scheduledTimer(withTimeInterval: 1.0, repeats: false) { _ in
                    self.didPresentExternalView?()
                    seal.fulfill(())
                }
            }
        }
    }
    
    fileprivate override func startPolling(on url: URL, completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
//        {
//          "status" : "COMPLETE",
//          "id" : "4474848f-721d-4c35-9325-e287196f7016",
//          "source" : "WEBHOOK",
//          "urls" : {
//            "status" : "https:\/\/api.staging.primer.io\/resume-tokens\/4474848f-721d-4c35-9325-e287196f7016",
//            "redirect" : "https:\/\/api.staging.primer.io\/resume-tokens\/4474848f-721d-4c35-9325-e287196f7016\/complete?api_key=9e66ba99-e154-4e34-9d96-91777859b85b",
//            "complete" : "https:\/\/api.staging.primer.io\/resume-tokens\/4474848f-721d-4c35-9325-e287196f7016\/complete"
//          }
//        }
        completion("4474848f-721d-4c35-9325-e287196f7016", nil)
    }
    
}

#endif
