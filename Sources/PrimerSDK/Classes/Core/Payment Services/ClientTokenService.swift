#if canImport(UIKit)

import Foundation

internal protocol ClientTokenServiceProtocol {
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void)
}

internal class ClientTokenService: ClientTokenServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    /**
    performs asynchronous call passed in by app developer, decodes the returned Base64 Primer client token string and adds it to shared state.
     */
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        settings.clientTokenRequestCallback({ [weak self] (token, err) in
            if let err = err {
                completion(err)
            } else if let token = token {
                guard let jwtTokenPayload = token.jwtTokenPayload,
                      let expDate = jwtTokenPayload.expDate
                else {
                    return completion(PrimerError.clientTokenNull)
                }
                
                if expDate < Date() {
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
