import Foundation

#if canImport(UIKit)

protocol TokenizationServiceProtocol {
    func tokenize(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, PrimerError>) -> Void
    )
}

class TokenizationService: TokenizationServiceProtocol {

    @Dependency private(set) var api: PrimerAPIClientProtocol
    @Dependency private(set) var state: AppStateProtocol

    func tokenize(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, PrimerError>) -> Void
    ) {
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

        api.tokenizePaymentMethod(clientToken: clientToken, paymentMethodTokenizationRequest: request) { (result) in
            switch result {
            case .failure:
                onTokenizeSuccess(.failure( PrimerError.tokenizationRequestFailed ))
            case .success(let paymentMethodToken):
                onTokenizeSuccess(.success(paymentMethodToken))

            }
        }
    }
}

#endif
