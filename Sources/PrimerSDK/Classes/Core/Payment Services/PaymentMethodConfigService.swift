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
                state.paymentMethodConfig = PaymentMethodConfig(
                    coreUrl: config.coreUrl,
                    pciUrl: config.pciUrl,
                    paymentMethods: config.paymentMethods,
                    keys: nil)

                state.viewModels = []

                state.paymentMethodConfig?.paymentMethods?.forEach({ method in
                    guard let type = method.type else { return }
                    if !type.isEnabled { return }
                    state.viewModels.append(PaymentMethodViewModel(type: type))
                })
                
                // Ensure Apple Pay is always first if present.
                // This is because of Apple's guidelines.
                let viewModels = state.viewModels
                if (viewModels.contains(where: { model in model.type == .applePay})) {
                    var arr = viewModels.filter({ model in model.type != .applePay})
                    arr.insert(PaymentMethodViewModel(type: .applePay), at: 0)
                    state.viewModels = arr
                }
                
                completion(nil)
            }
        }
    }
    
}

#endif
