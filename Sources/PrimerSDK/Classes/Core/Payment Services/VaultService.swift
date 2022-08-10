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
        let state: AppStateProtocol = AppState.current
        
        guard let clientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(err)
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
        
        firstly {
            api.fetchVaultedPaymentMethods(clientToken: clientToken)
        }
        .done { paymentMethods in
            state.paymentMethods = paymentMethods.data

            if state.selectedPaymentMethodId == nil && !state.paymentMethods.isEmpty {
                guard let firstPaymentMethodToken = state.paymentMethods.first?.id else {
                    completion(nil)
                    return
                }
                state.selectedPaymentMethodId = firstPaymentMethodToken
            }

            completion(nil)
        }
        .catch { err in
            completion(err)
        }
    }

    func deleteVaultedPaymentMethod(with id: String, _ completion: @escaping (Error?) -> Void) {        
        guard let clientToken = ClientTokenService.decodedClientToken else {
            let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
            ErrorHandler.handle(error: err)
            completion(err)
            return
        }
        
        let api: PrimerAPIClientProtocol = DependencyContainer.resolve()

        api.deleteVaultedPaymentMethod(clientToken: clientToken, id: id) { (result) in
            switch result {
            case .failure(let err):
                let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                completion(containerErr)
            case .success:
                completion(nil)
            }
        }
    }
}

#endif
