//
//  StripeAchTokenizationComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

protocol StripeAchTokenizationComponentProtocol: StripeTokenizationManagerProtocol, StripeAchClientSessionProtocol {
    /// - Validates the necessary conditions for proceeding with a payment operation.
    func validate() throws
}

protocol StripeAchClientSessionProtocol {
    /// - Get the user details (`fistname, lastname, email`) from the cached client session
    func getClientSessionUserDetails() -> Promise<StripeAchUserDetails>
    /// - Patch the client session with new user details
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

// MARK: - Get the cached user details
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

// MARK: - Patch the client session with new user details
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
