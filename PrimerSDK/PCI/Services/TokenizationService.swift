protocol TokenizationServiceProtocol {
    func tokenize(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, PrimerError>) -> Void
    )
}

class TokenizationService: TokenizationServiceProtocol {
    
    @Dependency private(set) var api: APIClientProtocol
    @Dependency private(set) var state: AppStateProtocol
    
    func tokenize(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, PrimerError>) -> Void
    ) {
        guard let clientToken = state.decodedClientToken else {
            return onTokenizeSuccess(.failure(PrimerError.TokenizationPreRequestFailed))
        }
        
        guard let pciURL = clientToken.pciUrl else {
            return onTokenizeSuccess(.failure(PrimerError.TokenizationPreRequestFailed))
        }
        
        guard let url = URL(string: "\(pciURL)/payment-instruments") else {
            return onTokenizeSuccess(.failure(PrimerError.TokenizationPreRequestFailed))
        }
        
        self.api.post(clientToken, body: request, url: url, completion: { result in
            do {
                switch result {
                case .failure:
                    onTokenizeSuccess(.failure( PrimerError.TokenizationRequestFailed ))
                case .success(let data):
                    let token = try JSONDecoder().decode(PaymentMethodToken.self, from: data)
                    onTokenizeSuccess(.success(token))
                }
            } catch {
                onTokenizeSuccess(.failure(PrimerError.TokenizationRequestFailed))
            }
        })
    }
}
