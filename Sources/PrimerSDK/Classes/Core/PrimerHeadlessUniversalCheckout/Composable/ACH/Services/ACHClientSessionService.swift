//
//  ACHClientSessionService.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/**
 * Protocol defining the operations required to manage user details within a client session for ACH transactions.
 *
 * Methods:
 *  - `getClientSessionUserDetails`: Retrieves the user details (`fistname, lastname, email`) from the cached client session.
 *  - `patchClientSession`: Updates the client session with new user details based on a given request.
 */
protocol ACHUserDetailsProviding {
    func getClientSessionUserDetails() -> ACHUserDetails
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
 * - Returns: `ACHUserDetails` containing the current user details.
 */
extension ACHClientSessionService {
    func getClientSessionUserDetails() -> ACHUserDetails {
        let customerDetails = PrimerAPIConfigurationModule.apiConfiguration?.clientSession?.customer
        return ACHUserDetails(
            firstName: customerDetails?.firstName ?? "",
            lastName: customerDetails?.lastName ?? "",
            emailAddress: customerDetails?.emailAddress ?? ""
        )
    }
}

/**
 * Applies updates to the client session using the details provided in the `actionsRequest`.
 *
 * This method takes a `ClientSessionUpdateRequest` which includes specific actions to update user details
 * and applies these to the client session. The method handles both successful updates and errors.
 *
 * - Parameter actionsRequest: The `ClientSessionUpdateRequest` specifying how user details should be updated.
 * - Throws: An error if the session update fails.
 */
extension ACHClientSessionService {
    func patchClientSession(with actionsRequest: ClientSessionUpdateRequest) async throws {
        let apiConfigurationModule = PrimerAPIConfigurationModule()
        try await apiConfigurationModule.updateSession(withActions: actionsRequest)
    }

    func prepareClientSessionActionsRequestBody(paymentMethodType: String) -> ClientSessionUpdateRequest {
        let params: [String: Any] = ["paymentMethodType": paymentMethodType]
        let actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]
        return ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))
    }
}
