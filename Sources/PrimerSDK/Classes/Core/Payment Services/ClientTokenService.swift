#if canImport(UIKit)

import Foundation

internal protocol ClientTokenServiceProtocol {
    static func storeClientToken(_ clientToken: String) throws
    func fetchClientToken(_ completion: @escaping (Error?) -> Void)
}

internal class ClientTokenService: ClientTokenServiceProtocol {
    
    static var decodedClientToken: DecodedClientToken? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let clientToken = state.clientToken else { return nil }
        
        guard let decodedClientToken = clientToken.jwtTokenPayload else { return nil }
        
        do {
            try decodedClientToken.validate()
        } catch {
            return nil
        }

        return decodedClientToken
    }
    
    static func storeClientToken(_ clientToken: String) throws {
        guard var decodedClientToken = clientToken.jwtTokenPayload else { throw PrimerError.clientTokenNull }
        
        try decodedClientToken.validate()
        
        let previousEnv = ClientTokenService.decodedClientToken?.env
        
        if decodedClientToken.env == nil {
            // That's because the clientToken returned for dynamic 3DS doesn't contain an env.
            decodedClientToken.env = previousEnv
        }

        let state: AppStateProtocol = DependencyContainer.resolve()
        state.clientToken = clientToken
    }
    
    static func resetClientToken() {
        let state: AppStateProtocol = DependencyContainer.resolve()
        state.clientToken = nil
    }
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    /**
    performs asynchronous call passed in by app developer, decodes the returned Base64 Primer client token string and adds it to shared state.
     */
    func fetchClientToken(_ completion: @escaping (Error?) -> Void) {
        guard let clientTokenCallback = Primer.shared.delegate?.clientTokenCallback else {
            let err = PrimerError.invalidValue(key: "clientTokenCallback delegate function.")
            completion(err)
            return
        }
        
        clientTokenCallback({ (token, err) in
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
