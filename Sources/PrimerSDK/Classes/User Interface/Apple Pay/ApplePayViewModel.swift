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
    func payWithApple(completion: @escaping (Error?) -> Void)
}

class ApplePayViewModel: NSObject, ApplePayViewModelProtocol {

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

    // swiftlint:disable cyclomatic_complexity function_body_length
    func payWithApple(completion: @escaping (Error?) -> Void) {
        guard let countryCode = countryCode else {
            return completion(PaymentException.missingCountryCode)
        }
        
        guard let currency = currency else {
            return completion(PaymentException.missingCurrency)
        }

        guard let merchantIdentifier = merchantIdentifier else {
            return completion(AppleException.missingMerchantIdentifier)
        }
        
        guard !orderItems.isEmpty else {
            return completion(PaymentException.missingOrderItems)
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
            let request = PKPaymentRequest()
            request.currencyCode = applePayRequest.currency.rawValue
            request.countryCode = applePayRequest.countryCode.rawValue
            request.merchantIdentifier = merchantIdentifier
            request.merchantCapabilities = [.capability3DS]
            request.supportedNetworks = supportedNetworks
            request.paymentSummaryItems = applePayRequest.items.compactMap({ $0.applePayItem })
            
            guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                log(logLevel: .error, title: "APPLE PAY", message: "Unable to present Apple Pay authorization.")
                return completion(AppleException.unableToPresentApplePay)
            }
            
            paymentVC.delegate = self
            
            applePayCompletion = { [weak self] result in
                switch result {
                case .success(let applePayPaymentResponse):
                    // Loading view
                    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                    
                    let applePayService: ApplePayServiceProtocol = DependencyContainer.resolve()
                    applePayService.fetchConfig { [weak self] (err) in
                        if let err = err {
                            DispatchQueue.main.async {
                                Primer.shared.presentingViewController?.dismiss(animated: true, completion: {
                                    let router: RouterDelegate = DependencyContainer.resolve()
                                    router.presentErrorScreen(with: err)
                                })

                                Primer.shared.delegate?.checkoutFailed(with: err)
                            }
                            completion(err)
                        } else {
                            let state: AppStateProtocol = DependencyContainer.resolve()

                            guard let applePayConfigId = self?.applePayConfigId else {
                                return completion(PaymentException.missingConfigurationId)
                            }

                            let instrument = PaymentInstrument(
                                paymentMethodConfigId: applePayConfigId,
                                token: applePayPaymentResponse.token,
                                sourceConfig: ApplePaySourceConfig(
                                    source: "IN_APP",
                                    merchantId: merchantIdentifier
                                )
                            )
                            
                            applePayService.tokenize(instrument: instrument) { [weak self] (result) in
                                switch result {
                                case .failure(let err):
                                    // Dismiss and show error screen
                                    ErrorHandler.shared.handle(error: err)
                                    DispatchQueue.main.async {
                                        Primer.shared.presentingViewController?.dismiss(animated: true, completion: {
                                            let router: RouterDelegate = DependencyContainer.resolve()
                                            router.presentErrorScreen(with: err)
                                        })
                                        
                                        Primer.shared.delegate?.checkoutFailed(with: err)
                                    }
                                    completion(err)
                                    
                                case .success(let token):
                                    DispatchQueue.main.async {
                                        if Primer.shared.flow.internalSessionFlow.vaulted {
                                            Primer.shared.delegate?.tokenAddedToVault(token)
                                            completion(nil)
                                        } else {
                                            //settings.onTokenizeSuccess(token, completion)
                                            Primer.shared.delegate?.authorizePayment(token, { (err) in
                                                DispatchQueue.main.async {
                                                    Primer.shared.presentingViewController?.dismiss(animated: true, completion: {
                                                        let router: RouterDelegate = DependencyContainer.resolve()
                                                        
                                                        if let err = err {
                                                            
                                                            router.presentErrorScreen(with: err)
                                                        } else {
                                                            router.presentSuccessScreen(for: .regular)
                                                        }
                                                    })
                                                    
                                                    completion(err)
                                                }
                                            })
                                            Primer.shared.delegate?.onTokenizeSuccess(token, { (err) in
                                                DispatchQueue.main.async {
                                                    Primer.shared.presentingViewController?.dismiss(animated: true, completion: {
                                                        let router: RouterDelegate = DependencyContainer.resolve()
                                                        
                                                        if let err = err {
                                                            
                                                            router.presentErrorScreen(with: err)
                                                        } else {
                                                            router.presentSuccessScreen(for: .regular)
                                                        }
                                                    })
                                                    
                                                    completion(err)
                                                }
                                            })
                                        }
                                    }
                                }
                            }
                        }
                    }
                    
                case .failure(let err):
                    completion(err)
                }
            }
            // FIXME: Present on a window above the app's window
            (Primer.shared.delegate as? UIViewController)?.present(paymentVC, animated: true, completion: nil)
            
        } else {
            log(logLevel: .error, title: "APPLE PAY", message: "Cannot make payments on the provided networks")
            return completion(AppleException.unableToMakePaymentsOnProvidedNetworks)
        }
    }
    // swiftlint:enable cyclomatic_complexity function_body_length
}

extension ApplePayViewModel: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
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
