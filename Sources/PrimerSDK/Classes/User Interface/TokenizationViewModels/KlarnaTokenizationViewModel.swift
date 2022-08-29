#if canImport(UIKit)

import Foundation
import WebKit
import UIKit

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif

class KlarnaTokenizationViewModel: PaymentMethodTokenizationViewModel, ExternalPaymentMethodTokenizationViewModelProtocol {
    
    private var sessionId: String?
    
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
    
    private lazy var _title: String = { return "Klarna" }()
    override var title: String  {
        get { return _title }
        set { _title = newValue }
    }
    
    private lazy var _buttonImage: UIImage? = {
        switch config.type {
        case .klarna:
            return UIImage(named: "klarna-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
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
        case .klarna:
            return UIColor(red: 1, green: 0.702, blue: 0.78, alpha: 1.0)
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
        case .klarna:
            return .black
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    override var buttonTintColor: UIColor? {
        get { return _buttonTintColor }
        set { _buttonTintColor = newValue }
    }
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self.self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
#if !canImport(PrimerKlarnaSDK)
        let err = PrimerError.failedToFindModule(name: "PrimerKlarnaSDK", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
        ErrorHandler.handle(error: err)
        throw err
#endif
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard let klarnaSessionType = settings.klarnaSessionType else {
            let err = PrimerError.invalidValue(key: "settings.klarnaSessionType", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if Primer.shared.flow == .checkoutWithKlarna && settings.amount == nil  {
            let err = PrimerError.invalidSetting(name: "amount", value: settings.amount != nil ? "\(settings.amount!)" : nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if case .hostedPaymentPage = klarnaSessionType {
            if settings.amount == nil {
                let err = PrimerError.invalidSetting(name: "amount", value: settings.amount != nil ? "\(settings.amount!)" : nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if settings.currency == nil {
                let err = PrimerError.invalidSetting(name: "currency", value: settings.currency?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if (settings.orderItems ?? []).isEmpty {
                let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
            
            if !(settings.orderItems ?? []).filter({ $0.unitAmount == nil }).isEmpty {
                let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                throw err
            }
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
            ClientSession.Action.selectPaymentMethod(resumeHandler: self, withParameters: params)
        } else {
            continueTokenizationFlow()
        }
    }
    
    fileprivate func continueTokenizationFlow() {
        do {
            try self.validate()
        } catch {
            DispatchQueue.main.async {
                PrimerDelegateProxy.checkoutFailed(with: error)
                self.handleFailedTokenizationFlow(error: error)
            }
            return
        }
        
        firstly {
            self.createPaymentSession()
        }
        .then { paymentSession -> Promise<String> in
            self.presentKlarnaController()
        }
        .then { authorizationToken -> Promise<KlarnaCustomerTokenAPIResponse> in
            self.authorizationToken = authorizationToken
            return self.authorizePaymentSession(authorizationToken: authorizationToken)
        }
        .then { customerTokenResponse -> Promise<PaymentMethodToken> in
#if canImport(PrimerKlarnaSDK)
            DispatchQueue.main.async {
                self.willDismissExternalView?()
                
                self.klarnaViewController?.dismiss(animated: true, completion: {
                    DispatchQueue.main.async {
                        self.didDismissExternalView?()
                    }
                })
            }
#endif
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            var instrument: PaymentInstrument
            var request: PaymentMethodTokenizationRequest
            
            if Primer.shared.flow.internalSessionFlow.vaulted {
                instrument = PaymentInstrument(
                    klarnaCustomerToken: customerTokenResponse.customerTokenId!,
                    sessionData: customerTokenResponse.sessionData)
                
                request = PaymentMethodTokenizationRequest(
                    paymentInstrument: instrument,
                    paymentFlow: .vault,
                    customerId: nil)
                
            } else {
                instrument = PaymentInstrument(
                    klarnaCustomerToken: customerTokenResponse.customerTokenId!,
                    sessionData: customerTokenResponse.sessionData)
                
                request = PaymentMethodTokenizationRequest(
                    paymentInstrument: instrument,
                    paymentFlow: .checkout,
                    customerId: settings.customerId)
            }
            
            let tokenizationService: TokenizationServiceProtocol = TokenizationService()
            return tokenizationService.tokenize(request: request)
        }
        .done { paymentMethod in
            self.paymentMethod = paymentMethod
            
            DispatchQueue.main.async {
                PrimerDelegateProxy.onTokenizeSuccess(paymentMethod, resumeHandler: self)
                PrimerDelegateProxy.onTokenizeSuccess(paymentMethod, { err in
                    if let err = err {
                        self.handleFailedTokenizationFlow(error: err)
                    } else {
                        self.handleSuccessfulTokenizationFlow()
                    }
                })
            }
        }
        .ensure {
            
        }
        .catch { err in
            DispatchQueue.main.async {
                PrimerDelegateProxy.checkoutFailed(with: err)
                self.handleFailedTokenizationFlow(error: err)
            }
        }
    }
    
    private func createPaymentSession() -> Promise<KlarnaCreatePaymentSessionAPIResponse> {
        return Promise { seal in
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            guard let configId = config.id else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            guard let klarnaSessionType = settings.klarnaSessionType else {
                let err = PrimerError.invalidValue(key: "settings.klarnaSessionType", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            var amount = settings.amount
            if amount == nil && Primer.shared.flow == .checkoutWithKlarna {
                let err = PrimerError.invalidSetting(name: "amount", value: settings.amount != nil ? "\(settings.amount!)" : nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            var orderItems: [OrderItem]? = nil
            
            if case .hostedPaymentPage = klarnaSessionType {
                if amount == nil {
                    let err = PrimerError.invalidSetting(name: "amount", value: settings.amount != nil ? "\(settings.amount!)" : nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                if settings.currency == nil {
                    let err = PrimerError.invalidSetting(name: "currency", value: settings.currency?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                if (settings.orderItems ?? []).isEmpty {
                    let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                if !(settings.orderItems ?? []).filter({ $0.unitAmount == nil }).isEmpty {
                    let err = PrimerError.invalidValue(key: "settings.orderItems.amount", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                orderItems = settings.orderItems
                
                log(logLevel: .info, message: "Klarna amount: \(amount!) \(settings.currency!.rawValue)")
                
            } else if case .recurringPayment = klarnaSessionType {
                // Do not send amount for recurring payments, even if it's set
                amount = nil
            }
            
            var body: KlarnaCreatePaymentSessionAPIRequest
            
            if settings.countryCode != nil || settings.currency != nil {
                body = KlarnaCreatePaymentSessionAPIRequest(
                    paymentMethodConfigId: configId,
                    sessionType: klarnaSessionType,
                    localeData: settings.localeData,
                    description: klarnaSessionType == .recurringPayment ? settings.klarnaPaymentDescription : nil,
                    redirectUrl: "https://primer.io/success",
                    totalAmount: amount,
                    orderItems: orderItems)
            } else {
                body = KlarnaCreatePaymentSessionAPIRequest(
                    paymentMethodConfigId: configId,
                    sessionType: klarnaSessionType,
                    localeData: settings.localeData,
                    description: klarnaSessionType == .recurringPayment ? settings.klarnaPaymentDescription : nil,
                    redirectUrl: "https://primer.io/success",
                    totalAmount: amount,
                    orderItems: orderItems)
            }
            
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
                    
                    self?.sessionId = res.sessionId
                    self?.klarnaPaymentSession = res
                    seal.fulfill(res)
                }
            }
        }
    }
    
    private func presentKlarnaController() -> Promise<String> {
        return Promise { seal in
#if canImport(PrimerKlarnaSDK)
            DispatchQueue.main.async {
                guard let klarnaPaymentSession = self.klarnaPaymentSession else {
                    let err = PrimerError.invalidValue(key: "Klarna payment session", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }

                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                
                self.klarnaViewController = PrimerKlarnaViewController(
                    delegate: self,
                    paymentCategory: .payLater,
                    clientToken: klarnaPaymentSession.clientToken,
                    urlScheme: settings.urlScheme)
                
                self.klarnaPaymentSessionCompletion = { authToken, err in
                    if let err = err {
                        seal.reject(err)
                    } else if let authToken = authToken {
                        seal.fulfill(authToken)
                    } else {
                        precondition(false, "Should always return an authToken or an error.")
                    }
                }
                
                self.willPresentExternalView?()
                Primer.shared.primerRootVC?.show(viewController: self.klarnaViewController!)
                self.didPresentExternalView?()
            }
#else
            let err = PrimerError.failedToFindModule(name: "PrimerKlarnaSDK", userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            seal.reject(err)
#endif
        }
    }
    
    private func authorizePaymentSession(authorizationToken: String) -> Promise<KlarnaCustomerTokenAPIResponse> {
        return Promise { seal in
            let state: AppStateProtocol = DependencyContainer.resolve()
            
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            guard let configId = state.primerConfiguration?.getConfigId(for: .klarna),
                  let sessionId = self.sessionId else {
                let err = PrimerError.missingPrimerConfiguration(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let body = CreateKlarnaCustomerTokenAPIRequest(
                paymentMethodConfigId: configId,
                sessionId: sessionId,
                authorizationToken: authorizationToken,
                description: settings.klarnaPaymentDescription,
                localeData: settings.localeData
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

extension KlarnaTokenizationViewModel {
    
    override func handle(error: Error) {
        ClientSession.Action.unselectPaymentMethod(resumeHandler: nil)
        self.completion?(nil, error)
        self.completion = nil
    }
    
    override func handle(newClientToken clientToken: String) {
        
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
                PrimerDelegateProxy.checkoutFailed(with: error)
            }
            self.handle(error: error)
        }
    }
    
    override func handleSuccess() {
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

#endif
