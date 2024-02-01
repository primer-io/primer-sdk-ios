//
//  KlarnaTokenizationComponent.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.01.2024.
//

import Foundation

protocol KlarnaTokenizationComponentProtocol: KlarnaTokenizationManagerProtocol {
    func validate() throws
    func createPaymentSession(
        attachment: Request.Body.Klarna.CreatePaymentSession.Attachment?,
        completion: @escaping (Result<Response.Body.Klarna.PaymentSession, Error>) -> Void
    )
    func authorizePaymentSession(
        authorizationToken: String,
        completion: @escaping (Result<Response.Body.Klarna.CustomerToken, Error>) -> Void
    )
}

class KlarnaTokenizationComponent: KlarnaTokenizationManager, KlarnaTokenizationComponentProtocol {
    // MARK: - Properties
    private let paymentMethod: PrimerPaymentMethod
    private let apiClient: PrimerAPIClientProtocol
    private let clientSession: ClientSession.APIResponse?
    
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
            throw getInvalidTokenError()
        }
        
        guard paymentMethod.id != nil else {
            throw getInvalidValueError(
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
    
    func validateOneOffPayment() throws {
        if AppState.current.amount == nil {
            throw getInvalidSettingError(name: "amount")
        }
        
        if AppState.current.currency == nil {
            throw getInvalidSettingError(name: "currency")
        }
        
        let lineItems = clientSession?.order?.lineItems ?? []
        
        if lineItems.isEmpty {
            throw getInvalidValueError(key: "lineItems")
        }
        
        if !(lineItems.filter({ $0.amount == nil })).isEmpty {
            throw getInvalidValueError(key: "settings.orderItems")
        }
    }
}

// MARK: - Create payment session
extension KlarnaTokenizationComponent {
    func createPaymentSession(
        attachment: Request.Body.Klarna.CreatePaymentSession.Attachment?,
        completion: @escaping (Result<Response.Body.Klarna.PaymentSession, Error>) -> Void) {
            guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
                let error = getInvalidTokenError()
                completion(.failure(error))
                return
            }
            
            guard let paymentMethodConfigId = paymentMethod.id else {
                let error = getInvalidValueError(key: "configuration.id", value: paymentMethod.id)
                completion(.failure(error))
                return
            }
            
            let body = KlarnaHelpers.getKlarnaPaymentSessionBody(
                with: attachment,
                paymentMethodConfigId: paymentMethodConfigId,
                clientSession: clientSession,
                recurringPaymentDescription: recurringPaymentDescription,
                redirectUrl: settings.paymentMethodOptions.urlScheme)
            
            self.apiClient.createKlarnaPaymentSession(clientToken: decodedJWTToken, klarnaCreatePaymentSessionAPIRequest: body) { (result) in
                switch result {
                case .failure(let error):
                    completion(.failure(error))
                    
                case .success(let response):
                    self.paymentSessionId = response.sessionId
                    
                    completion(.success(response))
                }
            }
        }
    
}

// MARK: - Authorize payment session
extension KlarnaTokenizationComponent {
    func authorizePaymentSession(authorizationToken: String, completion: @escaping (Result<Response.Body.Klarna.CustomerToken, Error>) -> Void) {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let error = getInvalidTokenError()
            completion(.failure(error))
            return
        }
        
        guard
            let paymentMethodConfigId = paymentMethod.id,
            let sessionId = paymentSessionId
        else {
            let error = self.getInvalidValueError(
                key: "paymentSessionId || configId",
                value: nil)
            completion(.failure(error))
            return
        }
        
        let body = KlarnaHelpers.getKlarnaCustomerTokenBody(
            with: paymentMethodConfigId,
            sessionId: sessionId,
            authorizationToken: authorizationToken,
            recurringPaymentDescription: recurringPaymentDescription)
        
        self.apiClient.createKlarnaCustomerToken(
            clientToken: decodedJWTToken,
            klarnaCreateCustomerTokenAPIRequest: body) { (result) in
                completion(result)
            }
    }
}
