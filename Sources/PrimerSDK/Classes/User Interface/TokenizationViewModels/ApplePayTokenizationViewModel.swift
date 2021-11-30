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
    
    override lazy var title: String = {
        return "Apple Pay"
    }()
    
    override lazy var buttonTitle: String? = {
        switch config.type {
        case .applePay:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonImage: UIImage? = {
        switch config.type {
        case .applePay:
            return UIImage(named: "apple-pay-logo", in: Bundle.primerResources, compatibleWith: nil)?.withRenderingMode(.alwaysTemplate)
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonColor: UIColor? = {
        switch config.type {
        case .applePay:
            return .black
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTitleColor: UIColor? = {
        switch config.type {
        case .applePay:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonBorderWidth: CGFloat = {
        switch config.type {
        case .applePay:
            return 0.0
        default:
            assert(true, "Shouldn't end up in here")
            return 0.0
        }
    }()
    
    override lazy var buttonBorderColor: UIColor? = {
        switch config.type {
        case .applePay:
            return nil
        default:
            assert(true, "Shouldn't end up in here")
            return nil
        }
    }()
    
    override lazy var buttonTintColor: UIColor? = {
        switch config.type {
        case .applePay:
            return .white
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

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    override func validate() throws {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = state.decodedClientToken, decodedClientToken.isValid else {
            let err = PaymentException.missingClientToken
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard decodedClientToken.pciUrl != nil else {
            let err = PrimerError.tokenizationPreRequestFailed
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard config.id != nil else {
            let err = PaymentException.missingConfigurationId
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard settings.countryCode != nil else {
            let err = PaymentException.missingCountryCode
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard settings.currency != nil else {
            let err = PaymentException.missingCurrency
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard settings.merchantIdentifier != nil else {
            let err = AppleException.missingMerchantIdentifier
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
        
        guard !(settings.orderItems ?? []).isEmpty else {
            let err = PaymentException.missingOrderItems
            _ = ErrorHandler.shared.handle(error: err)
            throw err
        }
    }
    
    @objc
    override func startTokenizationFlow() {
        super.startTokenizationFlow()
        
        Primer.shared.primerRootVC?.showLoadingScreenIfNeeded()
        
        if let onClientSessionActions = Primer.shared.delegate?.onClientSessionActions {
            let params: [String: Any] = ["paymentMethodType": config.type.rawValue]
            let actions: [ClientSession.Action] = [ClientSession.Action(type: "SELECT_PAYMENT_METHOD", params: params)]
            onClientSessionActions(actions, self)
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
            self.tokenize()
        }
        .done { [unowned self] paymentMethod in
            DispatchQueue.main.async {
                self.paymentMethod = paymentMethod
                
                if Primer.shared.flow.internalSessionFlow.vaulted {
                    Primer.shared.delegate?.tokenAddedToVault?(paymentMethod)
                }
                
                Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, resumeHandler: self)
                Primer.shared.delegate?.onTokenizeSuccess?(paymentMethod, { [unowned self] err in
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
                Primer.shared.delegate?.checkoutFailed?(with: err)
                self.handleFailedTokenizationFlow(error: err)
            }
        }
    }
    
    func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            if Primer.shared.flow.internalSessionFlow.vaulted {
                seal.reject(PrimerError.vaultNotSupported)
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
        let state: AppStateProtocol = DependencyContainer.resolve()
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        let decodedClientToken = state.decodedClientToken!
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
            items: (orderItems ?? [])
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
                let err = AppleException.unableToPresentApplePay
                _ = ErrorHandler.shared.handle(error: err)
                Primer.shared.delegate?.checkoutFailed?(with: err)
                return completion(nil, err)
            }
            
            paymentVC.delegate = self
            
            applePayReceiveDataCompletion = { result in
                switch result {
                case .success(let applePayPaymentResponse):
                    let state: AppStateProtocol = DependencyContainer.resolve()
                                        
                    guard let applePayConfigId = self.config.id else {
                        return completion(nil, PaymentException.missingConfigurationId)
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
                Primer.shared.primerRootVC?.present(paymentVC, animated: true, completion: {
                    DispatchQueue.main.async {
                        self.didPresentExternalView?()
                    }
                })
            }
            
        } else {
            log(logLevel: .error, title: "APPLE PAY", message: "Cannot make payments on the provided networks")
            completion(nil, AppleException.unableToMakePaymentsOnProvidedNetworks)
        }
    }
    
}

extension ApplePayTokenizationViewModel: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        controller.dismiss(animated: true, completion: nil)
        applePayReceiveDataCompletion?(.failure(AppleException.cancelled))
        applePayReceiveDataCompletion = nil
    }
    
    @available(iOS 11.0, *)
    func paymentAuthorizationViewController(
        _ controller: PKPaymentAuthorizationViewController,
        didAuthorizePayment payment: PKPayment,
        handler completion: @escaping (PKPaymentAuthorizationResult) -> Void
    ) {
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

            applePayReceiveDataCompletion?(.success(applePayPaymentResponse))
            applePayReceiveDataCompletion = nil
        } catch {
            applePayReceiveDataCompletion?(.failure(error))
            applePayReceiveDataCompletion = nil
        }
    }
    
}

extension ApplePayTokenizationViewModel {
    
    override func handle(error: Error) {
        if #available(iOS 11.0, *) {
            self.applePayControllerCompletion?(PKPaymentAuthorizationResult(status: .failure, errors: [error]))
        }
        self.applePayControllerCompletion = nil
        self.completion?(nil, error)
        self.completion = nil
    }
    
    override func handle(newClientToken clientToken: String) {
        do {
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
            
        } catch {
            Primer.shared.delegate?.checkoutFailed?(with: error)
            self.handle(error: error)
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
