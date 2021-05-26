#if canImport(UIKit)

import UIKit

protocol PaymentMethodConfigServiceProtocol {
    func fetchConfig(_ completion: @escaping (Error?) -> Void)
}

class PaymentMethodConfigService: PaymentMethodConfigServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func fetchConfig(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.configFetchFailed)
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.fetchConfiguration(clientToken: clientToken) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let config):
                state.paymentMethodConfig = config

                state.viewModels = []

                config.paymentMethods?.forEach({ method in
                    guard let type = method.type else { return }
                    if type == .googlePay { return }
//                    if type == .goCardlessMandate { return }
//                    if type == .applePay { return }
//                    if type == .klarna { return }
                    state.viewModels.append(PaymentMethodViewModel(type: type))
                })

                // ensure Apple Pay is always first if present.
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
