//
//  KlarnaTokenizationComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.01.2024.
//

import Foundation

protocol KlarnaTokenizationComponentProtocol: KlarnaTokenizationManagerProtocol {
    /// - Validates the necessary conditions for proceeding with a payment operation.
    func validate() throws
    /// - Initiates the creation for Klarna Payment Session
    func createPaymentSession() -> Promise<Response.Body.Klarna.PaymentSession>
    /// - Initiates the authorization for Klarna Payment Session
    func authorizePaymentSession(authorizationToken: String) -> Promise<Response.Body.Klarna.CustomerToken>
}

class KlarnaTokenizationComponent: KlarnaTokenizationManager, KlarnaTokenizationComponentProtocol {
    // MARK: - Properties
    private let paymentMethod: PrimerPaymentMethod
    private let apiClient: PrimerAPIClientProtocol
    private var clientSession: ClientSession.APIResponse?
    private var paymentSessionId: String?
    private var recurringPaymentDescription: String?
    // MARK: - Settings
    let settings: PrimerSettingsProtocol = DependencyContainer.resolve()
    // MARK: - Init
    init(paymentMethod: PrimerPaymentMethod) {
        self.paymentMethod = paymentMethod
        self.apiClient = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
        self.clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
        self.recurringPaymentDescription = PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription
        super.init()
    }
}

// MARK: - Validate
extension KlarnaTokenizationComponent {
    func validate() throws {
        guard
            let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
            decodedJWTToken.isValid,
            decodedJWTToken.pciUrl != nil
        else {
            throw KlarnaHelpers.getInvalidTokenError()
        }
        guard paymentMethod.id != nil else {
            throw KlarnaHelpers.getInvalidValueError(
                key: "configuration.id",
                value: paymentMethod.id
            )
        }
        switch KlarnaHelpers.getSessionType() {
        case .oneOffPayment:
            try validateOneOffPayment()
        case .recurringPayment:
            break
        }
    }
    /// - Validates the necessary conditions specific to one-off payment operations.
    func validateOneOffPayment() throws {
        if AppState.current.amount == nil {
            throw KlarnaHelpers.getInvalidSettingError(name: "amount")
        }
        if AppState.current.currency == nil {
            throw KlarnaHelpers.getInvalidSettingError(name: "currency")
        }
        let lineItems = clientSession?.order?.lineItems ?? []
        if lineItems.isEmpty {
            throw KlarnaHelpers.getInvalidValueError(key: "lineItems")
        }
        if !(lineItems.filter({ $0.amount == nil })).isEmpty {
            throw KlarnaHelpers.getInvalidValueError(key: "settings.orderItems")
        }
    }
}

// MARK: - Create payment session
extension KlarnaTokenizationComponent {
    func createPaymentSession() -> Promise<Response.Body.Klarna.PaymentSession> {
        return Promise { seal in
            // Verify if we have a valid decoded JWT token
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                seal.reject(KlarnaHelpers.getInvalidTokenError())
                return
            }
            // Ensure the payment method has a valid ID
            guard let paymentMethodConfigId = paymentMethod.id else {
                seal.reject(KlarnaHelpers.getInvalidValueError(key: "configuration.id", value: paymentMethod.id))
                return
            }
            // Request the primer configuration update with actions
            let requestUpdateBody = prepareKlarnaClientSessionActionsRequestBody()
            firstly {
                requestPrimerConfiguration(decodedJWTToken: decodedJWTToken, request: requestUpdateBody)
            }
            .then({ () -> Promise<Response.Body.Klarna.PaymentSession> in
                // Prepare the body for the payment session creation request
                let body = self.prepareKlarnaPaymentSessionRequestBody(paymentMethodConfigId: paymentMethodConfigId)
                
                // Create the Klarna payment session
                return self.createKlarnaSession(with: body, decodedJWTToken: decodedJWTToken)
            })
            .done({ paymentSession in
                seal.fulfill(paymentSession)
            })
            .catch { error in
                seal.reject(error)
            }
        }
    }
    
}

// MARK: - Authorize payment session
extension KlarnaTokenizationComponent {
    func authorizePaymentSession(authorizationToken: String) -> Promise<Response.Body.Klarna.CustomerToken> {
        return Promise { seal in
            // Verify if we have a valid decoded JWT token
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                seal.reject(KlarnaHelpers.getInvalidTokenError())
                return
            }
            // Ensure the payment method has a valid ID and the payment session id is available
            guard let paymentMethodConfigId = paymentMethod.id, let sessionId = paymentSessionId else {
                seal.reject(KlarnaHelpers.getInvalidValueError(key: "paymentSessionId || configId", value: nil))
                return
            }
            switch KlarnaHelpers.getSessionType() {
            case .oneOffPayment:
                // Prepare the body for the Klarna Finalize Payment Session request
                let body = prepareKlarnaFinalizePaymentSessionBody(paymentMethodConfigId: paymentMethodConfigId, sessionId: sessionId)
                firstly {
                    // Finalize Klarna Payment Session
                    finalizeKlarnaPaymentSession(with: decodedJWTToken, body: body)
                }
                .done { customerToken in
                    seal.fulfill(customerToken)
                }
                .catch { error in
                    seal.reject(error)
                }
            case .recurringPayment:
                // Prepare the body for the Klarna Customer Token creation request
                let body = prepareKlarnaCustomerTokenBody(paymentMethodConfigId: paymentMethodConfigId, sessionId: sessionId, authorizationToken: authorizationToken)
                firstly {
                    // Create the Klarna Customer Token
                    createKlarnaCustomerToken(with: decodedJWTToken, body: body)
                }
                .done { customerToken in
                    seal.fulfill(customerToken)
                }
                .catch { error in
                    seal.reject(error)
                }
            }
        }
    }
}

// MARK: - Klarna Creation helpers
private extension KlarnaTokenizationComponent {
    /// - Helper method to prepare Klarna Payment Session request body
    private func prepareKlarnaPaymentSessionRequestBody(paymentMethodConfigId: String) -> Request.Body.Klarna.CreatePaymentSession {
        return KlarnaHelpers.getKlarnaPaymentSessionBody(
            with: paymentMethodConfigId,
            clientSession: clientSession,
            recurringPaymentDescription: recurringPaymentDescription,
            redirectUrl: settings.paymentMethodOptions.urlScheme)
    }
    
    /// - Helper method to prepare Client Session Update Request body with actions
    private func prepareKlarnaClientSessionActionsRequestBody() -> ClientSessionUpdateRequest {
        let params: [String: Any] = ["paymentMethodType": paymentMethod.type]
        let actions = [ClientSession.Action.selectPaymentMethodActionWithParameters(params)]
        return ClientSessionUpdateRequest(actions: ClientSessionAction(actions: actions))
    }
    
    /// - Request to update Primer Configuration with actions
    /// - Sets the client session with updated primer configuration request data
    private func requestPrimerConfiguration(decodedJWTToken: DecodedJWTToken, request: ClientSessionUpdateRequest) -> Promise<Void> {
        return Promise { seal in
            apiClient.requestPrimerConfigurationWithActions(clientToken: decodedJWTToken, request: request) { [weak self] result in
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
    
    /// - Request to create  Klarna Payment Session
    /// - Sets the 'paymentSessionId'  with response's 'sessionId'
    private func createKlarnaSession(with body: Request.Body.Klarna.CreatePaymentSession, decodedJWTToken: DecodedJWTToken) -> Promise<Response.Body.Klarna.PaymentSession> {
        return Promise { seal in
            apiClient.createKlarnaPaymentSession(clientToken: decodedJWTToken, klarnaCreatePaymentSessionAPIRequest: body) { [weak self] result in
                guard let self = self else { return }
                switch result {
                case .success(let response):
                    self.paymentSessionId = response.sessionId
                    seal.fulfill(response)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}

// MARK: - Klarna Authorization helpers
extension KlarnaTokenizationComponent {
    /// - Helper method to prepare Klarna Finalize Payment Session body
    private func prepareKlarnaFinalizePaymentSessionBody(paymentMethodConfigId: String, sessionId: String) -> Request.Body.Klarna.FinalizePaymentSession {
        return KlarnaHelpers.getKlarnaFinalizePaymentBody(
            with: paymentMethodConfigId,
            sessionId: sessionId)
    }
    
    /// - Request to finalize  Klarna Payment Session
    private func finalizeKlarnaPaymentSession(with clientToken: DecodedJWTToken, body: Request.Body.Klarna.FinalizePaymentSession) -> Promise<Response.Body.Klarna.CustomerToken> {
        return Promise { seal in
            apiClient.finalizeKlarnaPaymentSession(clientToken: clientToken, klarnaFinalizePaymentSessionRequest: body) { (result) in
                switch result {
                case .success(let response):
                    seal.fulfill(response)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
    
    /// - Helper method to prepare Klarna Customer Token body
    private func prepareKlarnaCustomerTokenBody(paymentMethodConfigId: String, sessionId: String, authorizationToken: String) -> Request.Body.Klarna.CreateCustomerToken {
        return KlarnaHelpers.getKlarnaCustomerTokenBody(
            with: paymentMethodConfigId,
            sessionId: sessionId,
            authorizationToken: authorizationToken,
            recurringPaymentDescription: recurringPaymentDescription)
    }
    
    /// - Request to create  Klarna Customer Token
    private func createKlarnaCustomerToken(with clientToken: DecodedJWTToken, body: Request.Body.Klarna.CreateCustomerToken) -> Promise<Response.Body.Klarna.CustomerToken> {
        return Promise { seal in
            apiClient.createKlarnaCustomerToken(clientToken: clientToken, klarnaCreateCustomerTokenAPIRequest: body) { (result) in
                switch result{
                case .success(let response):
                    seal.fulfill(response)
                case .failure(let error):
                    seal.reject(error)
                }
            }
        }
    }
}

// MARK: - Klarna Testing helpers
extension KlarnaTokenizationComponent {
    func setSessionId(paymentSessionId: String) {
        self.paymentSessionId = paymentSessionId
    }
}
