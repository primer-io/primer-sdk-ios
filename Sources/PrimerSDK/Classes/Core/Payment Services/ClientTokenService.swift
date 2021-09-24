#if canImport(UIKit)

import Foundation

internal protocol ClientTokenServiceProtocol {
    static func storeClientToken(_ clientToken: String) throws
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void)
}

internal class ClientTokenService: ClientTokenServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    static func storeClientToken(_ clientToken: String) throws {
        guard var jwtTokenPayload = clientToken.jwtTokenPayload,
              let expDate = jwtTokenPayload.expDate
        else {
            throw PrimerError.clientTokenNull
        }
        
        if expDate < Date() {
            throw PrimerError.clientTokenExpired
        }
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        let previousEnv = state.decodedClientToken?.env
        
        if jwtTokenPayload.env == nil {
            // That's because the clientToken returned for dynamic 3DS doesn't contain an env.
            jwtTokenPayload.env = previousEnv
        }

        state.decodedClientToken = jwtTokenPayload
        state.accessToken = clientToken
    }

    /**
    performs asynchronous call passed in by app developer, decodes the returned Base64 Primer client token string and adds it to shared state.
     */
    func loadCheckoutConfig(_ completion: @escaping (Error?) -> Void) {
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        settings.clientTokenRequestCallback({ [weak self] (token, err) in
            if let err = err {
                completion(err)
            } else if let token = token {
                do {
                    try ClientTokenService.storeClientToken(token)
                    completion(nil)
                } catch {
                    completion(error)
                }
            }
        })
    }

}

#endif
