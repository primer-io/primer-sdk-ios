//
//  QRCodeTokenizationViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos on 11/1/22.
//

#if canImport(UIKit)

import SafariServices
import UIKit

class QRCodeTokenizationViewModel: ExternalPaymentMethodTokenizationViewModel {
    
    override lazy var title: String = {
        switch config.type {
        case .xfers:
            return "XFers"
        default:
            assert(true, "Shouldn't end up in here")
            return ""
        }
    }()
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        case .xfers:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
        switch config.type {
        case .xfers:
            return UIImage(named: "xfers-logo", in: Bundle.primerResources, compatibleWith: nil)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonColor: UIColor? = {
        switch config.type {
        case .xfers:
            return UIColor(red: 2.0/255, green: 139.0/255, blue: 244.0/255, alpha: 1.0)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .xfers:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .xfers:
            return 0.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .xfers:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .xfers:
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
    
    private var tokenizationService: TokenizationServiceProtocol?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
    }
        
    @objc
    override func startTokenizationFlow() {
        super.startTokenizationFlow()
    }
    
    fileprivate func continueTokenizationFlow() {
        do {
            try validate()
        } catch {
            DispatchQueue.main.async {
                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                Primer.shared.delegate?.checkoutFailed?(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        
        
        firstly {
            self.tokenize()
        }
        .then { tmpPaymentMethod -> Promise<PaymentMethodToken> in
            self.paymentMethod = tmpPaymentMethod
            return self.continueTokenizationFlow(for: tmpPaymentMethod)
        }
        .done { paymentMethod in
            
        }
        .catch { err in
            
        }
        
//        firstly {
//            self.fetchBanks()
//        }
//        .then { banks -> Promise<PaymentMethodToken> in
//            self.banks = banks
//            self.dataSource = banks
//            let bsvc = BankSelectorViewController(viewModel: self)
//            DispatchQueue.main.async {
//                Primer.shared.primerRootVC?.show(viewController: bsvc)
//            }
//
//            return self.fetchPaymentMethodToken()
//        }
//        .then { tmpPaymentMethod -> Promise<PaymentMethodToken> in
//            self.paymentMethod = tmpPaymentMethod
//            return self.continueTokenizationFlow(for: tmpPaymentMethod)
//        }
//        .done { paymentMethod in
//            self.paymentMethod = paymentMethod
//
//            DispatchQueue.main.async {
//                if Primer.shared.flow.internalSessionFlow.vaulted {
//                    Primer.shared.delegate?.tokenAddedToVault?(paymentMethod)
//                }
//
//                self.completion?(self.paymentMethod, nil)
//                self.handleSuccessfulTokenizationFlow()
//            }
//        }
//        .ensure { [unowned self] in
//            DispatchQueue.main.async {
//                self.willDismissExternalView?()
//                self.webViewController?.dismiss(animated: true, completion: {
//                    self.didDismissExternalView?()
//                })
//            }
//
//            self.willPresentExternalView = nil
//            self.didPresentExternalView = nil
//            self.willDismissExternalView = nil
//            self.didDismissExternalView = nil
//            self.webViewController = nil
//            self.webViewCompletion = nil
//            self.onResumeTokenCompletion = nil
//            self.onClientToken = nil
//        }
//        .catch { err in
//            DispatchQueue.main.async {
//                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
//                Primer.shared.delegate?.checkoutFailed?(with: err)
//                self.handleFailedTokenizationFlow(error: err)
//            }
//        }
    }
    
    fileprivate func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            guard let configId = config.id else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let xfers = PaymentInstrumentType.unknown
            let pmt = PaymentMethodToken(token: "access_token", analyticsId: nil, tokenType: .singleUse, paymentInstrumentType: xfers, paymentInstrumentData: nil, vaultData: nil, threeDSecureAuthentication: nil)
            
            seal.fulfill(pmt)
            
//            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
//            var sessionInfo: AsyncPaymentMethodOptions.SessionInfo?
//            if let localeCode = settings.localeData.localeCode {
//                sessionInfo = AsyncPaymentMethodOptions.SessionInfo(locale: localeCode)
//            }
//
//            let request = AsyncPaymentMethodTokenizationRequest(
//                paymentInstrument: AsyncPaymentMethodOptions(
//                    paymentMethodType: config.type,
//                    paymentMethodConfigId: configId,
//                    sessionInfo: sessionInfo))
//
//            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
//            firstly {
//                tokenizationService.tokenize(request: request)
//            }
//            .done{ paymentMethod in
//                seal.fulfill(paymentMethod)
//            }
//            .catch { err in
//                seal.reject(err)
//            }
            
//            let mockedTempPaymentMethodToken = PaymentMethodToken
        }
    }
    
    internal override func continueTokenizationFlow(for tmpPaymentMethod: PaymentMethodToken) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            var pollingURLs: QRCodePolling!
            
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
                guard let qrCodePolling = pollingURLsResponse as? QRCodePolling else {
                    let err = PrimerError.invalidValue(key: "qrCode", value: "nil", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    throw err
                }
                pollingURLs = qrCodePolling
                
                return self.presentQRCodePaymentMethod(with: qrCodePolling.qrCode)
            }
            .then { () -> Promise<String> in
                guard let statusUrl = pollingURLs.statusUrl else {
                    let err = PrimerError.invalidValue(key: "statusUrl", value: pollingURLs.qrCode, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    throw err
                }
                
                return self.startPolling(on: statusUrl)
            }
            .then { resumeToken -> Promise<PaymentMethodToken> in
                DispatchQueue.main.async {
                    Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
                    
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
    
    internal func presentQRCodePaymentMethod(with qrCode: String) -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async { [unowned self] in
                self.willPresentExternalView?()
                
                let qrCodeViewController = QRCodeViewController(viewModel: self)
                Primer.shared.primerRootVC?.show(viewController: qrCodeViewController)
                self.didPresentExternalView?()
                seal.fulfill(())
            }
        }
    }
    
    override internal func startPolling(on url: URL) -> Promise<String> {
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
            Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { _ in
                completion("qr_code_resume_token", nil)
                
//                switch result {
//                case .success(let res):
//                    if res.status == .pending {
//                        self.startPolling(on: url, completion: completion)
//                    } else if res.status == .complete {
//                        completion(res.id, nil)
//                    } else {
//                        // Do what here?
//                        fatalError()
//                    }
//                case .failure(let err):
//                    let nsErr = err as NSError
//                    if nsErr.domain == NSURLErrorDomain && nsErr.code == -1001 {
//                        // Retry
//                        self.startPolling(on: url, completion: completion)
//                    } else {
//                        completion(nil, err)
//                    }
//                }
            }
        }
    }
    
//    internal func continueTokenizationFlow(for tmpPaymentMethod: PaymentMethodToken) -> Promise<PaymentMethodToken> {
//        return Promise { seal in
//            var pollingURLs: PollingURLs!
//
//            // Fallback when no **requiredAction** is returned.
//            self.onResumeTokenCompletion = { (paymentMethod, err) in
//                if let err = err {
//                    seal.reject(err)
//                } else if let paymentMethod = paymentMethod {
//                    seal.fulfill(paymentMethod)
//                } else {
//                    assert(true, "Should have received one parameter")
//                }
//            }
//
//            firstly {
//                return self.fetchPollingURLs(for: tmpPaymentMethod)
//            }
//            .then { pollingURLsResponse -> Promise<Void> in
//                pollingURLs = pollingURLsResponse
//
//                guard let redirectUrl = pollingURLs.redirectUrl else {
//                    let err = PrimerError.invalidValue(key: "redirectUrl", value: pollingURLs.redirectUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
//                    ErrorHandler.handle(error: err)
//                    throw err
//                }
//
//                return self.presentAsyncPaymentMethod(with: redirectUrl)
//            }
//            .then { () -> Promise<String> in
//                guard let statusUrl = pollingURLs.statusUrl else {
//                    let err = PrimerError.invalidValue(key: "statusUrl", value: pollingURLs.redirectUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
//                    ErrorHandler.handle(error: err)
//                    throw err
//                }
//
//                return self.startPolling(on: statusUrl)
//            }
//            .then { resumeToken -> Promise<PaymentMethodToken> in
//                DispatchQueue.main.async {
//                    Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
//
//                    self.willDismissExternalView?()
//                    self.webViewController?.dismiss(animated: true, completion: {
//                        self.didDismissExternalView?()
//                    })
//                }
//                return self.passResumeToken(resumeToken)
//            }
//            .done { paymentMethod in
//                seal.fulfill(paymentMethod)
//            }
//            .catch { err in
//                seal.reject(err)
//            }
//        }
//    }
}

extension QRCodeTokenizationViewModel {
    
    override func handle(error: Error) {
        ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
        self.completion?(nil, error)
        self.completion = nil
    }
    
    override func handle(newClientToken clientToken: String) {
        do {
            // For Apaya there's no redirection URL, once the webview is presented it will get its response from a URL redirection.
            // We'll end up in here only for surcharge.
            
            guard let decodedClientToken = clientToken.jwtTokenPayload else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                self.handle(error: err)
                return
            }
            
            if decodedClientToken.intent?.contains("_REDIRECTION") == true {
                super.handle(newClientToken: clientToken)
            } else if decodedClientToken.intent == "CHECKOUT" {
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
            } else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                self.handle(error: err)
                return
            }
        } catch {
            DispatchQueue.main.async {
                Primer.shared.delegate?.onResumeError?(error)
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

