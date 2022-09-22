#if canImport(UIKit)

import Foundation

internal typealias JWTToken = String

internal protocol PrimerAPIConfigurationModuleProtocol {
    
    static var clientToken: JWTToken? { get }
    static var decodedJWTToken: DecodedJWTToken? { get }
    static var apiConfiguration: PrimerAPIConfiguration? { get }

    init(apiClient: PrimerAPIClientProtocol)
    func setupSession(
        forClientToken clientToken: String,
        requestDisplayMetadata: Bool,
        requestClientTokenValidation: Bool,
        requestVaultedPaymentMethods: Bool
    ) -> Promise<Void>
    func updateSession(withActions actionsRequest: ClientSessionUpdateRequest) -> Promise<Void>
    func storeRequiredActionClientToken(_ newClientToken: String) -> Promise<Void>
    static func resetClientSession()
}

internal class PrimerAPIConfigurationModule: PrimerAPIConfigurationModuleProtocol {
    
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
                PrimerAPIConfigurationModule.resetClientSession()
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
                PrimerAPIConfigurationModule.resetClientSession()
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
    
    private let apiClient: PrimerAPIClientProtocol
    
    required init(apiClient: PrimerAPIClientProtocol = PrimerAPIClient()) {
        self.apiClient = apiClient
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
                PrimerAPIConfigurationModule.validateClientToken(clientToken, requestRemoteClientTokenValidation: requestClientTokenValidation)
            }
            .then { () -> Promise<PrimerAPIConfiguration> in
                return PrimerAPIConfigurationModule.fetchConfigurationAndVaultedPaymentMethodsIfNeeded(
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

            self.apiClient.requestPrimerConfigurationWithActions(clientToken: decodedJWTToken, request: actionsRequest) { result in
                switch result {
                case .success(let configuration):
                    PrimerAPIConfigurationModule.apiConfiguration = configuration
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
                PrimerAPIConfigurationModule.validateClientToken(newClientToken, requestRemoteClientTokenValidation: true)
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
    
    static func resetClientSession() {
        AppState.current.clientToken = nil
        AppState.current.apiConfiguration = nil
    }

    // MARK: - HELPERS
    
    private static func validateClientToken(_ clientToken: String, requestRemoteClientTokenValidation: Bool) -> Promise<Void> {
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
                    PrimerAPIConfigurationModule.validateClientTokenRemotely(clientToken)
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
    
    private static func validateClientTokenInternally(_ tokenToValidate: JWTToken) throws -> JWTToken {
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
    
    private static func validateClientTokenRemotely(_ clientToken: JWTToken) -> Promise<Void> {
        return Promise { seal in
            let clientTokenRequest = Request.Body.ClientTokenValidation(clientToken: clientToken)
            let api: PrimerAPIClientProtocol = PrimerAPIClient()
            api.validateClientToken(request: clientTokenRequest) { result in
                switch result {
                case .success:
                    seal.fulfill()
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
    
    private static func fetchConfiguration(requestDisplayMetadata: Bool) -> Promise<PrimerAPIConfiguration> {
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

            let api: PrimerAPIClientProtocol = PrimerAPIClient()
            api.fetchConfiguration(clientToken: clientToken, requestParameters: requestParameters) { (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let config):
                    seal.fulfill(config)
                }
            }
        }
    }
    
    private static func fetchConfigurationAndVaultedPaymentMethodsIfNeeded(
        requestDisplayMetadata: Bool,
        requestVaultedPaymentMethods: Bool
    ) -> Promise<PrimerAPIConfiguration> {
        if requestVaultedPaymentMethods {
            let vaultService: VaultServiceProtocol = VaultService()
            let vaultedPaymentMethodsPromise = vaultService.fetchVaultedPaymentMethods()
            let fetchConfigurationPromise = PrimerAPIConfigurationModule.fetchConfiguration(requestDisplayMetadata: true)
            
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
            return PrimerAPIConfigurationModule.fetchConfiguration(requestDisplayMetadata: requestDisplayMetadata)
        }
        
    }
}

#endif
