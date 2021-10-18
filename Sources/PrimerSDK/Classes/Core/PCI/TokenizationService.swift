import Foundation

#if canImport(UIKit)

internal protocol TokenizationServiceProtocol {
    var paymentMethod: PaymentMethod? { get set }
    func tokenize(
        request: TokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethod, PrimerError>) -> Void
    )
    func tokenize(request: TokenizationRequest) -> Promise<PaymentMethod>
}

internal class TokenizationService: TokenizationServiceProtocol {
    
    var paymentMethod: PaymentMethod?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func tokenize(
        request: TokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethod, PrimerError>) -> Void
    ) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return onTokenizeSuccess(.failure(PrimerError.tokenizationPreRequestFailed))
        }

        log(logLevel: .verbose, title: nil, message: "Client Token: \(clientToken)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

        guard let pciURL = clientToken.pciUrl else {
            return onTokenizeSuccess(.failure(PrimerError.tokenizationPreRequestFailed))
        }

        log(logLevel: .verbose, title: nil, message: "PCI URL: \(pciURL)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)

        guard let url = URL(string: "\(pciURL)/payment-instruments") else {
            return onTokenizeSuccess(.failure(PrimerError.tokenizationPreRequestFailed))
        }

        log(logLevel: .verbose, title: nil, message: "URL: \(url)", prefix: nil, suffix: nil, bundle: nil, file: #file, className: String(describing: Self.self), function: #function, line: #line)
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        api.tokenizePaymentMethod(clientToken: clientToken, paymentMethodTokenizationRequest: request) { (result) in
            switch result {
            case .failure:
                DispatchQueue.main.async {
                    onTokenizeSuccess(.failure( PrimerError.tokenizationRequestFailed ))
                }
                
            case .success(let paymentMethod):
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                let state: AppStateProtocol = DependencyContainer.resolve()
                
                self.paymentMethod = paymentMethod
                
                var isThreeDSEnabled: Bool = false
                if state.paymentMethodConfig?.paymentMethods?.filter({ ($0.options as? CardOptions)?.threeDSecureEnabled == true }).count ?? 0 > 0 {
                    isThreeDSEnabled = true
                }

                /// 3DS requirements on tokenization are:
                ///     - The payment method has to be a card
                ///     - It has to be a vault flow
                ///     - is3DSOnVaultingEnabled has to be enabled by the developer
                ///     - 3DS has to be enabled int he payment methods options in the config object (returned by the config API call)
                if paymentMethod.paymentInstrumentType == .paymentCard,
                   Primer.shared.flow.internalSessionFlow.vaulted,
                   settings.is3DSOnVaultingEnabled,
                   paymentMethod.threeDSecureAuthentication?.responseCode != ThreeDS.ResponseCode.authSuccess,
                   isThreeDSEnabled {
                    #if canImport(Primer3DS)
                    let threeDSService: ThreeDSServiceProtocol = ThreeDSService()
                    DependencyContainer.register(threeDSService)
                    
                    var threeDSBeginAuthExtraData: ThreeDS.BeginAuthExtraData
                    do {
                        threeDSBeginAuthExtraData = try ThreeDSService.buildBeginAuthExtraData()
                    } catch {
                        onTokenizeSuccess(.success(paymentMethod))
                        return
                    }

                    threeDSService.perform3DS(
                        paymentMethod: paymentMethod,
                        protocolVersion: state.decodedClientToken?.env == "PRODUCTION" ? .v1 : .v2,
                        beginAuthExtraData: threeDSBeginAuthExtraData,
                            sdkDismissed: { () in

                            }, completion: { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let res):
                                        if case .VAULT = Primer.shared.flow.internalSessionFlow.uxMode {
                                            Primer.shared.delegate?.tokenAddedToVault?(res.0)
                                        }

                                        onTokenizeSuccess(.success(res.0))
                                        
                                    case .failure(let err):
                                        // Even if 3DS fails, continue...
                                        log(logLevel: .error, message: "3DS failed with error: \(err as NSError), continue without 3DS")
                                        onTokenizeSuccess(.success(paymentMethod))
                                        
                                    }
                                }

                            })
                    
                    #else
                    print("\nWARNING!\nCannot perform 3DS, Primer3DS SDK is missing. Continue without 3DS\n")
                    onTokenizeSuccess(.success(paymentMethod))
                    #endif
                    
                } else {
                    onTokenizeSuccess(.success(paymentMethod))
                }
            }
        }
    }
    
    func tokenize(request: TokenizationRequest) -> Promise<PaymentMethod> {
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
