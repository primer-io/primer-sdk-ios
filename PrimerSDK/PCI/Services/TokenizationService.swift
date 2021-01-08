protocol TokenizationServiceProtocol {
    func tokenize(
        with clientToken: ClientToken,
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, Error>) -> Void
    )
}

class TokenizationService: TokenizationServiceProtocol {
    
    private let api: APIClientProtocol
    
    init(with api: APIClientProtocol) { self.api = api }
    
    func tokenize(
        with clientToken: ClientToken,
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, Error>) -> Void
    ) {
        guard let pciURL = clientToken.pciUrl else { return }
        guard let url = URL(string: "\(pciURL)/payment-instruments") else { return }
        
        self.api.post(clientToken, body: request, url: url, completion: { result in
            do {
                switch result {
                case .failure: onTokenizeSuccess(.failure(PrimerError.ClientTokenNull))
                case .success(let data):
                    let token = try JSONDecoder().decode(PaymentMethodToken.self, from: data)
                    onTokenizeSuccess(.success(token))
                }
            } catch {
                onTokenizeSuccess(.failure(PrimerError.ClientTokenNull))
            }
        })
    }
}

class MockTokenizationService: TokenizationServiceProtocol {
    
    var tokenizeCalled = false
    
    func tokenize(with clientToken: ClientToken, request: PaymentMethodTokenizationRequest, onTokenizeSuccess: @escaping (Result<PaymentMethodToken, Error>) -> Void) {
        tokenizeCalled = true
        let token = PaymentMethodToken(token: "tokenID")
        return onTokenizeSuccess(.success(token))
    }
}
