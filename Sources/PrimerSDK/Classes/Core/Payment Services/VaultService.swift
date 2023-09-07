

import Foundation

internal protocol VaultServiceProtocol {
    static var apiClient: PrimerAPIClientProtocol? { get set }
    func fetchVaultedPaymentMethods() -> Promise<Void>
    func deleteVaultedPaymentMethod(with id: String) -> Promise<Void>
}

internal class VaultService: VaultServiceProtocol {
    
    static var apiClient: PrimerAPIClientProtocol?
    
    deinit {
        log(logLevel: .debug, message: "🧨 deinit: \(self) \(Unmanaged.passUnretained(self).toOpaque())")
    }

    func fetchVaultedPaymentMethods() -> Promise<Void> {
        return Promise { seal in
            let state: AppStateProtocol = AppState.current
            
            guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let apiClient: PrimerAPIClientProtocol = VaultService.apiClient ?? PrimerAPIClient()
            
            firstly {
                apiClient.fetchVaultedPaymentMethods(clientToken: clientToken)
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
            guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }
            
            let apiClient: PrimerAPIClientProtocol = VaultService.apiClient ?? PrimerAPIClient()
            
            apiClient.deleteVaultedPaymentMethod(clientToken: clientToken, id: id) { (result) in
                switch result {
                case .failure(let err):
                    let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: ["file": #file, "class": "\(Self.self)", "function": #function, "line": "\(#line)"], diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: containerErr)
                    seal.reject(containerErr)
                    
                case .success:
                    seal.fulfill()
                }
            }
        }
    }
}


