#if canImport(UIKit)

import UIKit

protocol PaymentMethodConfigServiceProtocol {
    func fetchConfig(_ completion: @escaping (Error?) -> Void)
}

class PaymentMethodConfigService: PaymentMethodConfigServiceProtocol {

    @Dependency private(set) var api: PrimerAPIClientProtocol
    @Dependency private(set) var state: AppStateProtocol
    @Dependency private(set) var settings: PrimerSettingsProtocol

    func fetchConfig(_ completion: @escaping (Error?) -> Void) {
        guard let clientToken = state.decodedClientToken else {
            return completion(PrimerError.configFetchFailed)
        }

        api.fetchConfiguration(clientToken: clientToken) { [weak self] (result) in
            switch result {
            case .failure(let error):
                completion(error)
            case .success(let config):
                self?.state.paymentMethodConfig = config

                self?.state.viewModels = []

                config.paymentMethods?.forEach({ method in
                    guard let type = method.type else { return }
                    if type == .googlePay { return }
                    self?.state.viewModels.append(PaymentMethodViewModel(type: type))
                })

                // ensure Apple Pay is always first if present.
                guard let viewModels = self?.state.viewModels else { return }
                if (viewModels.contains(where: { model in model.type == .applePay})) {
                    var arr = viewModels.filter({ model in model.type != .applePay})

                    if self?.settings.applePayEnabled == true {
                        arr.insert(PaymentMethodViewModel(type: .applePay), at: 0)
                    }

                    self?.state.viewModels = arr
                }

                completion(nil)
            }
        }
    }
    
}

#endif
