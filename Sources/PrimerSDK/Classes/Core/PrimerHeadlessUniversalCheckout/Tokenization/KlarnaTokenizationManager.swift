//
//  KlarnaTokenizationManager.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 11.12.2023.
//

import Foundation

protocol KlarnaTokenizationManagerProtocol: TokenizationManagerProtocol {
    func createPaymentSession(
        attachment: Request.Body.Klarna.CreatePaymentSession.Attachment?,
        completion: @escaping (Result<Response.Body.Klarna.CreatePaymentSession, Error>) -> Void
    )
    func authorizePaymentSession(
        authorizationToken: String,
        completion: @escaping (Result<Response.Body.Klarna.CustomerToken, Error>) -> Void
    )
    func finalizePaymentSession(
        completion: @escaping (Result<Response.Body.Klarna.CustomerToken, Error>) -> Void
    )
}

class KlarnaTokenizationManager: TokenizationManager, KlarnaTokenizationManagerProtocol {
    // MARK: - Properties
    private let paymentMethod: PrimerPaymentMethod
    private let apiClient: PrimerAPIClientProtocol
    private let tokenizationService: TokenizationServiceProtocol
    private let clientSession: ClientSession.APIResponse?
    
    private var paymentSessionId: String?
    
    // MARK: - Init
    init(paymentMethod: PrimerPaymentMethod) {
        self.paymentMethod = paymentMethod
        self.apiClient = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
        self.clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
        self.tokenizationService = TokenizationService()
        
        super.init()
    }
}

// MARK: - Validate
private extension KlarnaTokenizationManager {
    func validate() throws {
        guard
            let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
            decodedJWTToken.isValid,
            decodedJWTToken.pciUrl != nil
        else {
            throw self.getInvalidTokenError()
        }
        
        guard paymentMethod.id != nil else {
            throw self.getInvalidValueError(
                key: "configuration.id",
                value: paymentMethod.id
            )
        }
        
        switch self.getSessionType() {
        case .hostedPaymentPage:
            if AppState.current.amount == nil {
                throw self.getInvalidSettingError(name: "amount")
            }
            
            if AppState.current.currency == nil {
                throw self.getInvalidSettingError(name: "currency")
            }
            
            let lineItems = self.clientSession?.order?.lineItems ?? []
            
            if lineItems.isEmpty {
                throw self.getInvalidValueError(key: "lineItems")
            }
            
            if !(lineItems.filter({ $0.amount == nil })).isEmpty {
                throw self.getInvalidValueError(key: "settings.orderItems")
            }
            
        case .recurringPayment:
            break
        }
    }
}

// MARK: - Create payment session
extension KlarnaTokenizationManager {
    func createPaymentSession(
        attachment: Request.Body.Klarna.CreatePaymentSession.Attachment?,
        completion: @escaping (Result<Response.Body.Klarna.CreatePaymentSession, Error>) -> Void
    ) {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let error = self.getInvalidTokenError()
            completion(.failure(error))
            return
        }
        
        guard let configurationId = paymentMethod.id else {
            let error = self.getInvalidValueError(
                key: "configuration.id",
                value: paymentMethod.id
            )
            completion(.failure(error))
            return
        }
        
        let settings: PrimerSettingsProtocol = DependencyContainer.resolve()

        let body = Request.Body.Klarna.CreatePaymentSession(
            paymentMethodConfigId: configurationId,
            sessionType: .recurringPayment,
            localeData: PrimerSettings.current.localeData,
            description: PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            redirectUrl: settings.paymentMethodOptions.urlScheme,
            totalAmount: nil,
            orderItems: nil,
            attachment: attachment
        )
    
        self.apiClient.createKlarnaPaymentSession(
            clientToken: decodedJWTToken,
            klarnaCreatePaymentSessionAPIRequest: body
        ) { (result) in
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
extension KlarnaTokenizationManager {
    func authorizePaymentSession(
        authorizationToken: String,
        completion: @escaping (Result<Response.Body.Klarna.CustomerToken, Error>) -> Void
    ) {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let error = self.getInvalidTokenError()
            completion(.failure(error))
            return
        }
        
        guard
            let configId = self.getConfigId(),
            let sessionId = self.paymentSessionId
        else {
            let error = self.getInvalidValueError(
                key: "paymentSessionId || configId",
                value: nil
            )
            completion(.failure(error))
            return
        }
        
        let body = Request.Body.Klarna.CreateCustomerToken(
            paymentMethodConfigId: configId,
            sessionId: sessionId,
            authorizationToken: authorizationToken,
            description: PrimerSettings.current.paymentMethodOptions.klarnaOptions?.recurringPaymentDescription,
            localeData: PrimerSettings.current.localeData
        )

        self.apiClient.createKlarnaCustomerToken(
            clientToken: decodedJWTToken,
            klarnaCreateCustomerTokenAPIRequest: body
        ) { (result) in
            completion(result)
        }
    }
}

// MARK: - Finalize payment session
extension KlarnaTokenizationManager {
    func finalizePaymentSession(
        completion: @escaping (Result<Response.Body.Klarna.CustomerToken, Error>) -> Void
    ) {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken else {
            let error = self.getInvalidTokenError()
            completion(.failure(error))
            return
        }
        
        guard
            let configId = self.getConfigId(),
            let sessionId = self.paymentSessionId
        else {
            let error = self.getInvalidValueError(
                key: "paymentSessionId || configId",
                value: nil
            )
            completion(.failure(error))
            return
        }
        
        let body = Request.Body.Klarna.FinalizePaymentSession(paymentMethodConfigId: configId, sessionId: sessionId)
        
        self.apiClient.finalizeKlarnaPaymentSession(
            clientToken: decodedJWTToken,
            klarnaFinalizePaymentSessionRequest: body
        ) { (result) in
            completion(result)
        }
    }
}

// MARK: - Helpers
private extension KlarnaTokenizationManager {
    func getSessionType() -> KlarnaSessionType {
        if PrimerInternal.shared.intent == .vault {
            return .recurringPayment
        } else {
            return .hostedPaymentPage
        }
    }
    
    func getConfigId() -> String? {
        return PrimerAPIConfigurationModule.apiConfiguration?.getConfigId(
            for: PrimerPaymentMethodType.klarna.rawValue
        )
    }
}
