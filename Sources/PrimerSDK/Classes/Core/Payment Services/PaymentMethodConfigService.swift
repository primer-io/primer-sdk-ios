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
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerInternalError.invalidClientToken
            _ = ErrorHandler.shared.handle(error: err)
            completion(err)
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.fetchConfiguration(clientToken: clientToken) { (result) in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let config):
                state.primerConfiguration = config
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
    
}

#endif
