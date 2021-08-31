import Foundation

#if canImport(UIKit)

internal protocol TokenizationServiceProtocol {
    func tokenize(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, PrimerError>) -> Void
    )
}

internal class TokenizationService: TokenizationServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func tokenize(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, PrimerError>) -> Void
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
                
            case .success(let paymentMethodToken):
                let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
                let state: AppStateProtocol = DependencyContainer.resolve()
                
                var isThreeDSEnabled: Bool = false
                
                if state.paymentMethodConfig?.paymentMethods?.filter({ ($0.options as? CardOptions)?.threeDSecureEnabled == true }).count ?? 0 > 0 {
                    isThreeDSEnabled = true
                }
                               
                #if canImport(Primer3DS)
                if settings.is3DSEnabled && paymentMethodToken.paymentInstrumentType == .paymentCard && paymentMethodToken.threeDSecureAuthentication?.responseCode != ThreeDS.ResponseCode.authSuccess && isThreeDSEnabled {
                    
                    let threeDSService: ThreeDSServiceProtocol = ThreeDSService()
                    DependencyContainer.register(threeDSService)
                    
                    threeDSService.perform3DS(
                            paymentMethodToken: paymentMethodToken,
                        protocolVersion: state.decodedClientToken?.env == "PRODUCTION" ? .v1 : .v2,
                            sdkDismissed: { () in
                                
                            }, completion: { result in
                                DispatchQueue.main.async {
                                    switch result {
                                    case .success(let paymentMethodToken):
                                        if case .VAULT = Primer.shared.flow.internalSessionFlow.uxMode {
                                            Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
                                        }
                                                                                
                                        onTokenizeSuccess(.success(paymentMethodToken))
                                    case .failure(let err):
                                        onTokenizeSuccess(.failure( PrimerError.tokenizationRequestFailed ))
                                    }
                                }
                                
                            })
                } else {
                    DispatchQueue.main.async {
                        if settings.is3DSEnabled && paymentMethodToken.paymentInstrumentType == .paymentCard {
                            print("\nWARNING!\nCannot perform 3DS. Continue without 3DS\n")
                        }
                        
                        if case .VAULT = Primer.shared.flow.internalSessionFlow.uxMode {
                            Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
                        }
                        
                        onTokenizeSuccess(.success(paymentMethodToken))
                    }
                }
                #else
                DispatchQueue.main.async {
                    if settings.is3DSEnabled && paymentMethodToken.paymentInstrumentType == .paymentCard {
                        print("\nWARNING!\nCannot perform 3DS. Continue without 3DS\n")
                    }
                    
                    if case .VAULT = Primer.shared.flow.internalSessionFlow.uxMode {
                        Primer.shared.delegate?.tokenAddedToVault?(paymentMethodToken)
                    }
                    
                    onTokenizeSuccess(.success(paymentMethodToken))
                }
                #endif
            }
        }
    }
}

#endif
