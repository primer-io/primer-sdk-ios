#if canImport(UIKit)

import Foundation

/// Helper typealias to identify the JWT Token
internal typealias RawJWTToken = String

internal protocol ClientTokenServiceProtocol {
    static var decodedClientToken: DecodedClientToken? { get }
    static func storeClientToken(_ clientToken: String, isAPIValidationEnabled: Bool) -> Promise<Void>
    static func resetClientToken()
}

internal class ClientTokenService: ClientTokenServiceProtocol {
        
    /// The client token from the DepedencyContainer
    static var decodedClientToken: DecodedClientToken? {
        guard let clientToken = AppState.current.clientToken else { return nil }
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
    
    // MARK: Store
    
    static func storeClientToken(_ clientToken: String, isAPIValidationEnabled: Bool) -> Promise<Void> {
        return Promise { seal in
            do {
                _ = try validateInternally(clientToken)
            } catch {
                seal.reject(error)
                return
            }
            
            let isManualPaymentHandling = PrimerSettings.current.paymentHandling == .manual
            
            if !isAPIValidationEnabled || !isManualPaymentHandling {
                AppState.current.clientToken = clientToken
                seal.fulfill()
                
            } else {
                validateToken(clientToken) { error in
                    if let error = error {
                        AppState.current.clientToken = nil
                        seal.reject(error)
                    } else {
                        AppState.current.clientToken = clientToken
                        seal.fulfill()
                    }
                }
            }
        }
    }
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
}

extension ClientTokenService {
    
    // MARK: API Validation
    
    private static func validateToken(_ clientToken: RawJWTToken, completion: @escaping (Error?) -> Void) {
        let clientTokenRequest = Request.Body.ClientTokenValidation(clientToken: clientToken)
        let api: PrimerAPIClientProtocol = PrimerAPIClient()
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
            let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
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
    
    
}

extension ClientTokenService {
    
    // MARK: Reset
    
    static func resetClientToken() {
        AppState.current.clientToken = nil
    }
}

#endif
