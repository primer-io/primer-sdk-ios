//
//  APMViewModel.swift
//  PrimerSDK
//
//  Created by Evangelos Pittas on 16/9/21.
//

import Foundation
import PassKit

protocol PaymentMethodNavigationProtocol {
    func present(completionHandler: ((Bool) -> Void)?)
    func showResult(_ result: Result<String, Error>, completionHandler: ((Bool) -> Void)?)
}

protocol APMViewModelProtocol {
    func tokenize() -> Promise<PaymentMethodToken>
}

private protocol InternalAPMViewModelProtocol {

}

class APMViewModel {
    
    class WebBased: APMViewModelProtocol, InternalAPMViewModelProtocol, PaymentMethodNavigationProtocol {

        private(set) var apm: APMWebBasedProtocol
        private var isRequiredInfoLoaded: Bool = false
        
        init(apm: APMWebBasedProtocol) {
            self.apm = apm
        }
        
        func tokenize() -> Promise<PaymentMethodToken> {
            return Promise { seal in
                self.tokenize { result in
                    switch result {
                    case .success(let paymentMethod):
                        seal.fulfill(paymentMethod)
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            }
        }
        
        private func tokenize(completion: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
            self.present(completionHandler: nil)
            
            let config: PaymentMethodConfigServiceProtocol = DependencyContainer.resolve()
            
            firstly {
                config.loadConfigIfNeeded()
            }
            .then { config -> Promise<APMCreateSessionResponseProtocol> in
                return self.apm.createSession()
            }
            .then { res -> Promise<[String: String]> in
                guard let root = Primer.shared.root else {
                    throw PrimerError.generic
                }
            
                let apmViewController = try! APMWebViewController(
                    name: self.apm.name,
                    request: self.apm.apmRequest,
                    redirectUrlSchemePrefix: self.apm.redirectUrlSchemePrefix,
                    allowedHosts: self.apm.allowedHosts)
                
                return self.present(apmViewController: apmViewController, on: root)
            }
            .then { url -> Promise<Dictionary<String, Any?>?> in
                return self.apm.preTokenize()
            }
            .then { dic -> Promise<PaymentMethodToken> in
                return self.apm.tokenize()
            }
            .done { paymentMethod in
                self.showResult(.success("Test")) { finished in
                    
                }
                completion(.success(paymentMethod))
            }
            .catch { err in
                completion(.failure(err))
            }
        }
        
        fileprivate func present(apmViewController: APMViewController, on presentingViewController: PrimerViewController) -> Promise<[String: String]> {
            return Promise { seal in
                self.present(apmViewController: apmViewController, on: presentingViewController) { result in
                    switch result {
                    case .success(let responseParameters):
                        seal.fulfill(responseParameters)
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            }
        }
        
        private func present(apmViewController: APMViewController, on presentingViewController: PrimerViewController, completionHandler: @escaping ((Result<[String: String], Error>) -> Void)) {
            do {
                apmViewController.completionHandler = { (responseParameters, err) in
                    if let err = err {
                        completionHandler(.failure(err))
                    } else if let responseParameters = responseParameters {
                        self.apm.apmResponse = responseParameters
                        completionHandler(.success(responseParameters))
                    } else {
                        fatalError()
                    }
                }
                
                presentingViewController.present(apmViewController, animated: true, completion: nil)
                
            } catch {
                completionHandler(.failure(error))
            }
        }
        
        func present(completionHandler: ((Bool) -> Void)?) {
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            if !isRequiredInfoLoaded {
                if settings.isInitialLoadingHidden {
                    completionHandler?(true)
                } else {
                    // Show loading screen
                }
            } else {
                
            }
        }
        
        func showResult(_ result: Result<String, Error>, completionHandler: ((Bool) -> Void)?) {
            Primer.shared.dismiss()
            let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
            
            if settings.hasDisabledSuccessScreen {
                
            } else {
                
            }
        }
    }
    

    class SDKBased: NSObject, PKPaymentAuthorizationViewControllerDelegate {

        
        
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
        
        var apm: SDKBasedAPM
        
        init(apm: SDKBasedAPM) {
            self.apm = apm
        }
        
        func present(paymentRequest: PKPaymentRequest, completion: @escaping (Any?, Error?) -> Void) {
            guard let paymentVC = PKPaymentAuthorizationViewController(paymentRequest: paymentRequest) else {
                completion(nil, AppleException.unableToPresentApplePay)
                return
            }
            
            paymentVC.delegate = self
            
            applePayCompletion = { [weak self] result in
//                switch result {
//                case .success(let applePayPaymentResponse):
//                    // Loading view
//                    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
//
//                    let applePayService: ApplePayServiceProtocol = DependencyContainer.resolve()
//                    applePayService.fetchConfig { [weak self] (err) in
//                        if let err = err {
//                            DispatchQueue.main.async {
//                                Primer.shared.presentingViewController?.dismiss(animated: true, completion: {
//                                    let router: RouterDelegate = DependencyContainer.resolve()
//                                    router.presentErrorScreen(with: err)
//                                })
//
//                                Primer.shared.delegate?.checkoutFailed?(with: err)
//                            }
//
//                            completion(err)
//
//                        } else {
//                            let state: AppStateProtocol = DependencyContainer.resolve()
//
//                            guard let applePayConfigId = self?.applePayConfigId else {
//                                let err = PaymentException.missingConfigurationId
//                                _ = ErrorHandler.shared.handle(error: err)
//                                Primer.shared.delegate?.checkoutFailed?(with: err)
//                                return completion(err)
//                            }
//
//                            let instrument = PaymentInstrument(
//                                paymentMethodConfigId: applePayConfigId,
//                                token: applePayPaymentResponse.token,
//                                sourceConfig: ApplePaySourceConfig(source: "IN_APP", merchantId: merchantIdentifier)
//                            )
//
//                            applePayService.tokenize(instrument: instrument) { [weak self] (result) in
//                                switch result {
//                                case .failure(let err):
//                                    // Dismiss and show error screen
//                                    _ = ErrorHandler.shared.handle(error: err)
//                                    DispatchQueue.main.async {
//                                        Primer.shared.presentingViewController?.dismiss(animated: true, completion: {
//                                            let router: RouterDelegate = DependencyContainer.resolve()
//                                            router.presentErrorScreen(with: err)
//                                        })
//
//                                        Primer.shared.delegate?.checkoutFailed?(with: err)
//                                    }
//
//                                    completion(err)
//
//                                case .success(let token):
//                                    DispatchQueue.main.async {
//                                        if Primer.shared.flow.internalSessionFlow.vaulted {
//                                            Primer.shared.delegate?.tokenAddedToVault?(token)
//                                            completion(nil)
//                                        } else {
//                                            //settings.onTokenizeSuccess(token, completion)
//                                            Primer.shared.delegate?.authorizePayment?(token, { (err) in
//                                                DispatchQueue.main.async {
//                                                    Primer.shared.presentingViewController?.dismiss(animated: true, completion: {
//                                                        let router: RouterDelegate = DependencyContainer.resolve()
//
//                                                        if let err = err {
//                                                            router.presentErrorScreen(with: err)
//                                                        } else {
//                                                            router.presentSuccessScreen(for: .regular)
//                                                        }
//                                                    })
//
//                                                    completion(err)
//                                                }
//                                            })
//                                            Primer.shared.delegate?.onTokenizeSuccess?(token, { (err) in
//                                                DispatchQueue.main.async {
//                                                    Primer.shared.presentingViewController?.dismiss(animated: true, completion: {
//                                                        let router: RouterDelegate = DependencyContainer.resolve()
//
//                                                        if let err = err {
//                                                            router.presentErrorScreen(with: err)
//                                                        } else {
//                                                            router.presentSuccessScreen(for: .regular)
//                                                        }
//                                                    })
//
//                                                    completion(err)
//                                                }
//                                            })
//                                        }
//                                    }
//                                }
//                            }
//                        }
//                    }
//
//                case .failure(let err):
//                    _ = ErrorHandler.shared.handle(error: err)
//                    Primer.shared.delegate?.checkoutFailed?(with: err)
//                    completion(err)
//                }
            }
        }
        
        func createpaymentRequest() throws -> PKPaymentRequest {
            let supportedNetworks = PaymentNetwork.iOSSupportedPKPaymentNetworks
            if PKPaymentAuthorizationViewController.canMakePayments(usingNetworks: supportedNetworks) {
                let request = PKPaymentRequest()
//                request.currencyCode = currency.rawValue
//                request.countryCode = countryCode.rawValue
//                request.merchantIdentifier = merchantIdentifier
//                request.merchantCapabilities = [.capability3DS]
//                request.supportedNetworks = supportedNetworks
//                request.paymentSummaryItems = applePayRequest.items.compactMap({ $0.applePayItem })
                
                return request
                
            } else {
                log(logLevel: .error, title: "APPLE PAY", message: "Cannot make payments on the provided networks")
                throw AppleException.unableToMakePaymentsOnProvidedNetworks
            }
        }
        
        
        
        
        
        
        
        
        
        
        
        
        
        
        
//        func tokenize() -> Promise<PaymentMethodToken> {
//
//        }
//
//        func present(on viewController: PrimerViewController) -> Promise<URL> {
//
//        }
//
//        func present(completionHandler: ((Bool) -> Void)?) {
//
//        }
//
//        func showResult(_ result: Result<String, Error>, completionHandler: ((Bool) -> Void)?) {
//
//        }
        
        func paymentAuthorizationViewControllerDidFinish(_ controller: PKPaymentAuthorizationViewController) {
            
        }
    }
}

class PrimerPKPaymentAuthorizationViewController: PKPaymentAuthorizationViewController, APMViewController {
    var name: String {
        return ConfigPaymentMethodType.applePay.rawValue
    }
    var request: APMRequest!
    var completionHandler: (([String : String]?, Error?) -> Void)?
    
}

protocol APMRequest {}
extension URLRequest: APMRequest {}
extension PKPaymentRequest: APMRequest {}
