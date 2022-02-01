#if canImport(UIKit)

import Foundation

internal protocol ClientTokenServiceProtocol {
    static func storeClientToken(_ clientToken: String) throws
    func fetchClientToken(_ completion: @escaping (Error?) -> Void)
    func fetchClientToken() -> Promise<Void>
    func fetchClientTokenIfNeeded() -> Promise<Void>
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
        guard var currentDecodedToken = clientToken.jwtTokenPayload,
              let expDate = currentDecodedToken.expDate
        else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        if expDate < Date() {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            throw err
        }
        
        let state: AppStateProtocol = DependencyContainer.resolve()
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
        
        var segments: [String] = clientToken.split(separator: ".").compactMap({ String($0) })
        
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
        
        let modifiedClientToken = segments.joined(separator: ".").base64RFC4648Format
        
        state.clientToken = modifiedClientToken
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
            let err = PrimerError.missingPrimerDelegate(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
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
