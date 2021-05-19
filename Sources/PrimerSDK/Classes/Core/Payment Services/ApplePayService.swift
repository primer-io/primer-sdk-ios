//
//  ApplePayService.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/4/21.
//

import Foundation
import PassKit

protocol ApplePayServiceProtocol {
    func payWithApple(_ completion: @escaping (Result<PaymentInstrument, Error>) -> Void)
    func fetchConfig(_ completion: @escaping (Error?) -> Void)
}

enum ApplePayType {
    case recurring, checkout
}

class ApplePayService: NSObject, ApplePayServiceProtocol {
    
    deinit {
        print("ApplePayService deinit")
    }
    
    private var applePayCompletion: ((Result<ApplePayPaymentResponse, Error>) -> Void)?
 
    func payWithApple(_ completion: @escaping (Result<PaymentInstrument, Error>) -> Void) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        guard let countryCode = settings.countryCode else {
            return completion(.failure(PaymentException.missingCountryCode))
        }
        
        guard let currency = settings.currency else {
            return completion(.failure(PaymentException.missingCurrency))
        }
        
        guard let merchantIdentifier = settings.merchantIdentifier else {
            return completion(.failure(AppleException.missingMerchantIdentifier))
        }
        
        guard !settings.orderItems.isEmpty else {
            return completion(.failure(PaymentException.missingOrderItems))
        }
        
//        guard let supportedNetworks = settings.supportedNetworks, !supportedNetworks.isEmpty else {
//            return completion(.failure(AppleException.missingSupportedPaymentNetworks))
//        }
//        
//        guard let merchantCapabilities = settings.merchantCapabilities, !merchantCapabilities.isEmpty else {
//            return completion(.failure(AppleException.missingMerchantCapabilities))
//        }
        
        let applePayRequest = ApplePayRequest(
            currency: currency,
            merchantIdentifier: merchantIdentifier,
            countryCode: countryCode,
//            supportedNetworks: supportedNetworks,
            items: settings.orderItems
//            merchantCapabilities: merchantCapabilities
        )
        
        var supportedNetworks: [PKPaymentNetwork] = [
            .amex,
            .chinaUnionPay,
            .discover,
            .interac,
            .masterCard,
            .privateLabel,
            .visa
        ]
        
        if #available(iOS 11.2, *) {
//            @available(iOS 11.2, *)
            supportedNetworks.append(.cartesBancaires)
        } else if #available(iOS 11.0, *) {
//            @available(iOS, introduced: 11.0, deprecated: 11.2, message: "Use PKPaymentNetworkCartesBancaires instead.")
            supportedNetworks.append(.carteBancaires)
        } else if #available(iOS 10.3, *) {
//            @available(iOS, introduced: 10.3, deprecated: 11.0, message: "Use PKPaymentNetworkCartesBancaires instead.")
            supportedNetworks.append(.carteBancaire)
        }

        if #available(iOS 12.0, *) {
//            @available(iOS 12.0, *)
            supportedNetworks.append(.eftpos)
            supportedNetworks.append(.electron)
            supportedNetworks.append(.maestro)
            supportedNetworks.append(.vPay)
        }

        if #available(iOS 12.1.1, *) {
//            @available(iOS 12.1.1, *)
            supportedNetworks.append(.elo)
            supportedNetworks.append(.mada)
        }
        
        if #available(iOS 10.3.1, *) {
//            @available(iOS 10.3, *)
            supportedNetworks.append(.idCredit)
        }
        
        if #available(iOS 10.1, *) {
//            @available(iOS 10.1, *)
            supportedNetworks.append(.JCB)
            supportedNetworks.append(.suica)
        }
        
        if #available(iOS 10.3, *) {
//            @available(iOS 10.3, *)
            supportedNetworks.append(.quicPay)
        }
        
        if #available(iOS 14.0, *) {
//            @available(iOS 14.0, *)
            supportedNetworks.append(.barcode)
            supportedNetworks.append(.girocard)
        }
        
        if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks) {
            let request = PKPaymentRequest()
            request.currencyCode = applePayRequest.currency.rawValue
            request.countryCode = applePayRequest.countryCode.rawValue
            request.merchantIdentifier = "merchant.primer.dev.evangelos"
            request.merchantCapabilities = [.capability3DS]
            request.supportedNetworks = supportedNetworks
            request.paymentSummaryItems = applePayRequest.items.compactMap({ $0.applePayItem })
            
            guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: request) else {
                log(logLevel: .error, title: "APPLE PAY", message: "Unable to present Apple Pay authorization.")
                return completion(.failure(AppleException.unableToPresentApplePay))
            }
            
            paymentVC.delegate = self
            
            applePayCompletion = { result in
                switch result {
                case .success(let applePayPaymentResponse):
                    self.fetchConfig { (err) in
                        if let err = err {
                            return completion(.failure(err))
                        } else {
                            let state: AppStateProtocol = DependencyContainer.resolve()
                            
                            guard let applePayConfigId = state.paymentMethodConfig?.getConfigId(for: .applePay) else {
                                return completion(.failure(PaymentException.missingConfigurationId))
                            }
                            
                            let instrument = PaymentInstrument(
                                paymentMethodConfigId: applePayConfigId,
                                token: applePayPaymentResponse.token,
                                sourceConfig: ApplePaySourceConfig(source: "IN_APP", merchantId: merchantIdentifier)
                            )
                            
                            self.tokenize(instrument: instrument) { (err) in
                                if let err = err {
                                    return completion(.failure(err))
                                } else {
                                    return completion(.success(instrument))
                                }
                            }
                        }
                    }
                    
                case .failure(let err):
                    completion(.failure(err))
                }
            }
            // FIXME: Present on a window above the app's window
            (Primer.shared.delegate as? UIViewController)?.present(paymentVC, animated: true, completion: nil)
            
        } else {
            log(logLevel: .error, title: "APPLE PAY", message: "Cannot make payments on the provided networks")
            return completion(.failure(AppleException.unableToMakePaymentsOnProvidedNetworks))
        }
    }
    
    func fetchConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.configFetchFailed)
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.fetchConfiguration(clientToken: clientToken) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let config):
                state.paymentMethodConfig = config

                state.viewModels = []

                config.paymentMethods?.forEach({ method in
                    guard let type = method.type else { return }
                    if type == .googlePay { return }
                    state.viewModels.append(PaymentMethodViewModel(type: type))
                })

                // ensure Apple Pay is always first if present.
                let viewModels = state.viewModels
                if (viewModels.contains(where: { model in model.type == .applePay})) {
                    var arr = viewModels.filter({ model in model.type != .applePay})

                    if settings.applePayEnabled == true {
                        arr.insert(PaymentMethodViewModel(type: .applePay), at: 0)
                    }

                    state.viewModels = arr
                }

                completion(nil)
            }
        }
    }
    
    func tokenize(instrument: PaymentInstrument, completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let request = PaymentMethodTokenizationRequest(paymentInstrument: instrument, state: state)
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        let tokenizationService: TokenizationServiceProtocol = DependencyContainer.resolve()
        tokenizationService.tokenize(request: request) { [weak self] result in
            switch result {
            case .failure(let error):
                ErrorHandler.shared.handle(error: error)
                completion(error)
            case .success(let token):
                switch Primer.shared.flow {
                case .completeDirectCheckout:
                    settings.onTokenizeSuccess(token, completion)
                default:
                    completion(nil)
                }
            }
        }
    }
    
}

extension ApplePayService: PKPaymentAuthorizationViewControllerDelegate {
    
    func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
        (Primer.shared.delegate as? UIViewController)?.dismiss(animated: true, completion: nil)
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
            (Primer.shared.delegate as? UIViewController)?.dismiss(animated: true, completion: nil)
        } catch {
            applePayCompletion?(.failure(error))
            applePayCompletion = nil
        }
    }
    
}

extension PKPaymentMethodType {
    
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
