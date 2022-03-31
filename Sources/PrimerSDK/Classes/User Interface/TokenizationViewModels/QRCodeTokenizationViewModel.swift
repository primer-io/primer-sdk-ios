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
        do {
            try validate()
        } catch {
            DispatchQueue.main.async {
                ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
                PrimerDelegateProxy.checkoutFailed(with: error)
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
            self.paymentMethod = paymentMethod
            
            DispatchQueue.main.async {

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
                if let primerErr = err as? PrimerError, case PrimerError.cancelled = primerErr {
                    PrimerDelegateProxy.onResumeError(err)
                } else {
                    PrimerDelegateProxy.checkoutFailed(with: err)
                    self.handleFailedTokenizationFlow(error: err)
                }
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
                PrimerDelegateProxy.onResumeSuccess(resumeToken, resumeHandler: self)
                                
                // Resume payment with Payment method token
                                
                guard let resumePaymentId = self.resumePaymentId else {
                    DispatchQueue.main.async {
                        // TODO: Raise appropriate error
                    }
                    return
                }
                
                let createResumePaymentService: CreateResumePaymentServiceProtocol = DependencyContainer.resolve()
                createResumePaymentService.resumePaymentWithPaymentId(resumePaymentId, paymentResumeRequest: Payment.ResumeRequest(token: resumeToken)) { paymentResponse, error in
                    
                    guard let paymentResponse = paymentResponse,
                          let paymentResponseDict = try? paymentResponse.asDictionary() else {
                              if let error = error {
                                  Primer.shared.delegate?.checkoutDidFailWithError?(error)
                                  self.handle(error: error)
                              }
                              return
                          }
                    
                    if paymentResponse.status == .pending, let requiredAction = paymentResponse.requiredAction {
                        Primer.shared.delegate?.onPaymentPending?(paymentResponseDict)
                        self.handle(newClientToken: requiredAction.clientToken)
                    } else {
                        Primer.shared.delegate?.checkoutDidCompleteWithPayment?(paymentResponseDict)
                        self.handleSuccess()
                    }
                }

            }
        }
    }
}

extension QRCodeTokenizationViewModel {
    
    override func handle(error: Error) {
        ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
        self.completion?(nil, error)
        self.completion = nil
        onResumeTokenCompletion?(nil, error)
        onResumeTokenCompletion = nil
    }
    
    override func handle(newClientToken clientToken: String) {
        guard let decodedClientToken = clientToken.jwtTokenPayload else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            self.handle(error: err)
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
                self.handle(error: err)
            }
        } else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            self.handle(error: err)
            return
        }
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
        self.onResumeTokenCompletion?(self.paymentMethod, nil)
        self.onResumeTokenCompletion = nil
    }
    
}


extension QRCodeTokenizationViewModel {
    
    private func handleContinuePaymentFlowWithPaymentMethod(_ paymentMethod: PaymentMethodToken) {
                
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if settings.isManualPaymentHandlingEnabled {
            
            PrimerDelegateProxy.onTokenizeSuccess(paymentMethod, resumeHandler: self)
            
        } else {
            
            guard let paymentMethodTokenString = paymentMethod.token else {
                
                DispatchQueue.main.async {
                    // TODO: Raise appropriate error
                }
                return
            }
            
            // Raise "payment creation started" event
            
            Primer.shared.delegate?.onPaymentWillCreate?(paymentMethodTokenString)
            
            // Create payment with Payment method token
            
            let createResumePaymentService: CreateResumePaymentServiceProtocol = DependencyContainer.resolve()
            createResumePaymentService.createPayment(paymentRequest: Payment.CreateRequest(token: paymentMethodTokenString)) { paymentResponse, error in
                
                guard let paymentResponse = paymentResponse,
                      let paymentResponseDict = try? paymentResponse.asDictionary() else {
                          if let error = error {
                              Primer.shared.delegate?.checkoutDidFailWithError?(error)
                              self.handle(error: error)
                          }
                          return
                      }
                
                self.resumePaymentId = paymentResponse.id

                if paymentResponse.status == .pending, let requiredAction = paymentResponse.requiredAction {
                    Primer.shared.delegate?.onPaymentPending?(paymentResponseDict)
                    self.handle(newClientToken: requiredAction.clientToken)
                } else {
                    Primer.shared.delegate?.checkoutDidCompleteWithPayment?(paymentResponseDict)
                    self.handleSuccess()
                }
            }
        }
    }
}

#endif

