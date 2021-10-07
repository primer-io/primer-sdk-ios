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
        
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.configFetchFailed)
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.fetchConfiguration(clientToken: clientToken) { (result) in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let config):
                state.paymentMethodConfig = config

                state.viewModels = []

                state.paymentMethodConfig?.paymentMethods?.forEach({ method in
                    if !method.type.isEnabled { return }
                    state.viewModels.append(PaymentMethodConfigViewModel(config: method))
                })
                
                // Ensure Apple Pay is always first if present.
                // This is because of Apple's guidelines.
                for (index, vm) in state.viewModels.enumerated() {
                    if vm.config.type == .applePay {
                        state.viewModels.swapAt(0, index)
                    }
                }
                
                completion(nil)
            }
        }
    }
    
}

#endif
