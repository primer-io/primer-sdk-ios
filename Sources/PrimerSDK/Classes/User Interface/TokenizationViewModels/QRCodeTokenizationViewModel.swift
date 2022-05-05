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
    
    private lazy var _title: String = {
        switch config.type {
        case .xfers:
            return "XFers"
        default:
            assert(true, "Shouldn't end up in here")
            return ""
        }
    }()
    override var title: String  {
        get { return _title }
        set { _title = newValue }
    }
    
    private lazy var _originalImage: UIImage? = {
        switch config.type {
        case .xfers:
            return UIImage(named: "pay-now-logo", in: Bundle.primerResources, compatibleWith: nil)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var originalImage: UIImage? {
        get { return _originalImage }
        set { _originalImage = newValue }
    }
    
    private lazy var _buttonImage: UIImage? = {
        switch config.type {
        case .xfers:
            return originalImage?.withRenderingMode(.alwaysTemplate)
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
        case .xfers:
            return UIColor(red: 148.0/255, green: 31.0/255, blue: 127.0/255, alpha: 1.0)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonColor: UIColor? {
        get { return _buttonColor }
        set { _buttonColor = newValue }
    }
    
    private lazy var _buttonTintColor: UIColor? = {
        switch config.type {
        case .xfers:
            return .white
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonTintColor: UIColor? {
        get { return _buttonTintColor }
        set { _buttonTintColor = newValue }
    }
    
    private var tokenizationService: TokenizationServiceProtocol?
    internal var qrCode: String?
    private var didCancel: (() -> Void)?
    
    deinit {
        tokenizationService = nil
        qrCode = nil
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
                place: .bankSelectionList))
        Analytics.Service.record(event: event)
    }
    
    func cancel() {
        didCancel?()
    }
    
    fileprivate func continueTokenizationFlow() {
        
        firstly {
            self.validateReturningPromise()
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
        .catch { error in
            if let primerErr = error as? PrimerError, case PrimerError.cancelled = primerErr {
                self.handleErrorBasedOnSDKSettings(error, isOnResumeFlow: true)
            } else {
                self.unselectPaymentMethodWithError(error)
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
    
    internal override func continueTokenizationFlow(for tmpPaymentMethod: PaymentMethodToken) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            var qrCodePollingURLs: QRCodePollingURLs!
            
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
                return self.fetchQRCodePollingURLs(for: tmpPaymentMethod)
            }
            .then { tmpQrCodePollingURLs -> Promise<Void> in
                qrCodePollingURLs = tmpQrCodePollingURLs
                return self.presentQRCodePaymentMethod()
            }
            .then { () -> Promise<String> in
                guard let statusUrl = qrCodePollingURLs.statusUrl else {
                    let err = PrimerError.invalidValue(key: "statusUrl", value: qrCodePollingURLs.statusUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    throw err
                }
                
                return self.startPolling(on: statusUrl)
            }
            .then { resumeToken -> Promise<PaymentMethodToken> in
                DispatchQueue.main.async {
                    Primer.shared.primerRootVC?.showLoadingScreenIfNeeded(imageView: self.makeSquareLogoImageView(withDimension: 24.0), message: nil)
                    self.willDismissExternalView?()
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
    
    fileprivate func fetchQRCodePollingURLs(for paymentMethod: PaymentMethodToken) -> Promise<QRCodePollingURLs> {
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
                           let statusUrl = decodedClientToken.statusUrl,
                           decodedClientToken.intent != nil {
                            seal.fulfill(QRCodePollingURLs(status: statusUrl, complete: nil))
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
                self.handleContinuePaymentFlowWithPaymentMethod(paymentMethod)
            }
        }
    }
    
    fileprivate func presentQRCodePaymentMethod() -> Promise<Void> {
        return Promise { seal in
            let qrcvc = QRCodeViewController(viewModel: self)
            Primer.shared.primerRootVC?.show(viewController: qrcvc)
            seal.fulfill(())
        }
    }
    
    internal override func startPolling(on url: URL) -> Promise<String> {
        let p: Promise? = Promise<String> { seal in
            self.didCancel = {
                let err = PrimerError.cancelled(paymentMethodType: .xfers, userInfo: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                self.pollingRetryTimer?.invalidate()
                self.pollingRetryTimer = nil
                return
            }
            
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
        
        return p!
    }
    
    var pollingRetryTimer: Timer?
    
    fileprivate func startPolling(on url: URL, completion: @escaping (_ id: String?, _ err: Error?) -> Void) {
        let client: PrimerAPIClientProtocol = DependencyContainer.resolve()
        client.poll(clientToken: ClientTokenService.decodedClientToken, url: url.absoluteString) { result in
            switch result {
            case .success(let res):
                if res.status == .pending {
                    self.pollingRetryTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { _ in
                        self.startPolling(on: url, completion: completion)
                        self.pollingRetryTimer?.invalidate()
                        self.pollingRetryTimer = nil
                    }
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
                    self.pollingRetryTimer = Timer.scheduledTimer(withTimeInterval: 3, repeats: false) { _ in
                        self.startPolling(on: url, completion: completion)
                        self.pollingRetryTimer?.invalidate()
                        self.pollingRetryTimer = nil
                    }
                } else {
                    completion(nil, err)
                }
            }
        }
    }
    
    override internal func passResumeToken(_ resumeToken: String) -> Promise<PaymentMethodToken> {
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

extension QRCodeTokenizationViewModel {
    
    override func executeCompletionAndNullifyAfter(error: Error? = nil) {
        super.executeCompletionAndNullifyAfter(error: error)
        onResumeTokenCompletion?(nil, error)
        onResumeTokenCompletion = nil
    }
    
    private func unselectPaymentMethodWithError(_ error: Error) {
        firstly {
            ClientSession.Action.unselectPaymentMethodIfNeeded()
        }
        .done {}
        .catch { error in
            self.handleErrorBasedOnSDKSettings(error)
        }
    }
}


extension QRCodeTokenizationViewModel {
    
    override func handle(error: Error) {
        firstly {
            ClientSession.Action.unselectPaymentMethodIfNeeded()
        }
        .ensure {
            self.executeCompletionAndNullifyAfter(error: error)
            self.handleFailureFlow(error: error)
        }
        .catch { _ in }
    }
    
    override func handle(newClientToken clientToken: String) {
        guard let decodedClientToken = clientToken.jwtTokenPayload else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            self.handleErrorBasedOnSDKSettings(err)
            return
        }
        
        if decodedClientToken.intent == "XFERS_PAYNOW_REDIRECTION" {
            if let qrCode = decodedClientToken.qrCode {
                self.qrCode = qrCode
                onClientToken?(clientToken, nil)
            } else {
                onClientToken?(clientToken, nil)
            }
            
        } else if decodedClientToken.intent?.contains("_REDIRECTION") == true {
            super.handle(newClientToken: clientToken)
        } else if decodedClientToken.intent == "CHECKOUT" {
            
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
            .catch { err in
                self.handleErrorBasedOnSDKSettings(err)
            }
        } else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            self.handleErrorBasedOnSDKSettings(err)
            return
        }
    }
    
    override func handleSuccess() {
        self.tokenizationCompletion?(self.paymentMethodTokenData, nil)
        self.tokenizationCompletion = nil
        self.onResumeTokenCompletion?(self.paymentMethodTokenData, nil)
        self.onResumeTokenCompletion = nil
    }
    
}

#endif

