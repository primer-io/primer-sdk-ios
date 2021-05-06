#if canImport(UIKit)

protocol ClientTokenServiceProtocol {
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void)
}

class ClientTokenService: ClientTokenServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    /**
    performs asynchronous call passed in by app developer, decodes the returned Base64 Primer client token string and adds it to shared state.
     */
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        settings.clientTokenRequestCallback({ [weak self] result in
            switch result {
            case .failure:
                completion(PrimerError.clientTokenNull)
            case .success(let token):
                guard let jwtTokenPayload = token.jwtTokenPayload,
                      let expDate = jwtTokenPayload.expDate
                else {
                    Primer.shared.delegate?.checkoutFailed(with: PrimerError.clientTokenNull)
                    return completion(PrimerError.clientTokenNull)
                }
                
                if expDate < Date() {
                    Primer.shared.delegate?.checkoutFailed(with: PrimerError.tokenExpired)
                    return completion(PrimerError.tokenExpired)
                }
                
                if let jwtTokenPayload = token.jwtTokenPayload {
                    state.decodedClientToken = jwtTokenPayload
                    completion(nil)
                } else {
                    completion(PrimerError.clientTokenNull)
                }
            }
        })
    }

}

#endif
