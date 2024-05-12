//
//  StripeAchTokenizationComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

/**
 * Protocol defining the operations required to manage user details within a client session for Stripe ACH transactions.
 *
 * Methods:
 *  - `getClientSessionUserDetails`: Retrieves the user details (`fistname, lastname, email`) from the cached client session.
 *  - `patchClientSession`: Updates the client session with new user details based on a given request.
 */
protocol StripeAchUserDetailsProviding {
    func getClientSessionUserDetails() -> Promise<StripeAchUserDetails>
    func patchClientSession(actionsRequest: ClientSessionUpdateRequest) -> Promise<Void>
}

class StripeAchClientSessionService: StripeAchUserDetailsProviding {

    // MARK: - Properties
    private let apiClient: PrimerAPIClientProtocol
    private var clientSession: ClientSession.APIResponse?

    // MARK: - Settings
    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

    // MARK: - Init
    init() {
        self.apiClient = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
        self.clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
    }
}

/**
 * Retrieves the current user details stored in the client session.
 * This method accesses the cached client session to extract user details
 *
 * - Returns: A promise that resolves with `StripeAchUserDetails` containing the current user details.
 */
extension StripeAchClientSessionService {
    func getClientSessionUserDetails() -> Promise<StripeAchUserDetails> {
        let customerDetails = clientSession?.customer
        return Promise { seal in
            let userDetails = StripeAchUserDetails(firstName: customerDetails?.firstName ?? "",
                                                   lastName: customerDetails?.lastName ?? "",
                                                   emailAddress: customerDetails?.emailAddress ?? "")
            seal.fulfill(userDetails)
        }
        
    }
}

/**
 * Applies updates to the client session using the details provided in the `actionsRequest`.
 *
 * This method takes a `ClientSessionUpdateRequest` which includes specific actions to update user details
 * and applies these to the client session. The method handles both successful updates and errors.
 *
 * - Parameter actionsRequest: The `ClientSessionUpdateRequest` specifying how user details should be updated.
 * - Returns: A promise that resolves when the session has been successfully updated or rejects if an error occurs.
 */
extension StripeAchClientSessionService {
    func patchClientSession(actionsRequest: ClientSessionUpdateRequest) -> Promise<Void> {
        return Promise { seal in
            firstly {
                updateClientSession(with: actionsRequest)
            }
            .done { _ in
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
            
        }
    }
}

// MARK: - Stripe ACH client session API calls
private extension StripeAchClientSessionService {
    private func updateClientSession(with actionsRequest: ClientSessionUpdateRequest) -> Promise<Void> {
        return Promise { seal in
            // Verify if we have a valid decoded JWT token
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                seal.reject(StripeAchHelpers.getInvalidTokenError())
                return
            }
            
            apiClient.requestPrimerConfigurationWithActions(clientToken: decodedJWTToken,
                                                            request: actionsRequest) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let configuration):
                    PrimerAPIConfigurationModule.apiConfiguration?.clientSession = configuration.clientSession
                    self.clientSession = configuration.clientSession
                    seal.fulfill()
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}
