#if canImport(UIKit)

import Foundation

/// Helper typealias to identify the JWT Token
internal typealias RawJWTToken = String

internal protocol ClientTokenServiceProtocol {
    static func storeClientToken(_ clientToken: String) -> Promise<Void>
    static func storeClientToken(_ clientToken: String, completion: @escaping (Error?) -> Void)
    func fetchClientToken(_ completion: @escaping (Error?) -> Void)
    func fetchClientToken() -> Promise<Void>
    func fetchClientTokenIfNeeded() -> Promise<Void>
}

internal class ClientTokenService: ClientTokenServiceProtocol {
        
    /// The client token from the DepedencyContainer
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
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
}

extension ClientTokenService {
    
    // MARK: API Validation
    
    private static func validateToken(_ clientToken: RawJWTToken, completion: @escaping (Error?) -> Void) {
        
        let clientTokenRequest = ClientTokenValidationRequest(clientToken: clientToken)
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.validateClientToken(request: clientTokenRequest) { result in
            switch result {
            case .success:
                completion(nil)
            case .failure(let error):
                completion(error)
            }
        }
        
    }
    
}

extension ClientTokenService {
    
    // MARK: Internal Validation
    
    // make the internal validation 40:95
    // if passes, then API call (both callback and promise functions)
    // if passes, store it
    
    private static func validateInternally(_ tokenToValidate: RawJWTToken) throws -> RawJWTToken {
        
        guard var currentDecodedToken = tokenToValidate.jwtTokenPayload,
              let expDate = currentDecodedToken.expDate,
              expDate > Date() else {
            let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: error)
            throw error
        }
                        
        let previousDecodedToken = ClientTokenService.decodedClientToken
        
        currentDecodedToken.configurationUrl = currentDecodedToken.configurationUrl?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        currentDecodedToken.coreUrl = currentDecodedToken.coreUrl?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        currentDecodedToken.pciUrl = currentDecodedToken.pciUrl?.replacingOccurrences(of: "10.0.2.2:8080", with: "localhost:8080")
        
        if currentDecodedToken.env == nil {
            currentDecodedToken.env = previousDecodedToken?.env
        }
        
        if currentDecodedToken.analyticsUrl == nil {
            currentDecodedToken.analyticsUrl = previousDecodedToken?.analyticsUrl
        }
        
        if currentDecodedToken.configurationUrl == nil {
            currentDecodedToken.configurationUrl = previousDecodedToken?.configurationUrl
        }
        
        if currentDecodedToken.coreUrl == nil {
            currentDecodedToken.coreUrl = previousDecodedToken?.coreUrl
        }
        
        if currentDecodedToken.pciUrl == nil {
            currentDecodedToken.pciUrl = previousDecodedToken?.pciUrl
        }
        
        var segments: [String] = tokenToValidate.split(separator: ".").compactMap({ String($0) })
        
        var tmpSecondSegment: String?
        if let data = try? JSONEncoder().encode(currentDecodedToken),
           let dataStr = String(data: data.base64EncodedData(), encoding: .utf8) {
            tmpSecondSegment = dataStr
        }
        
        if segments.count > 1, let tmpSecondSegment = tmpSecondSegment {
            segments[1] = tmpSecondSegment
        } else if segments.count == 1, let tmpSecondSegment = tmpSecondSegment {
            segments.append(tmpSecondSegment)
        }
        
        return segments.joined(separator: ".").base64RFC4648Format
        
    }
}

extension ClientTokenService {
    
    // MARK: Store
    
    static func storeClientToken(_ clientToken: String) -> Promise<Void> {
        return Promise { seal in
            storeClientToken(clientToken) { error in
                if let error = error {
                    seal.reject(error)
                } else {
                    seal.fulfill()
                }
            }
        }
    }
    
    static func storeClientToken(_ clientToken: String, completion: @escaping (Error?) -> Void) {
        
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        // 1. Validate the token manually or return the previous one from current App State
        do {
            _ = try validateInternally(clientToken)
        } catch {
            completion(error)
            return
        }
        
        // 2. Validate the token from the dedicated API
        validateToken(clientToken) { error in
            
            guard error == nil else {
                completion(error)
                return
            }
            
            // 3. Assign the new token to the App State
            state.clientToken = clientToken
            completion(nil)
        }
    }
}

extension ClientTokenService {
    
    // MARK: Reset
    
    static func resetClientToken() {
        let state: AppStateProtocol = DependencyContainer.resolve()
        state.clientToken = nil
    }
}

extension ClientTokenService {
    
    // MARK: Fetcthing
    
    /**
     performs asynchronous call passed in by app developer, decodes the returned Base64 Primer client token string and adds it to shared state.
     */
    func fetchClientToken(_ completion: @escaping (Error?) -> Void) {
        
        PrimerDelegateProxy.clientTokenCallback({ (token, error) in
                        
            guard error == nil, let token = token else {
                completion(error)
                return
            }
            
            ClientTokenService.storeClientToken(token) { error in
                completion(error)
                return
            }
        })
    }
    
    func fetchClientToken() -> Promise<Void> {
        return Promise { seal in
            self.fetchClientToken { err in
                if let err = err {
                    seal.reject(err)
                } else {
                    seal.fulfill()
                }
            }
        }
    }
    
    func fetchClientTokenIfNeeded() -> Promise<Void> {
        return Promise { seal in
            do {
                if let decodedClientToken = ClientTokenService.decodedClientToken {
                    try decodedClientToken.validate()
                    seal.fulfill()
                } else {
                    firstly {
                        self.fetchClientToken()
                    }
                    .done {
                        seal.fulfill()
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                }
                
            } catch {
                switch error {
                case PrimerError.invalidClientToken:
                    firstly {
                        self.fetchClientToken()
                    }
                    .done { decodedClientToken in
                        seal.fulfill(decodedClientToken)
                    }
                    .catch { err in
                        seal.reject(err)
                    }
                default:
                    seal.reject(error)
                }
            }
            
        }
    }
}

#endif
