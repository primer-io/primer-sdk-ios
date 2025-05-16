import Foundation

internal protocol VaultServiceProtocol {
    func fetchVaultedPaymentMethods() -> Promise<Void>
    func fetchVaultedPaymentMethods() async throws
    func deleteVaultedPaymentMethod(with id: String) -> Promise<Void>
    func deleteVaultedPaymentMethod(with id: String) async throws
}

final class VaultService: VaultServiceProtocol {

    let apiClient: PrimerAPIClientVaultProtocol

    init(apiClient: PrimerAPIClientVaultProtocol) {
        self.apiClient = apiClient
    }

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
                state.paymentMethods = paymentMethods.data
                state.selectedPaymentMethodId = paymentMethods.data.first?.id
                seal.fulfill()
            }
            .catch { err in
                seal.reject(err)
            }
        }
    }

    func fetchVaultedPaymentMethods() async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchVaultedPaymentMethods()
                .done {
                    continuation.resume()
                }
                .catch { err in
                    continuation.resume(throwing: err)
                }
        }
    }

    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken) -> Promise<Response.Body.VaultedPaymentMethods> {
        return Promise { seal in
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

    func fetchVaultedPaymentMethods(clientToken: DecodedJWTToken) async throws -> Response.Body.VaultedPaymentMethods {
        return try await withCheckedThrowingContinuation { continuation in
            self.fetchVaultedPaymentMethods(clientToken: clientToken)
                .done { response in
                    continuation.resume(returning: response)
                }
                .catch { err in
                    continuation.resume(throwing: err)
                }
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

            apiClient.deleteVaultedPaymentMethod(clientToken: clientToken, id: id) { result in
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

    func deleteVaultedPaymentMethod(with id: String) async throws {
        return try await withCheckedThrowingContinuation { continuation in
            self.deleteVaultedPaymentMethod(with: id)
                .done {
                    continuation.resume()
                }
                .catch { err in
                    continuation.resume(throwing: err)
                }
        }
    }
}
