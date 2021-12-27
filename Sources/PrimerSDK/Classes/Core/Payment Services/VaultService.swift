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
            let err = PrimerInternalError.invalidClientToken
            _ = ErrorHandler.shared.handle(error: err)
            completion(err)
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        firstly {
            api.vaultFetchPaymentMethods(clientToken: clientToken)
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
            completion(err)
        }
    }

    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void) {        
        guard let clientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerInternalError.invalidClientToken
            _ = ErrorHandler.shared.handle(error: err)
            completion(err)
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.vaultDeletePaymentMethod(clientToken: clientToken, id: id) { (result) in
            switch result {
            case .failure(let err):
                let containerErr = PaymentError.failedToCreateSession(error: err)
                _ = ErrorHandler.shared.handle(error: err)
                completion(containerErr)
            case .success:
                completion(nil)
            }
        }
    }
}

#endif
