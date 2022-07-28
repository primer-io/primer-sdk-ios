#if canImport(UIKit)

import UIKit

internal protocol PrimerAPIConfigurationServiceProtocol {
    init(requestDisplayMetadata: Bool?)
    func fetchConfiguration() -> Promise<Void>
    func fetchConfigurationIfNeeded() -> Promise<Void>
}

internal class PrimerAPIConfigurationService: PrimerAPIConfigurationServiceProtocol {
    
    private let requestDisplayMetadata: Bool?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }
    
    required init(requestDisplayMetadata: Bool?) {
        self.requestDisplayMetadata = requestDisplayMetadata
    }
    
    func fetchConfiguration() -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let requestParameters = PrimerAPIConfiguration.API.RequestParameters(
                skipPaymentMethodTypes: [],
                requestDisplayMetadata: true)
            
            let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
            api.fetchConfiguration(clientToken: clientToken, requestParameters: requestParameters) { (result) in
                switch result {
                case .failure(let err):
                    seal.reject(err)
                case .success(let config):
                    AppState.current.apiConfiguration = config
                    seal.fulfill()
                }
            }
        }
    }
    
    func fetchConfigurationIfNeeded() -> Promise<Void> {
        return Promise { seal in
            if AppState.current.apiConfiguration != nil {
                seal.fulfill()
            } else {
                firstly {
                    self.fetchConfiguration()
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
}

#endif
