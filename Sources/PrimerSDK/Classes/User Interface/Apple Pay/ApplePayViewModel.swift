#if canImport(UIKit)

import Foundation
import PassKit

protocol ApplePayViewModelProtocol: PrimerOAuthViewModel {
    var countryCode: CountryCode? { get }
    var currency: Currency? { get }
    var merchantIdentifier: String? { get }
    var orderItems: [OrderItem] { get }
    var applePayConfigId: String? { get }
    var clientToken: DecodedClientToken? { get }
    var isVaulted: Bool { get }
    var uxMode: UXMode { get }
}

class ApplePayViewModel: NSObject, ApplePayViewModelProtocol {
    var host: OAuthHost = .applePay

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
    
    var didPresentPaymentMethod: (() -> Void)?
    
    private var applePayCompletion: ((Result<ApplePayPaymentResponse, Error>) -> Void)?

    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    func tokenize() -> Promise<PaymentMethodToken> {
        return Promise { seal in
            if Primer.shared.flow.internalSessionFlow.vaulted {
                seal.reject(PrimerError.vaultNotSupported)
                return
            }
            
            self.payWithApple { (token, err) in
                if let err = err {
                    seal.reject(err)
                } else if let token = token {
                    seal.fulfill(token)
                } else {
                    assert(true)
                }
            }
        }
    }
    
    var request: PKPaymentRequest!

    // swiftlint:disable cyclomatic_complexity function_body_length
    private func payWithApple(completion: @escaping (PaymentMethodToken?, Error?) -> Void) {
        guard let countryCode = countryCode else {
            let err = PaymentException.missingCountryCode
            _ = ErrorHandler.shared.handle(error: err)
            Primer.shared.delegate?.checkoutFailed?(with: err)
            return completion(nil, err)
        }
        
        guard let currency = currency else {
            let err = PaymentException.missingCurrency
            _ = ErrorHandler.shared.handle(error: err)
            Primer.shared.delegate?.checkoutFailed?(with: err)
            return completion(nil, err)
        }
        
        guard let merchantIdentifier = merchantIdentifier else {
            let err = AppleException.missingMerchantIdentifier
            _ = ErrorHandler.shared.handle(error: err)
            Primer.shared.delegate?.checkoutFailed?(with: err)
            return completion(nil, err)
        }
        
        guard !orderItems.isEmpty else {
            let err = PaymentException.missingOrderItems
            _ = ErrorHandler.shared.handle(error: err)
            Primer.shared.delegate?.checkoutFailed?(with: err)
            return completion(nil, err)
        }
        
        let applePayRequest = ApplePayRequest(
            currency: currency,
            merchantIdentifier: merchantIdentifier,
            countryCode: countryCode,
//            supportedNetworks: supportedNetworks,
            items: orderItems
//            merchantCapabilities: merchantCapabilities
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
            
            applePayCompletion = { result in
                switch result {
                case .success(let applePayPaymentResponse):
                    let applePayService: ApplePayServiceProtocol = DependencyContainer.resolve()
                    applePayService.fetchConfig { [weak self] (err) in
                        if let err = err {
                            completion(nil, err)
                            
                        } else {
                            guard let applePayConfigId = self?.applePayConfigId else {
                                return completion(nil, PaymentException.missingConfigurationId)
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
            Primer.shared.primerRootVC?.present(paymentVC, animated: true, completion: nil)
            didPresentPaymentMethod?()
            
        } else {
            log(logLevel: .error, title: "APPLE PAY", message: "Cannot make payments on the provided networks")
            return completion(nil, AppleException.unableToMakePaymentsOnProvidedNetworks)
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
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
