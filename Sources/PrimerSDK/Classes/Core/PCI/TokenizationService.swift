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
                onTokenizeSuccess(.failure( PrimerError.tokenizationRequestFailed ))
            case .success(let paymentMethodToken):
                if case .VAULT = Primer.shared.flow.internalSessionFlow.uxMode {
                    DispatchQueue.main.async {
                        Primer.shared.delegate?.tokenAddedToVault(paymentMethodToken)
                    }
                }
                onTokenizeSuccess(.success(paymentMethodToken))

            }
        }
    }
}

#endif
