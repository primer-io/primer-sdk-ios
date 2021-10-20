#if canImport(UIKit)

import Foundation

internal protocol ClientTokenServiceProtocol {
    static var decodedClientToken: DecodedClientToken? { get }
    static func storeClientToken(_ clientToken: String) throws
    func fetchClientToken(_ completion: @escaping (Error?) -> Void)
    static func resetClientToken()
}

internal class ClientTokenService: ClientTokenServiceProtocol {
    
    static var decodedClientToken: DecodedClientToken? {
        let state: AppStateProtocol = DependencyContainer.resolve()
        guard let clientToken = state.clientToken else { return nil }
        
        guard var decodedClientToken = clientToken.jwtTokenPayload else { return nil }
        
        decodedClientToken.configurationUrlStr = decodedClientToken.configurationUrlStr?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        decodedClientToken.coreUrlStr = decodedClientToken.coreUrlStr?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        decodedClientToken.pciUrlStr = decodedClientToken.pciUrlStr?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        
        do {
            try decodedClientToken.validate()
            return decodedClientToken
        } catch {
            return nil
        }
    }
    
    static func storeClientToken(_ clientToken: String) throws {
        guard var decodedClientToken = clientToken.jwtTokenPayload else {
            throw PrimerError.clientTokenNull
        }
        
        try decodedClientToken.validate()
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        let previousEnv = ClientTokenService.decodedClientToken?.env
        
        decodedClientToken.configurationUrlStr = decodedClientToken.configurationUrlStr?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        decodedClientToken.coreUrlStr = decodedClientToken.coreUrlStr?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        decodedClientToken.pciUrlStr = decodedClientToken.pciUrlStr?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        
        if decodedClientToken.env == nil {
            // That's because the clientToken returned for dynamic 3DS doesn't contain an env.
            decodedClientToken.env = previousEnv
        }

        state.clientToken = clientToken
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
    
    static func resetClientToken() {
        let state: AppStateProtocol = DependencyContainer.resolve()
        state.clientToken = nil
    }

}

#endif
