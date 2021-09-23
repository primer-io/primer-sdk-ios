#if canImport(UIKit)

import UIKit

internal protocol PaymentMethodConfigServiceProtocol {
    func fetchConfig(_ completion: @escaping (Error?) -> Void)
    func loadConfigIfNeeded() -> Promise<PaymentMethodConfig>
    func loadConfigIfNeeded(completionHandler: @escaping (PaymentMethodConfig?, Error?) -> Void)
}

extension PaymentMethodConfigServiceProtocol {
    func loadConfigIfNeeded() -> Promise<PaymentMethodConfig> {
        return Promise { seal in
            self.loadConfigIfNeeded { paymentMethodConfig, err in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethodConfig = paymentMethodConfig {
                    seal.fulfill(paymentMethodConfig)
                } else {
                    fatalError()
                }
            }
        }
    }
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
                    paymentMethods: config.paymentMethods
                )

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
    
    func loadConfigIfNeeded() -> Promise<PaymentMethodConfig> {
        return Promise { seal in
            self.loadConfigIfNeeded { paymentMethodConfig, err in
                if let err = err {
                    seal.reject(err)
                } else if let paymentMethodConfig = paymentMethodConfig {
                    seal.fulfill(paymentMethodConfig)
                } else {
                    fatalError()
                }
            }
        }
    }
    
    func loadConfigIfNeeded(completionHandler: @escaping (PaymentMethodConfig?, Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        if let config = state.paymentMethodConfig {
            completionHandler(config, nil)
            return
        }
        
        guard let clientToken = state.decodedClientToken else {
            return completionHandler(nil, PrimerError.configFetchFailed)
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        api.fetchConfiguration(clientToken: clientToken) { (result) in
            switch result {
            case .failure(let error):
                completionHandler(nil, error)
            case .success(let config):
                state.paymentMethodConfig = PaymentMethodConfig(
                    coreUrl: config.coreUrl,
                    pciUrl: config.pciUrl,
                    paymentMethods: config.paymentMethods
                )

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
                
                completionHandler(state.paymentMethodConfig, nil)
            }
        }
    }
    
}

#endif
