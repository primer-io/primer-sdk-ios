#if canImport(UIKit)

import Foundation
import PassKit
import UIKit

internal extension PKPaymentMethodType {
    
    var primerValue: String? {
        switch self {
        case .credit:
            return "credit"
        case .debit:
            return "debit"
        case .prepaid:
            return "prepaid"
        default:
            return nil
        }
    }
    
}

class ApplePayTokenizationViewModel: PaymentMethodTokenizationViewModel, ExternalPaymentMethodTokenizationViewModelProtocol {
    
    var willPresentExternalView: (() -> Void)?
    var didPresentExternalView: (() -> Void)?
    var willDismissExternalView: (() -> Void)?
    var didDismissExternalView: (() -> Void)?

    private var applePayWindow: UIWindow?
    private var request: PKPaymentRequest!
    // This is the completion handler that notifies that the necessary data were received.
    private var applePayReceiveDataCompletion: ((Result<ApplePayPaymentResponse, Error>) -> Void)?
    // This is the PKPaymentAuthorizationViewController's completion, call it when tokenization has finished.
    private var applePayControllerCompletion: ((NSObject) -> Void)?
    private var isCancelled: Bool = false
    
    private lazy var _title: String = { return "Apple Pay" }()
    override var title: String  {
        get { return _title }
        set { _title = newValue }
    }
    
    private lazy var _buttonImage: UIImage? = {
        switch config.type {
        case .applePay:
            return UIImage(named: "apple-pay-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
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
        case .applePay:
            return .black
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
        case .applePay:
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

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken, decodedClientToken.isValid else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id", value: config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard settings.countryCode != nil else {
            let err = PrimerError.invalidSetting(name: "countryCode", value: settings.countryCode?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard settings.currency != nil else {
            let err = PrimerError.invalidSetting(name: "currency", value: settings.countryCode?.rawValue, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard settings.merchantIdentifier != nil else {
            let err = PrimerError.invalidMerchantIdentifier(merchantIdentifier: settings.merchantIdentifier, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        guard !(settings.orderItems ?? []).isEmpty else {
            let err = PrimerError.invalidValue(key: "settings.orderItems", value: nil, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
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
            self.handle(error: error)
            return
        }
        
        firstly {
            self.handlePrimerWillCreatePaymentEvent(PaymentMethodData(type: self.config.type))
        }
        .then {
            self.tokenize()
        }
        .done { [unowned self] paymentMethod in
            DispatchQueue.main.async {
                self.paymentMethod = paymentMethod
                self.handleContinuePaymentFlowWithPaymentMethod(paymentMethod)
            }
        }
        .ensure {
            
        }
        .catch { error in
            DispatchQueue.main.async {
                self.unselectPaymentMethodWithError(error)
                PrimerDelegateProxy.primerDidFailWithError(error)
                self.handleFailedTokenizationFlow(error: error)
            }
        }
    }
    
    func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            if Primer.shared.flow.internalSessionFlow.vaulted {
                let err = PrimerError.unsupportedIntent(intent: .vault, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            self.payWithApple { (paymentMethod, err) in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethod = paymentMethod {
                    seal.fulfill(paymentMethod)
                } else {
                    assert(true)
                }
            }
        }
    }

    
    private func payWithApple(completion: @escaping (PaymentMethodToken?, Error?) -> Void) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(nil, err)
            return
        }
        
        let countryCode = settings.countryCode!
        let currency = settings.currency!
        let merchantIdentifier = settings.merchantIdentifier!
        let orderItems = [
            try! OrderItem(
                name: "Total", unitAmount: settings.amount ?? 0, quantity: 1)
        ]
        
        let applePayRequest = ApplePayRequest(
            currency: currency,
            merchantIdentifier: merchantIdentifier,
            countryCode: countryCode,
            items: orderItems
        )
        
        let supportedNetworks = PaymentNetwork.iOSSupportedPKPaymentNetworks
        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks) {
            request = PKPaymentRequest()
            request.currencyCode = applePayRequest.currency.rawValue
            request.countryCode = applePayRequest.countryCode.rawValue
            request.merchantIdentifier = merchantIdentifier
            request.merchantCapabilities = [.capability3DS]
            request.supportedNetworks = supportedNetworks
            request.paymentSummaryItems = applePayRequest.items.compactMap({ $0.applePayItem })
            
            guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                let error = PrimerError.unableToPresentPaymentMethod(paymentMethodType: .applePay, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                ErrorHandler.handle(error: error)
                self.unselectPaymentMethodWithError(error)
                PrimerDelegateProxy.primerDidFailWithError(error)
                return completion(nil, error)
            }
            
            paymentVC.delegate = self
            
            applePayReceiveDataCompletion = { result in
                switch result {
                case .success(let applePayPaymentResponse):
                    let state: AppStateProtocol = DependencyContainer.resolve()
                                        
                    guard let applePayConfigId = self.config.id else {
                        let err = PrimerError.invalidValue(key: "configuration.id", value: self.config.id, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                        ErrorHandler.handle(error: err)
                        completion(nil, err)
                        return
                    }

                    let instrument = PaymentInstrument(
                        paymentMethodConfigId: applePayConfigId,
                        token: applePayPaymentResponse.token,
                        sourceConfig: ApplePaySourceConfig(source: "IN_APP", merchantId: merchantIdentifier)
                    )
                    let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
                    
                    let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
                    apiClient.tokenizePaymentMethod(
                        clientToken: decodedClientToken,
                        paymentMethodTokenizationRequest: request) { result in
                            switch result {
                            case .success(let paymentMethod):
                                completion(paymentMethod, nil)
                            case .failure(let err):
                                completion(nil, err)
                            }
                        }
                    
                case .failure(let err):
                    completion(nil, err)
                }
            }
            
            DispatchQueue.main.async {
                self.willPresentExternalView?()
                self.isCancelled = true
                Primer.shared.primerRootVC?.present(paymentVC, animated: true, completion: {
                    DispatchQueue.main.async {
                        PrimerHeadlessUniversalCheckout.current.delegate?.primerHeadlessUniversalCheckoutPaymentMethodPresented()
                        self.didPresentExternalView?()
                    }
                })
            }
            
        } else {
            log(logLevel: .error, title: "APPLE PAY", message: "Cannot make payments on the provided networks")
            let err = PrimerError.unableToMakePaymentsOnProvidedNetworks(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(nil, err)
        }
    }
    
}

extension ApplePayTokenizationViewModel: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        if self.isCancelled {
            controller.dismiss(animated: true, completion: nil)
            let err = PrimerError.cancelled(paymentMethodType: .applePay, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            applePayReceiveDataCompletion?(.failure(err))
            applePayReceiveDataCompletion = nil
        }
    }
    
    @available(iOS 11.0, *)
    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
        self.isCancelled = false
        applePayControllerCompletion = { obj in
            completion(obj as! PKPaymentAuthorizationResult)
        }
        
        do {
            let tokenPaymentData = try JSONParser().parse(ApplePayPaymentResponseTokenPaymentData.self, from: payment.token.paymentData)
            let applePayPaymentResponse = ApplePayPaymentResponse(
                token: ApplePayPaymentResponseToken(
                    paymentMethod: ApplePayPaymentResponsePaymentMethod(
                        displayName: payment.token.paymentMethod.displayName,
                        network: payment.token.paymentMethod.network?.rawValue,
                        type: payment.token.paymentMethod.type.primerValue
                    ),
                    transactionIdentifier: payment.token.transactionIdentifier,
                    paymentData: tokenPaymentData
                )
            )
            completion(PKPaymentAuthorizationResult(status: .success, errors: nil))
            controller.dismiss(animated: true, completion: nil)
            applePayReceiveDataCompletion?(.success(applePayPaymentResponse))
            applePayReceiveDataCompletion = nil
        } catch {
            completion(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
            controller.dismiss(animated: true, completion: nil)
            applePayReceiveDataCompletion?(.failure(error))
            applePayReceiveDataCompletion = nil
        }
    }
}

extension ApplePayTokenizationViewModel {
    
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
            self.applePayControllerCompletion = nil
        }
        .catch { error in
            PrimerDelegateProxy.primerDidFailWithError(error)
        }
    }
}

extension ApplePayTokenizationViewModel {
    
    override func handle(error: Error) {
        if #available(iOS 11.0, *) {
            self.applePayControllerCompletion?(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
        }
        self.unselectPaymentMethodWithError(error)
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
                self.handleErrorBasedOnSDKSettings(error, isOnResumeFlow: true)
            }
        }
    }

    override func handleSuccess() {
        if #available(iOS 11.0, *) {
            self.applePayControllerCompletion?(PKPaymentAuthorizationResult(status: .success, errors: nil))
        }
        self.applePayControllerCompletion = nil
        self.completion?(self.paymentMethod, nil)
        self.completion = nil
    }
    
}

#endif
