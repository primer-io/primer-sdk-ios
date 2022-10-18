//
//  KlarnaTokenizationModule.swift
//  PrimerSDK
//
//  Created by Evangelos on 17/10/22.
//

#if canImport(UIKit)

import Foundation
#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif
import UIKit

class KlarnaTokenizationModule: TokenizationModule {
    
    private var klarnaPaymentSession: Response.Body.Klarna.CreatePaymentSession?
#if canImport(PrimerKlarnaSDK)
    private var klarnaViewController: PrimerKlarnaViewController?
#endif
    private var klarnaPaymentSessionCompletion: ((_ authorizationToken: String?, _ error: Error?) -> Void)?
    private var authorizationToken: String?
    private var klarnaCustomerTokenAPIResponse: Response.Body.Klarna.CustomerToken?
    
    override func validate() -> Promise<Void> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard decodedJWTToken.pciUrl != nil else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard self.paymentMethodModule.paymentMethodConfiguration.id != nil else {
                let err = PrimerError.invalidValue(key: "configuration.id", value: self.paymentMethodModule.paymentMethodConfiguration.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let klarnaSessionType: KlarnaSessionType = PrimerInternal.shared.intent == .vault ? .recurringPayment : .hostedPaymentPage
            
            if PrimerInternal.shared.intent == .checkout && AppState.current.amount == nil  {
                let err = PrimerError.invalidSetting(name: "amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            if case .hostedPaymentPage = klarnaSessionType {
                if AppState.current.amount == nil {
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
                
                if (PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems ?? []).isEmpty {
                    let err = PrimerError.invalidValue(key: "lineItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                if !(PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems ?? []).filter({ $0.amount == nil }).isEmpty {
                    let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
            }
            
            seal.fulfill()
        }
    }
    
    override func start() -> Promise<PrimerPaymentMethodTokenData> {
//        NotificationCenter.default.addObserver(self, selector: #selector(self.receivedNotification(_:)), name: Notification.Name.urlSchemeRedirect, object: nil)
        
        return super.start()
    }
    
    override func performPreTokenizationSteps() -> Promise<Void> {
        let event = Analytics.Event(
            eventType: .ui,
            properties: UIEventProperties(
                action: .click,
                context: Analytics.Event.Property.Context(
                    issuerId: nil,
                    paymentMethodType: self.paymentMethodModule.paymentMethodConfiguration.type,
                    url: nil),
                extra: nil,
                objectType: .button,
                objectId: .select,
                objectClass: "\(Self.self)",
                place: .paymentMethodPopup))
        Analytics.Service.record(event: event)
        
        PrimerUIManager.primerRootViewController?.showLoadingScreenIfNeeded(imageView: self.paymentMethodModule.userInterfaceModule.makeIconImageView(withDimension: 24.0), message: nil)
        
        return Promise { seal in
#if canImport(PrimerKlarnaSDK)
            firstly {
                self.validate()
            }
            .then { () -> Promise<Void> in
                let clientSessionActionsModule: ClientSessionActionsProtocol = ClientSessionActionsModule()
                return clientSessionActionsModule.selectPaymentMethodIfNeeded(self.paymentMethodModule.paymentMethodConfiguration.type, cardNetwork: nil)
            }
            .then { () -> Promise<Void> in
                return self.firePrimerWillCreatePaymentEvent(PrimerPaymentMethodData(type: self.paymentMethodModule.paymentMethodConfiguration.type))
            }
            .then { () -> Promise<Response.Body.Klarna.CreatePaymentSession> in
                return self.createPaymentSession()
            }
            .then { () -> Promise<Void> in
                return self.paymentMethodModule.checkouEventsNotifierModule.fireWillPresentPaymentMethodUI()
            }
            .then { session -> Promise<Void> in
                self.klarnaPaymentSession = session
                return self.presentPaymentMethodUserInterface()
            }
            .then { () -> Promise<Void> in
                return self.paymentMethodModule.checkouEventsNotifierModule.fireDidPresentPaymentMethodUI()
            }
            .then { () -> Promise<Void> in
                return self.awaitUserInput()
            }
            .then { () -> Promise<Response.Body.Klarna.CustomerToken> in
                return self.authorizePaymentSession(authorizationToken: self.authorizationToken!)
            }
            .done { klarnaCustomerTokenAPIResponse in
                self.klarnaCustomerTokenAPIResponse = klarnaCustomerTokenAPIResponse
                DispatchQueue.main.async {
//                    self.willDismissExternalView?()
                }
                
                seal.fulfill()
            }
            .ensure {
//                self.willDismissExternalView?()
                self.klarnaViewController?.dismiss(animated: true, completion: {
//                    self.didDismissExternalView?()
                })
            }
            .catch { err in
                seal.reject(err)
            }
#else
            let err = PrimerError.failedToFindModule(name: "PrimerKlarnaSDK", userInfo: nil, diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            seal.reject(err)
#endif
        }
    }
    
    override func performTokenizationStep() -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.paymentMethodModule.checkouEventsNotifierModule.fireDidStartTokenizationEvent()
            }
            .then { () -> Promise<PrimerPaymentMethodTokenData> in
                return self.tokenize()
            }
            .then { paymentMethodTokenData -> Promise<Void> in
                self.paymentMethodTokenData = paymentMethodTokenData
                return self.paymentMethodModule.checkouEventsNotifierModule.fireDidFinishTokenizationEvent()
            }
            .done {
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
    override func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let klarnaCustomerToken = self.klarnaCustomerTokenAPIResponse?.customerTokenId else {
                let err = PrimerError.invalidValue(key: "tokenization.klarnaCustomerToken", value: nil, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let sessionData = self.klarnaCustomerTokenAPIResponse?.sessionData else {
                let err = PrimerError.invalidValue(key: "tokenization.sessionData", value: nil, userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let paymentInstrument = KlarnaCustomerTokenPaymentInstrument(
                klarnaCustomerToken: klarnaCustomerToken,
                sessionData: sessionData)
            
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            
            firstly {
                tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
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
    
    // MARK: - KLARNA SPECIFIC FUNCTIONALITY
    
    private func createPaymentSession() -> Promise<Response.Body.Klarna.CreatePaymentSession> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let configId = self.paymentMethodModule.paymentMethodConfiguration.id else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let klarnaSessionType: KlarnaSessionType = PrimerInternal.shared.intent == .vault ? .recurringPayment : .hostedPaymentPage
            
            var amount = AppState.current.amount
            if amount == nil && PrimerInternal.shared.intent == .checkout {
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
                
                if (PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems ?? []).isEmpty {
                    let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                if !(PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems ?? []).filter({ $0.amount == nil }).isEmpty {
                    let err = PrimerError.invalidValue(key: "settings.orderItems.amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                orderItems = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.order?.lineItems?.compactMap({ try? $0.toOrderItem() })
                
                log(logLevel: .info, message: "Klarna amount: \(amount!) \(AppState.current.currency!.rawValue)")
                
            } else if case .recurringPayment = klarnaSessionType {
                // Do not send amount for recurring payments, even if it's set
                amount = nil
            }
                        
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            let body = Request.Body.Klarna.CreatePaymentSession(
                paymentMethodConfigId: configId,
                sessionType: .recurringPayment,
                localeData: PrimerSettings.current.localeData,
                description: PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
                redirectUrl: settings.paymentMethodOptions.urlScheme,
                totalAmount: nil,
                orderItems: nil)
            
            let apiClient: PrimerAPIClientProtocol = PaymentMethodModule.apiClient ?? PrimerAPIClient()
            
            apiClient.createKlarnaPaymentSession(clientToken: decodedJWTToken, klarnaCreatePaymentSessionAPIRequest: body) { (result) in
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
                    
                    seal.fulfill(res)
                }
            }
        }
    }
    
    private func awaitUserInput() -> Promise<Void> {
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
    
    private func authorizePaymentSession(authorizationToken: String) -> Promise<Response.Body.Klarna.CustomerToken> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let configId = PrimerAPIConfigurationModule.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.klarna.rawValue),
                  let sessionId = self.klarnaPaymentSession?.sessionId else {
                let err = PrimerError.missingPrimerConfiguration(
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let body = Request.Body.Klarna.CreateCustomerToken(
                paymentMethodConfigId: configId,
                sessionId: sessionId,
                authorizationToken: authorizationToken,
                description: PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
                localeData: PrimerSettings.current.localeData
            )
                        
            let apiClient: PrimerAPIClientProtocol = PaymentMethodModule.apiClient ?? PrimerAPIClient()
            
            apiClient.createKlarnaCustomerToken(clientToken: decodedJWTToken, klarnaCreateCustomerTokenAPIRequest: body) { (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let response):
                    seal.fulfill(response)
                }
            }
        }
    }
    
    private func finalizePaymentSession() -> Promise<Response.Body.Klarna.CustomerToken> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let configId = PrimerAPIConfigurationModule.apiConfiguration?.getConfigId(for: PrimerPaymentMethodType.klarna.rawValue),
                  let sessionId = self.klarnaPaymentSession?.sessionId else {
                let err = PrimerError.missingPrimerConfiguration(
                    userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                    diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let body = Request.Body.Klarna.FinalizePaymentSession(paymentMethodConfigId: configId, sessionId: sessionId)
            log(logLevel: .info, message: "config ID: \(configId)", className: "KlarnaService", function: "finalizePaymentSession")
            
            let apiClient: PrimerAPIClientProtocol = PaymentMethodModule.apiClient ?? PrimerAPIClient()
            
            apiClient.finalizeKlarnaPaymentSession(clientToken: decodedJWTToken, klarnaFinalizePaymentSessionRequest: body) { (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                    
                case .success(let response):
                    log(logLevel: .info, message: "\(response)", className: "KlarnaService", function: "createPaymentSession")
                    seal.fulfill(response)
                }
            }
        }
    }
    
    private func presentPaymentMethodUserInterface() -> Promise<Void> {
        return Promise { seal in
            DispatchQueue.main.async {
#if canImport(PrimerKlarnaSDK)
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                
                guard let urlSchemeStr = settings.paymentMethodOptions.urlScheme,
                      URL(string: urlSchemeStr) != nil else {
                    let err = PrimerError.invalidUrlScheme(
                        urlScheme: settings.paymentMethodOptions.urlScheme,
                        userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"],
                        diagnosticsId: nil)
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                self.klarnaViewController = PrimerKlarnaViewController(
                    delegate: self,
                    paymentCategory: .payLater,
                    clientToken: self.klarnaPaymentSession!.clientToken,
                    urlScheme: urlSchemeStr)
                
                self.klarnaPaymentSessionCompletion = { _, err in
                    if let err = err {
                        seal.reject(err)
                    } else {
                        fatalError()
                    }
                }
                
//                self.willPresentExternalView?()
                PrimerUIManager.primerRootViewController?.show(viewController: self.klarnaViewController!)
//                self.didPresentExternalView?()
                seal.fulfill()
#else
                let err = PrimerError.failedToFindModule(name: "Primer/Klarna", userInfo: nil, diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
#endif
            }
        }
    }
}

#if canImport(PrimerKlarnaSDK)
extension KlarnaTokenizationModule: PrimerKlarnaViewControllerDelegate {
    
    func primerKlarnaViewDidLoad() {
        
    }
    
    func primerKlarnaPaymentSessionCompleted(authorizationToken: String?, error: PrimerKlarnaError?) {
        self.klarnaPaymentSessionCompletion?(authorizationToken, error)
        self.klarnaPaymentSessionCompletion = nil
    }
}
#endif

#endif
