#if canImport(UIKit)

import Foundation

internal protocol TokenizationServiceProtocol {
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData? { get set }
    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData>
}

internal class TokenizationService: TokenizationServiceProtocol {
    
    var paymentMethodTokenData: PrimerPaymentMethodTokenData?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    func tokenize(requestBody: Request.Body.Tokenization) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            log(logLevel: .verbose, title: nil, message: "Client Token: \(decodedClientToken)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

            guard let pciURL = decodedClientToken.pciUrl else {
                let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            log(logLevel: .verbose, title: nil, message: "PCI URL: \(pciURL)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

            guard let url = URL(string: "\(pciURL)/payment-instruments") else {
                let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            log(logLevel: .verbose, title: nil, message: "URL: \(url)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
            
            let api: PrimerAPIClientProtocol = PrimerAPIClient()
            
            api.tokenizePaymentMethod(clientToken: decodedClientToken, tokenizationRequestBody: requestBody) { (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                    
                case .success(let paymentMethodTokenData):
                    self.paymentMethodTokenData = paymentMethodTokenData
                    
                    var isThreeDSEnabled: Bool = false
                    if AppState.current.apiConfiguration?.paymentMethods?.filter({ ($0.options as? CardOptions)?.threeDSecureEnabled == true }).count ?? 0 > 0 {
                        isThreeDSEnabled = true
                    }

                    /// 3DS requirements on tokenization are:
                    ///     - The payment method has to be a card
                    ///     - It has to be a vault flow
                    ///     - is3DSOnVaultingEnabled has to be enabled by the developer
                    ///     - 3DS has to be enabled int he payment methods options in the config object (returned by the config API call)
                    if paymentMethodTokenData.paymentInstrumentType == .paymentCard,
                       PrimerInternal.shared.intent == .vault,
                       PrimerSettings.current.paymentMethodOptions.cardPaymentOptions.is3DSOnVaultingEnabled,
                       paymentMethodTokenData.threeDSecureAuthentication?.responseCode != ThreeDS.ResponseCode.authSuccess,
                       isThreeDSEnabled {
                        #if canImport(Primer3DS)
                        let threeDSService: ThreeDSServiceProtocol = ThreeDSService()
                        DependencyContainer.register(threeDSService)
                        
                        var threeDSBeginAuthExtraData: ThreeDS.BeginAuthExtraData
                        do {
                            threeDSBeginAuthExtraData = try ThreeDSService.buildBeginAuthExtraData()
                        } catch {
                            seal.fulfill(paymentMethodTokenData)
                            return
                        }
                        
                        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                            ErrorHandler.handle(error: err)
                            seal.reject(err)
                            return
                        }

                        threeDSService.perform3DS(
                            paymentMethodTokenData: paymentMethodTokenData,
                            protocolVersion: decodedClientToken.env == "PRODUCTION" ? .v1 : .v2,
                            beginAuthExtraData: threeDSBeginAuthExtraData,
                                sdkDismissed: { () in

                                }, completion: { result in
                                    DispatchQueue.main.async {
                                        switch result {
                                        case .success(let paymentMethodTokenData):
                                            seal.fulfill(paymentMethodTokenData.0)
                                        case .failure(let err):
                                            // Even if 3DS fails, continue...
                                            log(logLevel: .error, message: "3DS failed with error: \(err as NSError), continue without 3DS")
                                            seal.fulfill(paymentMethodTokenData)
                                        }
                                    }

                                })
                        
                        #else
                        print("\nWARNING!\nCannot perform 3DS, Primer3DS SDK is missing. Continue without 3DS\n")
                        seal.fulfill(paymentMethodTokenData)
                        #endif
                        
                    } else {
                        seal.fulfill(paymentMethodTokenData)
                    }
                }
            }
        }
    }
}

#endif
