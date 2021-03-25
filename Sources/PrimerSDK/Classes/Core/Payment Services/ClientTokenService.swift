#if canImport(UIKit)

protocol ClientTokenServiceProtocol {
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void)
}

class ClientTokenService: ClientTokenServiceProtocol {

    @Dependency private(set) var state: AppStateProtocol

    /**
    performs asynchronous call passed in by app developer, decodes the returned Base64 Primer client token string and adds it to shared state.
     */
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        state.settings.clientTokenRequestCallback({ [weak self] result in
            switch result {
            case .failure: completion(PrimerError.ClientTokenNull)
            case .success(let token):
                guard let clientToken = token.clientToken else { return completion(PrimerError.ClientTokenNull) }
                self?.state.decodedClientToken = clientToken.decodeClientTokenBase64()
                completion(nil)
            }
        })
    }

}

#endif
