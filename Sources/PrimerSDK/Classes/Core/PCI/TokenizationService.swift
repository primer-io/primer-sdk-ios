#if canImport(UIKit)

import Foundation

internal protocol TokenizationServiceProtocol {
    var tokenizedPaymentMethodToken: PaymentMethodToken? { get set }
    func tokenize(
        request: TokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, Error>) -> Void
    )
    func tokenize(request: TokenizationRequest) -> Promise<PaymentMethodToken>
}

internal class TokenizationService: TokenizationServiceProtocol {
    
    var tokenizedPaymentMethodToken: PaymentMethodToken?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func tokenize(
        request: TokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, Error>) -> Void
    ) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            onTokenizeSuccess(.failure(err))
            return
        }

        log(logLevel: .verbose, title: nil, message: "Client Token: \(decodedClientToken)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

        guard let pciURL = decodedClientToken.pciUrl else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            onTokenizeSuccess(.failure(err))
            return
        }

        log(logLevel: .verbose, title: nil, message: "PCI URL: \(pciURL)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

        guard let url = URL(string: "\(pciURL)/payment-instruments") else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl", value: decodedClientToken.pciUrl, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            onTokenizeSuccess(.failure(err))
            return
        }

        log(logLevel: .verbose, title: nil, message: "URL: \(url)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        api.tokenizePaymentMethod(clientToken: decodedClientToken, paymentMethodTokenizationRequest: request) { (result) in
            switch result {
            case .failure(let err):
                DispatchQueue.main.async { onTokenizeSuccess(.failure(err)) }
                
            case .success(let paymentMethodToken):
                self.tokenizedPaymentMethodToken = paymentMethodToken
                
                var isThreeDSEnabled: Bool = false
                if AppState.current.apiConfiguration?.paymentMethods?.filter({ ($0.options as? CardOptions)?.threeDSecureEnabled == true }).count ?? 0 > 0 {
                    isThreeDSEnabled = true
                }

                /// 3DS requirements on tokenization are:
                ///     - The payment method has to be a card
                ///     - It has to be a vault flow
                ///     - is3DSOnVaultingEnabled has to be enabled by the developer
                ///     - 3DS has to be enabled int he payment methods options in the config object (returned by the config API call)
                if paymentMethodToken.paymentInstrumentType == .paymentCard,
                   Primer.shared.intent == .vault,
                   PrimerSettings.current.paymentMethodOptions.cardPaymentOptions.is3DSOnVaultingEnabled,
                   paymentMethodToken.threeDSecureAuthentication?.responseCode != ThreeDS.ResponseCode.authSuccess,
                   isThreeDSEnabled {
                    #if canImport(Primer3DS)
                    let threeDSService: ThreeDSServiceProtocol = ThreeDSService()
                    DependencyContainer.register(threeDSService)
                    
                    var threeDSBeginAuthExtraData: ThreeDS.BeginAuthExtraData
                    do {
                        threeDSBeginAuthExtraData = try ThreeDSService.buildBeginAuthExtraData()
                    } catch {
                        onTokenizeSuccess(.success(paymentMethodToken))
                        return
                    }
                    
                    guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                        let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                        ErrorHandler.handle(error: err)
                        onTokenizeSuccess(.failure(err))
                        return
                    }

                    threeDSService.perform3DS(
                            paymentMethodToken: paymentMethodToken,
                        protocolVersion: decodedClientToken.env == "PRODUCTION" ? .v1 : .v2,
                        beginAuthExtraData: threeDSBeginAuthExtraData,
                            sdkDismissed: { () in

                            }, completion: { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let paymentMethodToken):
                                        onTokenizeSuccess(.success(paymentMethodToken.0))
                                        
                                    case .failure(let err):
                                        // Even if 3DS fails, continue...
                                        log(logLevel: .error, message: "3DS failed with error: \(err as NSError), continue without 3DS")
                                        onTokenizeSuccess(.success(paymentMethodToken))
                                        
                                    }
                                }

                            })
                    
                    #else
                    print("\nWARNING!\nCannot perform 3DS, Primer3DS SDK is missing. Continue without 3DS\n")
                    onTokenizeSuccess(.success(paymentMethodToken))
                    #endif
                    
                } else {
                    onTokenizeSuccess(.success(paymentMethodToken))
                }
            }
        }
    }
    
    func tokenize(request: TokenizationRequest) -> Promise<PaymentMethodToken> {
        return Promise { seal in
            self.tokenize(request: request) { result in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let res):
                    seal.fulfill(res)
                }
            }
        }
    }
}

#endif
