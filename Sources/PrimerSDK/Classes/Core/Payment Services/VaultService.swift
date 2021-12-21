#if canImport(UIKit)

import Foundation

internal protocol VaultServiceProtocol {
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void)
    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void)
}

internal class VaultService: VaultServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let clientToken = ClientTokenService.decodedClientToken else {
            return completion(PrimerError.vaultFetchFailed)
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        firstly {
            api.fetchVaultedPaymentMethods(clientToken: clientToken)
        }
        .done { paymentMethods in
            state.paymentMethods = paymentMethods.data

            let paymentMethods = state.paymentMethods

            if state.selectedPaymentMethodToken == nil && !paymentMethods.isEmpty {
                guard let firstPaymentMethodToken = paymentMethods.first?.token else { return }
                state.selectedPaymentMethodToken = firstPaymentMethodToken
            }

            completion(nil)
        }
        .catch { err in
            completion(PrimerError.vaultFetchFailed)
        }
    }

    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void) {        
        guard let clientToken = ClientTokenService.decodedClientToken else {
            return completion(PrimerError.vaultDeleteFailed)
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.deleteVaultedPaymentMethod(clientToken: clientToken, id: id) { (result) in
            switch result {
            case .failure:
                completion(PrimerError.vaultDeleteFailed)
            case .success:
                completion(nil)
            }
        }
    }
}

#endif
