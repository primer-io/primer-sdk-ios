#if canImport(UIKit)

import Foundation

internal protocol ClientTokenServiceProtocol {
    static var clientToken: String? { get }
    static var decodedClientToken: DecodedClientToken? { get }
    static func storeClientToken(_ clientToken: String) throws
    static func resetClientToken()
    func fetchClientToken(_ completion: @escaping (Error?) -> Void)
}

internal class ClientTokenService: ClientTokenServiceProtocol {
    
    static var clientToken: String? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        return state.clientToken
    }
    
    static var decodedClientToken: DecodedClientToken? {
        guard let clientToken = ClientTokenService.clientToken,
              let decodedClientToken = clientToken.jwtTokenPayload,
              let expDate = decodedClientToken.expDate,
              expDate < Date()
        else {
            ClientTokenService.resetClientToken()
            return nil
        }

        return decodedClientToken
    }
    
    static func storeClientToken(_ clientToken: String) throws {
        guard var decodedClientToken = clientToken.jwtTokenPayload,
              let expDate = decodedClientToken.expDate
        else {
            throw PrimerError.clientTokenNull
        }
        
        if expDate < Date() {
            throw PrimerError.clientTokenExpired
        }
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        let previousEnv = ClientTokenService.decodedClientToken?.env
        
        if decodedClientToken.env == nil {
            // That's because the clientToken returned for dynamic 3DS doesn't contain an env.
            decodedClientToken.env = previousEnv
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
