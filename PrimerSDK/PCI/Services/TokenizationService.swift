protocol TokenizationServiceProtocol {
    func tokenize(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, PrimerError>) -> Void
    )
}

class TokenizationService: TokenizationServiceProtocol {
    
    @Dependency private(set) var api: APIClientProtocol
    @Dependency private(set) var state: AppStateProtocol
    
    let primerAPI = PrimerAPIClient()
    
    func tokenize(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, PrimerError>) -> Void
    ) {
        guard let clientToken = state.decodedClientToken else {
            return onTokenizeSuccess(.failure(PrimerError.TokenizationPreRequestFailed))
        }
        
        print("🔥🔥🔥🔥🔥 clientToken:", clientToken)
        
        guard let pciURL = clientToken.pciUrl else {
            return onTokenizeSuccess(.failure(PrimerError.TokenizationPreRequestFailed))
        }
        
        print("🔥🔥🔥🔥🔥 pciURL:", pciURL)
        
        guard let url = URL(string: "\(pciURL)/payment-instruments") else {
            return onTokenizeSuccess(.failure(PrimerError.TokenizationPreRequestFailed))
        }
        
        print("🔥🔥🔥🔥🔥 url:", url)
        
        primerAPI.tokenizePaymentMethod(clientToken: clientToken, paymentMethodTokenizationRequest: request) { (result) in
            switch result {
            case .failure:
                onTokenizeSuccess(.failure( PrimerError.TokenizationRequestFailed ))
            case .success(let paymentMethodToken):
                onTokenizeSuccess(.success(paymentMethodToken))
            
            }
        }
    }
}
