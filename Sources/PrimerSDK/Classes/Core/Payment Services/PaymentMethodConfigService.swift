#if canImport(UIKit)

import UIKit

internal protocol PaymentMethodConfigServiceProtocol {
    func fetchConfig(_ completion: @escaping (Error?) -> Void)
}

internal class PaymentMethodConfigService: PaymentMethodConfigServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func fetchConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            return completion(PrimerError.configFetchFailed)
        }
        
        let api: PrimerAPIClientProtocol = PrimerAPIClient()
        api.fetchConfiguration(clientToken: decodedClientToken) { (result) in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let config):
                state.paymentMethodConfig = config
                completion(nil)
            }
        }
    }
    
    private func fetchConfig() -> Promise<Void> {
        return Promise { seal in
            self.fetchConfig { err in
                if let err = err {
                    seal.reject(err)
                } else {
                    seal.fulfill(())
                }
            }
        }
    }
    
    func fetchPrimerConfigurationIfNeeded(enforce: Bool) -> Promise<PrimerConfiguration> {
        return Promise { seal in
            let clientTokenService: ClientTokenService = DependencyContainer.resolve()
            
            firstly {
                clientTokenService.fetchClientTokenIfNeeded(enforce: false)
            }
            .then { () -> Promise<Void> in
                let state: AppStateProtocol = DependencyContainer.resolve()
                
                if !enforce, state.paymentMethodConfig != nil {
                    return Promise()
                } else {
                    return self.fetchConfig()
                }
            }
            .done {
                let state: AppStateProtocol = DependencyContainer.resolve()
                
                guard let config = state.paymentMethodConfig else {
                    throw PrimerError.configFetchFailed
                }
                
                seal.fulfill(config)
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }
    
}

#endif
