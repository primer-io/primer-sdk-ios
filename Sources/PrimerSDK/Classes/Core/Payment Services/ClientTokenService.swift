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
        let previousJwtTokenPayload = ClientTokenService.decodedClientToken

        if jwtTokenPayload.analyticsUrl == nil {
            jwtTokenPayload.analyticsUrl = previousJwtTokenPayload?.analyticsUrl
        }
        
        if jwtTokenPayload.configurationUrl == nil {
            jwtTokenPayload.configurationUrl = previousJwtTokenPayload?.configurationUrl
        }
        
        if jwtTokenPayload.coreUrl == nil {
            jwtTokenPayload.coreUrl = previousJwtTokenPayload?.coreUrl
        }
        
        if jwtTokenPayload.env == nil {
            jwtTokenPayload.env = previousJwtTokenPayload?.env
        }
        
        if jwtTokenPayload.pciUrl == nil {
            jwtTokenPayload.pciUrl = previousJwtTokenPayload?.pciUrl
        }
        
        var segments: [String] = clientToken.split(separator: ".").compactMap({ String($0) })
        
        var tmpSecondSegment: String?
        if let data = try? JSONEncoder().encode(jwtTokenPayload),
           let dataStr = String(data: data.base64EncodedData(), encoding: .utf8) {
            tmpSecondSegment = dataStr
        }
        
        if segments.count > 1, let tmpSecondSegment = tmpSecondSegment {
            segments[1] = tmpSecondSegment
        } else if segments.count == 1, let tmpSecondSegment = tmpSecondSegment {
            segments.append(tmpSecondSegment)
        }
        
        let modifiedClientToken = segments.joined(separator: ".")
        
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
