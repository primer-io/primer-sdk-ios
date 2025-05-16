//
//  ACHClientSessionService.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

/**
 * Protocol defining the operations required to manage user details within a client session for ACH transactions.
 *
 * Methods:
 *  - `getClientSessionUserDetails`: Retrieves the user details (`fistname, lastname, email`) from the cached client session.
 *  - `patchClientSession`: Updates the client session with new user details based on a given request.
 */
protocol ACHUserDetailsProviding {
    func getClientSessionUserDetails() -> Promise<ACHUserDetails>
    func getClientSessionUserDetails() async throws -> ACHUserDetails

    func patchClientSession(with actionsRequest: ClientSessionUpdateRequest) -> Promise<Void>
    func patchClientSession(with actionsRequest: ClientSessionUpdateRequest) async throws
}

final class ACHClientSessionService: ACHUserDetailsProviding {

    // MARK: - Properties

    let apiClient: PrimerAPIClientProtocol
    let settings: PrimerSettingsProtocol

    // MARK: - Init

    init(apiClient: PrimerAPIClientProtocol = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient(),
         settings: PrimerSettingsProtocol = DependencyContainer.resolve()) {
        self.apiClient = apiClient
        self.settings = settings
    }
}

/**
 * Retrieves the current user details stored in the client session.
 * This method accesses the cached client session to extract user details
 *
 * - Returns: A promise that resolves with `ACHUserDetails` containing the current user details.
 */
extension ACHClientSessionService {
    func getClientSessionUserDetails() -> Promise<ACHUserDetails> {
        let customerDetails = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.customer
        return Promise { seal in
            let userDetails = ACHUserDetails(firstName: customerDetails?.firstName ?? "",
                                             lastName: customerDetails?.lastName ?? "",
                                             emailAddress: customerDetails?.emailAddress ?? "")
            seal.fulfill(userDetails)
        }
    }

    func getClientSessionUserDetails() async throws -> ACHUserDetails {
        return try await getClientSessionUserDetails().async()
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
extension ACHClientSessionService {
    func patchClientSession(with actionsRequest: ClientSessionUpdateRequest) -> Promise<Void> {
        return Promise { seal in
            firstly {
                let apiConfigurationModule = PrimerAPIConfigurationModule()
                return apiConfigurationModule.updateSession(withActions: actionsRequest)
            }
            .done { _ in
                seal.fulfill()
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }

    func patchClientSession(with actionsRequest: ClientSessionUpdateRequest) async throws {
        return try await patchClientSession(with: actionsRequest).async()
    }

    func prepareClientSessionActionsRequestBody(paymentMethodType: String) -> ClientSessionUpdateRequest {
        let params: [String: Any] = ["paymentMethodType": paymentMethodType]
        let actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]
        return ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))
    }
}
