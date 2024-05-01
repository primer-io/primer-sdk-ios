//
//  StripeAchTokenizationComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

/**
 * Protocol that extends tokenization and client session management functionalities specific to Stripe ACH transactions.
 *
 * This protocol inherits from `StripeTokenizationManagerProtocol` and `StripeAchClientSessionProtocol`, encapsulating
 * both tokenization of payment methods and management of user details within a client session. It also requires an
 * implementation of a validation method to ensure data integrity before proceeding with tokenization or session updates.
 *
 */
protocol StripeAchTokenizationComponentProtocol: StripeTokenizationManagerProtocol, StripeAchClientSessionProtocol {
    func validate() throws
}

/**
 * Protocol defining the operations required to manage user details within a client session for Stripe ACH transactions.
 *
 * Methods:
 *  - `getClientSessionUserDetails`: Retrieves the user details (`fistname, lastname, email`) from the cached client session.
 *  - `patchClientSession`: Updates the client session with new user details based on a given request.
 */
protocol StripeAchClientSessionProtocol {
    func getClientSessionUserDetails() -> Promise<StripeAchUserDetails>
    func patchClientSession(actionsRequest: ClientSessionUpdateRequest) -> Promise<Void>
}

class StripeAchTokenizationComponent: StripeTokenizationManager, StripeAchTokenizationComponentProtocol {
    // MARK: - Properties
    private let paymentMethod: PrimerPaymentMethod
    private let apiClient: PrimerAPIClientProtocol
    private var clientSession: ClientSession.APIResponse?
    
    // MARK: - Settings
    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
    
    // MARK: - Init
    init(paymentMethod: PrimerPaymentMethod) {
        self.paymentMethod = paymentMethod
        self.apiClient = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
        self.clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
        super.init()
    }
}

// MARK: - Validate
extension StripeAchTokenizationComponent {
    func validate() throws {
        guard
            let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
            decodedJWTToken.isValid,
            decodedJWTToken.pciUrl != nil
        else {
            throw StripeHelpers.getInvalidTokenError()
        }
        
        guard paymentMethod.id != nil else {
            throw StripeHelpers.getInvalidValueError(
                key: "configuration.id",
                value: paymentMethod.id
            )
        }
        
        if AppState.current.amount == nil {
            throw StripeHelpers.getInvalidSettingError(name: "amount")
        }
        
        if AppState.current.currency == nil {
            throw StripeHelpers.getInvalidSettingError(name: "currency")
        }
        
        let lineItems = clientSession?.order?.lineItems ?? []
        if lineItems.isEmpty {
            throw StripeHelpers.getInvalidValueError(key: "lineItems")
        }
        
        if !(lineItems.filter({ $0.amount == nil })).isEmpty {
            throw StripeHelpers.getInvalidValueError(key: "settings.orderItems")
        }
    }
}

/**
 * Retrieves the current user details stored in the client session.
 * This method accesses the cached client session to extract user details
 *
 * - Returns: A promise that resolves with `StripeAchUserDetails` containing the current user details.
 */
extension StripeAchTokenizationComponent {
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
extension StripeAchTokenizationComponent {
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
private extension StripeAchTokenizationComponent {
    private func updateClientSession(with actionsRequest: ClientSessionUpdateRequest) -> Promise<Void> {
        return Promise { seal in
            // Verify if we have a valid decoded JWT token
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                seal.reject(StripeHelpers.getInvalidTokenError())
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
