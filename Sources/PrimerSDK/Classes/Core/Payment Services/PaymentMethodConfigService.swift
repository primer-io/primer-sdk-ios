#if canImport(UIKit)

import UIKit

internal protocol PaymentMethodConfigServiceProtocol {
    func fetchConfig(_ completion: @escaping (Error?) -> Void)
    func fetchConfig() -> Promise<Void>
}

internal class PaymentMethodConfigService: PaymentMethodConfigServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func fetchConfig(_ completion: @escaping (Error?) -> Void) {
        guard let clientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
            ErrorHandler.handle(error: err)
            completion(err)
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.fetchConfiguration(clientToken: clientToken) { (result) in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let config):
                AppState.current.apiConfiguration = config
                completion(nil)
            }
        }
    }
    
    func fetchConfig() -> Promise<Void> {
        return Promise { seal in
            self.fetchConfig { err in
                if let err = err {
                    seal.reject(err)
                } else {
                    seal.fulfill()
                }
            }
        }
    }
    
    func fetchPrimerConfigurationIfNeeded() -> Promise<PrimerAPIConfiguration> {
        return Promise { seal in
            if let paymentMethodsConfig = PrimerAPIConfiguration.current {
                seal.fulfill(paymentMethodsConfig)
            } else {
                guard let decodedClientToken = ClientTokenService.decodedClientToken else {
                    let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"])
                    ErrorHandler.handle(error: err)
                    seal.reject(err)
                    return
                }
                
                do {
                    try decodedClientToken.validate()
                } catch {
                    seal.reject(error)
                    return
                }
                
                let apiClient: PrimerAPIClientProtocol = DependencyContainer.resolve()
                apiClient.fetchConfiguration(clientToken: decodedClientToken) { result in
                    switch result {
                    case .success(let paymentMethodsConfig):
                        seal.fulfill(paymentMethodsConfig)
                    case .failure(let err):
                        seal.reject(err)
                    }
                }
            }
        }
    }
    
}

#endif
