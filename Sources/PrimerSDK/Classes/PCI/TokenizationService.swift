#if canImport(UIKit)

import Foundation

internal protocol TokenizationServiceProtocol {
    
    static var apiClient: PrimerAPIClientProtocol? { get set }
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get set }
    
    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData>
    func exchangePaymentMethodToken(_ paymentMethodToken: PrimerPaymentMethodTokenData) -> Promise<PrimerPaymentMethodTokenData>
}

internal class TokenizationService: TokenizationServiceProtocol {
    
    static var apiClient: PrimerAPIClientProtocol?
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            log(logLevel: .verbose, title: nil, message: "Client Token: \(decodedJWTToken)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

            guard let pciURL = decodedJWTToken.pciUrl else {
                let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedJWTToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            log(logLevel: .verbose, title: nil, message: "PCI URL: \(pciURL)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

            guard let url = URL(string: "\(pciURL)/payment-instruments") else {
                let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedJWTToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            log(logLevel: .verbose, title: nil, message: "URL: \(url)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
                       
            let apiClient: PrimerAPIClientProtocol = TokenizationService.apiClient ?? PrimerAPIClient()
            
            apiClient.tokenizePaymentMethod(clientToken: decodedJWTToken, tokenizationRequestBody: requestBody) { (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                    
                case .success(let paymentMethodTokenData):
                    self.paymentMethodTokenData = paymentMethodTokenData
                    
                    var isThreeDSEnabled: Bool = false
                    if PrimerAPIConfigurationModule.apiConfiguration?.paymentMethods?.filter({ ($0.options as? CardOptions)?.threeDSecureEnabled == true }).count ?? 0 > 0 {
                        isThreeDSEnabled = true
                    }

                    /// 3DS requirements on tokenization are:
                    ///     - The payment method has to be a card
                    ///     - It has to be a vault flow
                    ///     - is3DSOnVaultingEnabled has to be enabled by the developer
                    ///     - 3DS has to be enabled int he payment methods options in the config object (returned by the config API call)
                    if paymentMethodTokenData.paymentInstrumentType == .paymentCard,
                       PrimerInternal.shared.intent == .vault,
                       paymentMethodTokenData.threeDSecureAuthentication?.responseCode != ThreeDS.ResponseCode.authSuccess,
                       isThreeDSEnabled {
                        print("\nWARNING!\nCannot perform 3DS when vaulting, operation will continue without 3DS\n")
                        seal.fulfill(paymentMethodTokenData)
                        
                    } else {
                        seal.fulfill(paymentMethodTokenData)
                    }
                }
            }
        }
    }
    
    func exchangePaymentMethodToken(_ paymentMethodToken: PrimerPaymentMethodTokenData) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let apiClient: PrimerAPIClientProtocol = CheckoutWithVaultedPaymentMethodViewModel.apiClient ?? PrimerAPIClient()
            
            apiClient.exchangePaymentMethodToken(clientToken: decodedJWTToken, paymentMethodId: paymentMethodToken.id!) { result in
                DispatchQueue.main.async {
                    switch result {
                    case .success(let singleUsePaymentMethod):
                        seal.fulfill(singleUsePaymentMethod)
                    case .failure(let error):
                        seal.reject(error)
                    }
                }
            }
        }
    }
}

#endif
