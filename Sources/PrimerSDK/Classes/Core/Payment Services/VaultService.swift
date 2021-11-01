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

    // swiftlint:disable cyclomatic_complexity
    func loadVaultedPaymentMethods(_ completion: @escaping (Error?) -> Void) {
        let state: AppStateProtocol = DependencyContainer.resolve()
        
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            return completion(PrimerError.vaultFetchFailed)
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        firstly {
            api.vaultFetchPaymentMethods(clientToken: decodedClientToken)
        }
        .done { paymentMethods in
            state.paymentMethods = paymentMethods.data

            let paymentMethods = state.paymentMethods

            if (state.selectedPaymentMethodId ?? "").isEmpty == true && (paymentMethods ?? []).isEmpty == false {
                guard let id = paymentMethods!.first?.token else { return }
                state.selectedPaymentMethodId = id
            }

            completion(nil)
        }
        .catch { err in
            completion(PrimerError.vaultFetchFailed)
        }
    }

    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void) {
        guard let decodedClientToken = ClientTokenService.decodedClientToken else {
            return completion(PrimerError.vaultDeleteFailed)
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.vaultDeletePaymentMethod(clientToken: decodedClientToken, id: id) { (result) in
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
