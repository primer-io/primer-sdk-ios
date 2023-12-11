//
//  KlarnaTokenizationManager.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 11.12.2023.
//

import Foundation

protocol KlarnaTokenizationManagerProtocol {
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
    func tokenize(
        completion: @escaping (Result<PrimerPaymentMethodTokenData, Error>) -> Void
    )
}

class KlarnaTokenizationManager: KlarnaTokenizationManagerProtocol {
    // MARK: - Properties
    private let paymentMethod: PrimerPaymentMethod
    private let apiClient: PrimerAPIClientProtocol
    private let tokenizationService: TokenizationServiceProtocol
    private let clientSession: ClientSession.APIResponse?
    
    private var paymentSessionId: String?
    private var customerToken: Response.Body.Klarna.CustomerToken?
    
    // MARK: - Init
    init(paymentMethod: PrimerPaymentMethod) {
        self.paymentMethod = paymentMethod
        self.apiClient = PrimerAPIConfigurationModule.apiClient ?? PrimerAPIClient()
        self.tokenizationService = TokenizationService()
        self.clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
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

// MARK: - Tokenize payment session
extension KlarnaTokenizationManager {
    func tokenize(
        completion: @escaping (Result<PrimerPaymentMethodTokenData, Error>) -> Void
    ) {
        guard let klarnaCustomerToken = self.customerToken?.customerTokenId else {
            let error = self.getInvalidValueError(
                key: "tokenization.klarnaCustomerToken",
                value: nil
            )
            completion(.failure(error))
            return
        }

        guard let sessionData = self.customerToken?.sessionData else {
            let error = self.getInvalidValueError(
                key: "tokenization.sessionData",
                value: nil
            )
            completion(.failure(error))
            return
        }

        let paymentInstrument = KlarnaCustomerTokenPaymentInstrument(
            klarnaCustomerToken: klarnaCustomerToken,
            sessionData: sessionData
        )

        let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)

        self.tokenizationService.tokenize(requestBody: requestBody) { (result) in
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

// MARK: - Errors
private extension KlarnaTokenizationManager {
    func getInvalidTokenError() -> PrimerError {
        let error = PrimerError.invalidClientToken(
            userInfo: self.getErrorUserInfo(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
    
    func getInvalidSettingError(
        name: String
    ) -> PrimerError {
        let error = PrimerError.invalidSetting(
            name: name,
            value: nil,
            userInfo: self.getErrorUserInfo(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
    
    func getInvalidValueError(
        key: String,
        value: Any? = nil
    ) -> PrimerError {
        let error = PrimerError.invalidValue(
            key: key,
            value: value,
            userInfo: self.getErrorUserInfo(),
            diagnosticsId: UUID().uuidString
        )
        ErrorHandler.handle(error: error)
        return error
    }
    
    func getErrorUserInfo() -> [String: String] {
        return [
            "file": #file,
            "class": "\(Self.self)",
            "function": #function,
            "line": "\(#line)"
        ]
    }
}
