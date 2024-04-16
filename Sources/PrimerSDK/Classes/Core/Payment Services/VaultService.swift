import Foundation

internal protocol VaultServiceProtocol {
    static var apiClient: PrimerAPIClientProtocol? { get set }
    func fetchVaultedPaymentMethods() -> Promise<Void>
    func deleteVaultedPaymentMethod(with id: String) -> Promise<Void>
}

internal class VaultService: VaultServiceProtocol {

    static var apiClient: PrimerAPIClientProtocol?

    func fetchVaultedPaymentMethods() -> Promise<Void> {
        return Promise { seal in
            let state: AppStateProtocol = AppState.current

            guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            firstly {
                fetchVaultedPaymentMethods(clientToken: clientToken)
            }
            .done { paymentMethods in
                AppState.current.selectedPaymentMethodId = paymentMethods.data.first?.id
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

    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken) -> Promise<Response.Body.VaultedPaymentMethods> {
        return Promise { seal in
            let apiClient: PrimerAPIClientProtocol = VaultService.apiClient ?? PrimerAPIClient()
            apiClient.fetchVaultedPaymentMethods(clientToken: clientToken, completion: { result in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                case .failure(let err):
                    seal.reject(err)
                }
            })
        }
    }

    func deleteVaultedPaymentMethod(with id: String) -> Promise<Void> {
        return Promise { seal in
            guard let clientToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let err = PrimerError.invalidClientToken(userInfo: .errorUserInfoDictionary(),
                                                         diagnosticsId: UUID().uuidString)
                ErrorHandler.handle(error: err)
                seal.reject(err)
                return
            }

            let apiClient: PrimerAPIClientProtocol = VaultService.apiClient ?? PrimerAPIClient()

            apiClient.deleteVaultedPaymentMethod(clientToken: clientToken, id: id) { (result) in
                switch result {
                case .failure(let err):
                    let containerErr = PrimerError.failedToCreateSession(error: err, userInfo: .errorUserInfoDictionary(),
                                                                         diagnosticsId: UUID().uuidString)
                    ErrorHandler.handle(error: containerErr)
                    seal.reject(containerErr)

                case .success:
                    seal.fulfill()
                }
            }
        }
    }
}
