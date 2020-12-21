import UIKit

class TokenizationService {
    
    private let pciEndpoint = "https://api.sandbox.primer.io"
//    private let pciEndpoint = "http://192.168.0.50:8081"
    private let clientToken: ClientToken
    private let api: APIClientProtocol
    
    init(clientToken: ClientToken, api: APIClientProtocol) {
        self.clientToken = clientToken
        self.api = api
    }
    
    func tokenize(
        request: PaymentMethodTokenizationRequest,
        onTokenizeSuccess: @escaping (Result<PaymentMethodToken, Error>) -> Void
    ) {
        guard let url = URL(string: "\(pciEndpoint)/payment-instruments") else { return }
        print("url:", url)
        self.api.post(clientToken, body: request, url: url, completion: { result in
            do {
                let data = try result.get()
                let token = try JSONDecoder().decode(PaymentMethodToken.self, from: data)
                print("token:", token)
                onTokenizeSuccess(.success(token))
            } catch {
                let tokenizationError = PaymentMethodTokenizationError(description: error.localizedDescription)
                onTokenizeSuccess(.failure(tokenizationError))
            }
        })
    }
}
