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
        guard let jwtTokenPayload = clientToken.jwtTokenPayload,
              let expDate = jwtTokenPayload.expDate
        else {
            return nil
        }
        
        if expDate < Date() {
            return nil
        }
        
        return jwtTokenPayload
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
        let previousEnv = ClientTokenService.decodedClientToken?.env
        
        jwtTokenPayload.configurationUrl = jwtTokenPayload.configurationUrl?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        jwtTokenPayload.coreUrl = jwtTokenPayload.coreUrl?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        jwtTokenPayload.pciUrl = jwtTokenPayload.pciUrl?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        
        if jwtTokenPayload.env == nil {
            // That's because the clientToken returned for dynamic 3DS doesn't contain an env.
            jwtTokenPayload.env = previousEnv
        }

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
