#if canImport(UIKit)

import Foundation

internal protocol VaultServiceProtocol {
    func fetchVaultedPaymentMethods() -> Promise<Void>
    func deleteVaultedPaymentMethod(with id: String) -> Promise<Void>
}

internal class VaultService: VaultServiceProtocol {
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func fetchVaultedPaymentMethods() -> Promise<Void> {
        return Promise { seal in
            let state: AppStateProtocol = AppState.current
            
            guard let clientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
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
                        seal.fulfill()
                        return
                    }
                    state.selectedPaymentMethodId = firstPaymentMethodToken
                }

                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func deleteVaultedPaymentMethod(with id: String) -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = ClientTokenService.decodedClientToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let api: PrimerAPIClientProtocol = DependencyContainer.resolve()
            api.deleteVaultedPaymentMethod(clientToken: clientToken, id: id) { (result) in
                switch result {
                case .failure(let err):
                    let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: nil)
                    ErrorHandler.handle(error: containerErr)
                    seal.reject(containerErr)
                    
                case .success:
                    seal.fulfill()
                }
            }
        }
    }
}

#endif
