#if canImport(UIKit)

import Foundation
import PassKit

protocol ApplePayViewModelProtocol {
    var countryCode: CountryCode? { get }
    var currency: Currency? { get }
    var merchantIdentifier: String? { get }
    var orderItems: [OrderItem] { get }
    var applePayConfigId: String? { get }
    var clientToken: DecodedClientToken? { get }
    var isVaulted: Bool { get }
    var uxMode: UXMode { get }
    func payWithApple(completion: @escaping (PaymentMethodToken?, Error?) -> Void)
}

class ApplePayViewModel: NSObject, ApplePayViewModelProtocol {
    
    private var resumeHandler: ResumeHandlerProtocol!
    private var applePayWindow: UIWindow?

    var countryCode: CountryCode? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.countryCode
    }
    var currency: Currency? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.currency
    }
    var merchantIdentifier: String? {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.merchantIdentifier
    }
    var orderItems: [OrderItem] {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        return settings.orderItems
    }
    var applePayConfigId: String? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.paymentMethodConfig?.getConfigId(for: .applePay)
    }
    var clientToken: DecodedClientToken? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.decodedClientToken
    }
    var isVaulted: Bool {
        return Primer.shared.flow.internalSessionFlow.vaulted
    }
    var uxMode: UXMode {
        return Primer.shared.flow.internalSessionFlow.uxMode
    }
    
    private var applePayCompletion: ((Result<ApplePayPaymentResponse, Error>) -> Void)?

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override init() {
        super.init()
        resumeHandler = self
    }
    
    func payWithApple(completion: @escaping (PaymentMethodToken?, Error?) -> Void) {
        initializeApplePay { token, err in
            if let err = err {
                DispatchQueue.main.async {
                    Primer.shared.delegate?.checkoutFailed?(with: err)
                    self.dismissWithError(err)
                }
                
            } else if let token = token {
                DispatchQueue.main.async {
                    if Primer.shared.flow.internalSessionFlow.vaulted {
                        Primer.shared.delegate?.tokenAddedToVault?(token)
                        
                    } else {
                        Primer.shared.delegate?.authorizePayment?(token, { (err) in
                        })
                    }
                    
                    Primer.shared.delegate?.onTokenizeSuccess?(token, resumeHandler: self)
                    
                    Primer.shared.delegate?.onTokenizeSuccess?(token, { (err) in
                        if let err = err {
                            self.dismissWithError(err)
                        } else {
                            self.dismissSuccess()
                        }
                    })
                }
            }
        }
    }

    // swiftlint:disable cyclomatic_complexity function_body_length
    func initializeApplePay(completion: @escaping (PaymentMethodToken?, Error?) -> Void) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        if !settings.isInitialLoadingHidden {
            
        }
        
        let config: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
        config.fetchConfig { [weak self] err in
            guard let self = self else { return }
            
            if let err = err {
                DispatchQueue.main.async {
                    Primer.shared.delegate?.checkoutFailed?(with: err)
                    
                    if !settings.hasDisabledSuccessScreen {
                        
                    } else {
                        
                    }
                }
            } else {
                guard let countryCode = self.countryCode else {
                    let err = PaymentException.missingCountryCode
                    _ = ErrorHandler.shared.handle(error: err)
                    return completion(nil, err)
                }
                
                guard let currency = self.currency else {
                    let err = PaymentException.missingCurrency
                    _ = ErrorHandler.shared.handle(error: err)
                    return completion(nil, err)
                }
                
                guard let merchantIdentifier = self.merchantIdentifier else {
                    let err = AppleException.missingMerchantIdentifier
                    _ = ErrorHandler.shared.handle(error: err)
                    return completion(nil, err)
                }
                
                guard !self.orderItems.isEmpty else {
                    let err = PaymentException.missingOrderItems
                    _ = ErrorHandler.shared.handle(error: err)
                    return completion(nil, err)
                }
                
                let applePayRequest = ApplePayRequest(
                    currency: currency,
                    merchantIdentifier: merchantIdentifier,
                    countryCode: countryCode,
        //            supportedNetworks: supportedNetworks,
                    items: self.orderItems
        //            merchantCapabilities: merchantCapabilities
                )
                
                
                let supportedNetworks = PaymentNetwork.iOSSupportedPKPaymentNetworks
                if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks) {
                    let request = PKPaymentRequest()
                    request.currencyCode = applePayRequest.currency.rawValue
                    request.countryCode = applePayRequest.countryCode.rawValue
                    request.merchantIdentifier = merchantIdentifier
                    request.merchantCapabilities = [.capability3DS]
                    request.supportedNetworks = supportedNetworks
                    request.paymentSummaryItems = applePayRequest.items.compactMap({ $0.applePayItem })
                    
                    guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                        let err = AppleException.unableToPresentApplePay
                        _ = ErrorHandler.shared.handle(error: err)
                        return completion(nil, err)
                    }
                    
                    paymentVC.delegate = self
                    
                    self.applePayCompletion = { [weak self] result in
                        switch result {
                        case .success(let applePayPaymentResponse):
                            let applePayService: ApplePayServiceProtocol = DependencyContainer.resolve()
                            applePayService.fetchConfig { [weak self] (err) in
                                if let err = err {

                                    completion(nil, err)
                                    
                                } else {
                                    let state: AppStateProtocol = DependencyContainer.resolve()

                                    guard let applePayConfigId = self?.applePayConfigId else {
                                        let err = PaymentException.missingConfigurationId
                                        _ = ErrorHandler.shared.handle(error: err)
                                        return completion(nil, err)
                                    }

                                    let instrument = PaymentInstrument(
                                        paymentMethodConfigId: applePayConfigId,
                                        token: applePayPaymentResponse.token,
                                        sourceConfig: ApplePaySourceConfig(source: "IN_APP", merchantId: merchantIdentifier)
                                    )
                                    
                                    applePayService.tokenize(instrument: instrument) { [weak self] (result) in
                                        switch result {
                                        case .failure(let err):
                                            completion(nil, err)
                                            
                                        case .success(let token):
                                            completion(token, nil)
                                        }
                                    }
                                }
                            }
                            
                        case .failure(let err):
                            completion(nil, err)
                        }
                    }
                    
                    self.applePayWindow = UIWindow(frame: UIScreen.main.bounds)
                    self.applePayWindow?.rootViewController = ClearViewController()
                    self.applePayWindow?.backgroundColor = UIColor.clear
                    self.applePayWindow?.windowLevel = UIWindow.Level.alert
                    self.applePayWindow?.makeKeyAndVisible()
                    self.applePayWindow?.rootViewController?.present(paymentVC, animated: true, completion: nil)
                    
                } else {
                    log(logLevel: .error, title: "APPLE PAY", message: "Cannot make payments on the provided networks")
                    return completion(nil, AppleException.unableToMakePaymentsOnProvidedNetworks)
                }
            }
        }
        
        
        
        
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
    
    private func dismissWithError(_ err: Error) {
        DispatchQueue.main.async {
            self.applePayWindow?.rootViewController?.dismiss(animated: true, completion: {
                DispatchQueue.main.async {
                    self.applePayWindow = nil
                    
                    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                    if settings.hasDisabledSuccessScreen {
                        Primer.shared.dismiss()
                    } else {
                        let router: RouterDelegate = DependencyContainer.resolve()
                        router.presentErrorScreen(with: err)
                    }
                }
            })
        }
    }
    
    private func dismissSuccess() {
        DispatchQueue.main.async {
            self.applePayWindow?.rootViewController?.dismiss(animated: true, completion: {
                DispatchQueue.main.async {
                    self.applePayWindow = nil
                    
                    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                    if settings.hasDisabledSuccessScreen {
                        Primer.shared.dismiss()
                    } else {
                        let router: RouterDelegate = DependencyContainer.resolve()
                        router.presentSuccessScreen(for: .regular)
                    }
                }
            })
        }
    }
}

extension ApplePayViewModel: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
        applePayCompletion?(.failure(AppleException.cancelled))
        applePayCompletion = nil
    }
    
    @available(iOS 11.0, *)
    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
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

            applePayCompletion?(.success(applePayPaymentResponse))
            applePayCompletion = nil
        } catch {
            applePayCompletion?(.failure(error))
            applePayCompletion = nil
        }
    }
    
}

extension ApplePayViewModel: ResumeHandlerProtocol {
    func handle(error: Error) {
        
    }
    
    func handle(newClientToken clientToken: String) {
        
    }
    
    func handleSuccess() {
        
    }
}

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

#endif
