#if canImport(UIKit)

import Foundation

internal typealias JWTToken = String

internal protocol PrimerAPIConfigurationModuleProtocol {
    
    static var apiClient: PrimerAPIClientProtocol? { get set }
    static var clientToken: JWTToken? { get }
    static var decodedJWTToken: DecodedJWTToken? { get }
    static var apiConfiguration: PrimerAPIConfiguration? { get }
    static func resetSession()

    func setupSession(
        forClientToken clientToken: String,
        requestDisplayMetadata: Bool,
        requestClientTokenValidation: Bool,
        requestVaultedPaymentMethods: Bool
    ) -> Promise<Void>
    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) -> Promise<Void>
    func storeRequiredActionClientToken(_ newClientToken: String) -> Promise<Void>
}

internal class PrimerAPIConfigurationModule: PrimerAPIConfigurationModuleProtocol {
    
    static var apiClient: PrimerAPIClientProtocol?
    
    static var clientToken: JWTToken? {
        get {
            if PrimerAPIConfigurationModule.decodedJWTToken == nil {
                AppState.current.clientToken = nil
                return nil
            }
            
            return AppState.current.clientToken
        }
        set {
            if newValue?.decodedJWTToken != nil {
                AppState.current.clientToken = newValue
            } else {
                PrimerAPIConfigurationModule.resetSession()
            }
        }
    }
    
    static var apiConfiguration: PrimerAPIConfiguration? {
        get {
            return AppState.current.apiConfiguration
        }
        set {
            if PrimerAPIConfigurationModule.clientToken != nil {
                AppState.current.apiConfiguration = newValue
            } else {
                PrimerAPIConfigurationModule.resetSession()
            }
        }
    }
    
    static var decodedJWTToken: DecodedJWTToken? {
        guard let decodedJWTToken = AppState.current.clientToken?.decodedJWTToken,
              let expDate = decodedJWTToken.expDate,
              expDate > Date() else {
            return nil
        }
        
        return decodedJWTToken
    }
    
    static func resetSession() {
        AppState.current.clientToken = nil
        AppState.current.apiConfiguration = nil
    }
        
    func setupSession(
        forClientToken clientToken: String,
        requestDisplayMetadata: Bool = true,
        requestClientTokenValidation: Bool = true,
        requestVaultedPaymentMethods: Bool = false
    ) -> Promise<Void> {
        return Promise { seal in
            if let currentClientToken = PrimerAPIConfigurationModule.clientToken,
               currentClientToken == clientToken,
               PrimerAPIConfigurationModule.apiConfiguration != nil {
                seal.fulfill()
                return
            }
            
            firstly {
                self.validateClientToken(clientToken, requestRemoteClientTokenValidation: requestClientTokenValidation)
            }
            .then { () -> Promise<PrimerAPIConfiguration> in
                return self.fetchConfigurationAndVaultedPaymentMethodsIfNeeded(
                    requestDisplayMetadata: requestDisplayMetadata,
                    requestVaultedPaymentMethods: requestVaultedPaymentMethods)
            }
            .done { apiConfiguration in
                PrimerAPIConfigurationModule.clientToken = clientToken
                PrimerAPIConfigurationModule.apiConfiguration = apiConfiguration
                seal.fulfill()
            }
            .catch { err in
                PrimerAPIConfigurationModule.clientToken = nil
                PrimerAPIConfigurationModule.apiConfiguration = nil
                seal.reject(err)
            }
        }
    }
    
    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) -> Promise<Void> {
        return Promise { seal in
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let apiClient = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
            apiClient.requestPrimerConfigurationWithActions(clientToken: decodedJWTToken, request: actionsRequest) { result in
                switch result {
                case .success(let configuration):
                    PrimerAPIConfigurationModule.apiConfiguration?.clientSession = configuration.clientSession
                    seal.fulfill()
                case .failure(let err):
                    seal.reject(err)
                }
            }
        }
    }
    
    func storeRequiredActionClientToken(_ newClientToken: String) -> Promise<Void> {
        return Promise { seal in
            firstly {
                self.validateClientToken(newClientToken, requestRemoteClientTokenValidation: true)
            }
            .done {
                PrimerAPIConfigurationModule.clientToken = newClientToken
                seal.fulfill()
            }
            .catch { err in
                PrimerAPIConfigurationModule.clientToken = nil
                PrimerAPIConfigurationModule.apiConfiguration = nil
                seal.reject(err)
            }
        }
    }

    // MARK: - HELPERS
    
    private func validateClientToken(_ clientToken: String, requestRemoteClientTokenValidation: Bool) -> Promise<Void> {
        return Promise { seal in
            do {
                _ = try validateClientTokenInternally(clientToken)
            } catch {
                seal.reject(error)
                return
            }
            
            let isAutoPaymentHandling = PrimerSettings.current.paymentHandling == .auto
            
            if !requestRemoteClientTokenValidation || isAutoPaymentHandling {
                AppState.current.clientToken = clientToken
                seal.fulfill()
                
            } else {
                firstly {
                    self.validateClientTokenRemotely(clientToken)
                }
                .done {
                    seal.fulfill()
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        }
    }
    
    private func validateClientTokenInternally(_ tokenToValidate: JWTToken) throws -> JWTToken {
        guard var currentDecodedToken = tokenToValidate.decodedJWTToken,
              let expDate = currentDecodedToken.expDate,
              expDate > Date() else {
            let error = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: error)
            throw error
        }
                        
        let previousDecodedToken = PrimerAPIConfigurationModule.decodedJWTToken
        
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
    
    private func validateClientTokenRemotely(_ clientToken: JWTToken) -> Promise<Void> {
        return Promise { seal in
            let clientTokenRequest = Request.Body.ClientTokenValidation(clientToken: clientToken)
            
            let apiClient = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
            apiClient.validateClientToken(request: clientTokenRequest) { result in
                switch result {
                case .success:
                    seal.fulfill()
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
    
    private func fetchConfiguration(requestDisplayMetadata: Bool) -> Promise<PrimerAPIConfiguration> {
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let requestParameters = Request.URLParameters.Configuration(
                skipPaymentMethodTypes: [],
                requestDisplayMetadata: requestDisplayMetadata)

            let apiClient = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
            apiClient.fetchConfiguration(clientToken: clientToken, requestParameters: requestParameters) { (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let config):
                    seal.fulfill(config)
                }
            }
        }
    }
    
    private func fetchConfigurationAndVaultedPaymentMethodsIfNeeded(
        requestDisplayMetadata: Bool,
        requestVaultedPaymentMethods: Bool
    ) -> Promise<PrimerAPIConfiguration> {
        if requestVaultedPaymentMethods {
            let vaultService: VaultServiceProtocol = VaultService()
            let vaultedPaymentMethodsPromise = vaultService.fetchVaultedPaymentMethods()
            let fetchConfigurationPromise = self.fetchConfiguration(requestDisplayMetadata: true)
            
            return Promise { seal in
                firstly {
                    when(fulfilled: fetchConfigurationPromise, vaultedPaymentMethodsPromise)
                }
                .done { apiConfiguration, _ in
                    seal.fulfill(apiConfiguration)
                }
                .catch { err in
                    seal.reject(err)
                }
            }
        } else {
            return self.fetchConfiguration(requestDisplayMetadata: requestDisplayMetadata)
        }
        
    }
}

#endif
