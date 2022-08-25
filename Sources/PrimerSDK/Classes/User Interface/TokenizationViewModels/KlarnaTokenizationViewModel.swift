#if canImport(UIKit)

import Foundation
import UIKit

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif

class KlarnaTokenizationViewModel: PaymentMethodTokenizationViewModel {
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?
    
#if canImport(PrimerKlarnaSDK)
    private var klarnaViewController: PrimerKlarnaViewController?
#endif
    private var klarnaPaymentSession: KlarnaCreatePaymentSessionAPIResponse?
    private var klarnaCustomerTokenAPIResponse: KlarnaCustomerTokenAPIResponse?
    private var klarnaPaymentSessionCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    private var authorizationToken: String?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self.self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        let klarnaSessionType: KlarnaSessionType = Primer.shared.intent == .vault ? .recurringPayment : .hostedPaymentPage
        
        if Primer.shared.intent == .checkout && AppState.current.amount == nil  {
            let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if case .hostedPaymentPage = klarnaSessionType {
            if AppState.current.amount == nil {
                let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if AppState.current.currency == nil {
                let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if (AppState.current.apiConfiguration?.clientSession?.order?.lineItems ?? []).isEmpty {
                let err = PrimerError.invalidValue(key: "lineItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if !(AppState.current.apiConfiguration?.clientSession?.order?.lineItems ?? []).filter({ $0.amount == nil }).isEmpty {
                let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                throw err
            }
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
#if canImport(PrimerKlarnaSDK)
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
            .then { () -> Promise<KlarnaCreatePaymentSessionAPIResponse> in
                return self.createPaymentSession()
            }
            .then { session -> Promise<Void> in
                self.klarnaPaymentSession = session
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<KlarnaCustomerTokenAPIResponse> in
                return self.authorizePaymentSession(authorizationToken: self.authorizationToken!)
            }
            .done { klarnaCustomerTokenAPIResponse in
                self.klarnaCustomerTokenAPIResponse = klarnaCustomerTokenAPIResponse
                DispatchQueue.main.async {
                    self.willDismissExternalView?()
                }
                
                seal.fulfill()
            }
            .ensure {
                self.willDismissExternalView?()
                self.klarnaViewController?.dismiss(animated: true, completion: {
                    self.didDismissExternalView?()
                })
            }
            .catch { err in
                seal.reject(err)
            }
#else
            let err = PrimerError.failedToFindModule(name: "Primer/Klarna", userInfo: nil, diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            seal.reject(err)
#endif
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
            .done {
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
    
    override func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
#if canImport(PrimerKlarnaSDK)
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                
                self.klarnaViewController = PrimerKlarnaViewController(
                    delegate: self,
                    paymentCategory: .payLater,
                    clientToken: self.klarnaPaymentSession!.clientToken,
                    urlScheme: settings.paymentMethodOptions.urlScheme)
                
                //                Primer.shared.primerRootVC?.present(self.klarnaViewController!, animated: true, completion: {
                //                    self.didPresentExternalView?()
                //                    seal.fulfill()
                //                })
                self.klarnaPaymentSessionCompletion = { _, err in
                    if let err = err {
                        seal.reject(err)
                    } else {
                        fatalError()
                    }
                }
                
                self.willPresentExternalView?()
                Primer.shared.primerRootVC?.show(viewController: self.klarnaViewController!)
                self.didPresentExternalView?()
                seal.fulfill()
#else
                
#endif
            }
        }
    }
    
    override func awaitUserInput() -> Promise<Void> {
        return Promise { seal in
            self.klarnaPaymentSessionCompletion = { authorizationToken, err in
                if let err = err {
                    seal.reject(err)
                } else if let authorizationToken = authorizationToken {
                    self.authorizationToken = authorizationToken
                    seal.fulfill()
                } else {
                    precondition(false, "Should never end up in here")
                }
            }
        }
    }
    
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            var instrument: PaymentInstrument
            var request: PaymentMethodTokenizationRequest
            
            if Primer.shared.intent == .vault {
                instrument = PaymentInstrument(
                    klarnaAuthorizationToken: self.authorizationToken!,
                    sessionData: self.klarnaCustomerTokenAPIResponse!.sessionData)
                
                request = PaymentMethodTokenizationRequest(
                    paymentInstrument: instrument,
                    paymentFlow: .vault)
                
            } else {
                instrument = PaymentInstrument(
                    klarnaCustomerToken: self.klarnaCustomerTokenAPIResponse!.customerTokenId,
                    sessionData: self.klarnaCustomerTokenAPIResponse!.sessionData)
                
                request = PaymentMethodTokenizationRequest(
                    paymentInstrument: instrument,
                    paymentFlow: .checkout)
            }
            
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            
            firstly {
                tokenizationService.tokenize(request: request)
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    private func createPaymentSession() -> Promise<KlarnaCreatePaymentSessionAPIResponse> {
        return Promise { seal in
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let configId = config.id else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let klarnaSessionType: KlarnaSessionType = Primer.shared.intent == .vault ? .recurringPayment : .hostedPaymentPage
            
            var amount = AppState.current.amount
            if amount == nil && Primer.shared.intent == .checkout {
                let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            var orderItems: [OrderItem]? = nil
            
            if case .hostedPaymentPage = klarnaSessionType {
                if amount == nil {
                    let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                if AppState.current.currency == nil {
                    let err = PrimerError.invalidSetting(name: "currency", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                if (AppState.current.apiConfiguration?.clientSession?.order?.lineItems ?? []).isEmpty {
                    let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                if !(AppState.current.apiConfiguration?.clientSession?.order?.lineItems ?? []).filter({ $0.amount == nil }).isEmpty {
                    let err = PrimerError.invalidValue(key: "settings.orderItems.amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                orderItems = AppState.current.apiConfiguration?.clientSession?.order?.lineItems?.compactMap({ try? $0.toOrderItem() })
                
                log(logLevel: .info, message: "Klarna amount: \(amount!) \(AppState.current.currency!.rawValue)")
                
            } else if case .recurringPayment = klarnaSessionType {
                // Do not send amount for recurring payments, even if it's set
                amount = nil
            }
                        
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            let body = KlarnaCreatePaymentSessionAPIRequest(
                paymentMethodConfigId: configId,
                sessionType: .recurringPayment,
                localeData: PrimerSettings.current.localeData,
                description: PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
                redirectUrl: settings.paymentMethodOptions.urlScheme,
                totalAmount: nil,
                orderItems: nil)
            
            let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
            
            api.createKlarnaPaymentSession(clientToken: decodedClientToken, klarnaCreatePaymentSessionAPIRequest: body) { [weak self] (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                    
                case .success(let res):
                    log(
                        logLevel: .info,
                        message: "\(res)",
                        className: "\(String(describing: self.self))",
                        function: #function
                    )
                    
                    self?.klarnaPaymentSession = res
                    
                    guard URL(string: res.hppRedirectUrl) != nil else {
                        let err = PrimerError.invalidValue(key: "hppRedirectUrl", value: res.hppRedirectUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        seal.reject(err)
                        return
                    }
                    
                    seal.fulfill(res)
                }
            }
        }
    }
    
    private func authorizePaymentSession(authorizationToken: String) -> Promise<KlarnaCustomerTokenAPIResponse> {
        return Promise { seal in
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let configId = AppState.current.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.klarna.rawValue),
                  let sessionId = self.klarnaPaymentSession?.sessionId else {
                let err = PrimerError.missingPrimerConfiguration(
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let body = CreateKlarnaCustomerTokenAPIRequest(
                paymentMethodConfigId: configId,
                sessionId: sessionId,
                authorizationToken: authorizationToken,
                description: PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
                localeData: PrimerSettings.current.localeData
            )
            
            let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
            
            api.createKlarnaCustomerToken(clientToken: decodedClientToken, klarnaCreateCustomerTokenAPIRequest: body) { (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let response):
                    seal.fulfill(response)
                }
            }
        }
    }
    
    private func finalizePaymentSession() -> Promise<KlarnaCustomerTokenAPIResponse> {
        return Promise { seal in
            self.finalizePaymentSession { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let res):
                    seal.fulfill(res)
                }
            }
        }
    }
    
    private func finalizePaymentSession(completion: @escaping (Result<KlarnaCustomerTokenAPIResponse, Error>) -> Void) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        guard let configId = AppState.current.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.klarna.rawValue),
              let sessionId = self.klarnaPaymentSession?.sessionId else {
            let err = PrimerError.missingPrimerConfiguration(
                userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(.failure(err))
            return
        }
        
        let body = KlarnaFinalizePaymentSessionRequest(paymentMethodConfigId: configId, sessionId: sessionId)
        log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "finalizePaymentSession")
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.finalizeKlarnaPaymentSession(clientToken: decodedClientToken, klarnaFinalizePaymentSessionRequest: body) { (result) in
            switch result {
            case .failure(let err):
                completion(.failure(err))
            case .success(let response):
                log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createPaymentSession")
                completion(.success(response))
            }
        }
    }
}

#if canImport(PrimerKlarnaSDK)
extension KlarnaTokenizationViewModel: PrimerKlarnaViewControllerDelegate {
    
    func primerKlarnaViewDidLoad() {
        
    }
    
    func primerKlarnaPaymentSessionCompleted(authorizationToken: String?, error: PrimerKlarnaError?) {
        self.klarnaPaymentSessionCompletion?(authorizationToken, error)
        self.klarnaPaymentSessionCompletion = nil
    }
}
#endif

#endif
