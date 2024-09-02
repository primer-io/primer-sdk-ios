//
//  ACHTokenizationManager.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

/**
 * Protocol for tokenization process regarding an ACH payment.
 *
 * - Returns: A `Promise<PrimerPaymentMethodTokenData>` which resolves to a `PrimerPaymentMethodTokenData`
 * object on successful tokenization or rejects with an `Error` if the tokenization process fails.
 */
protocol ACHTokenizationDelegate {
    func tokenize() -> Promise<PrimerPaymentMethodTokenData>
}

/**
 * Validation method to ensure data integrity before proceeding with tokenization.
 */
protocol ACHValidationDelegate {
    func validate() throws
}

class ACHTokenizationService: ACHTokenizationDelegate, ACHValidationDelegate {
    
    // MARK: - Properties
    private let tokenizationService: TokenizationServiceProtocol
    private let paymentMethod: PrimerPaymentMethod
    private var clientSession: ClientSession.APIResponse?

    // MARK: - Init
    init(paymentMethod: PrimerPaymentMethod, tokenizationService: TokenizationServiceProtocol = TokenizationService()) {
        self.paymentMethod = paymentMethod
        self.tokenizationService = tokenizationService
        self.clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
    }

    // MARK: - Tokenize
    func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            // Ensure the payment method has a valid ID
            guard paymentMethod.id != nil else {
                seal.reject(ACHHelpers.getInvalidValueError(key: "configuration.id", value: paymentMethod.id))
                return
            }
            
            firstly {
                getRequestBody()
            }
            .then { requestBody in
                self.tokenizationService.tokenize(requestBody: requestBody)
            }
            .done { paymentMethodTokenData in
                seal.fulfill(paymentMethodTokenData)
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }
    
    // MARK: - Validation
    func validate() throws {
        guard
            let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken,
            decodedJWTToken.isValid,
            decodedJWTToken.pciUrl != nil
        else {
            throw ACHHelpers.getInvalidTokenError()
        }
        
        guard paymentMethod.id != nil else {
            throw ACHHelpers.getInvalidValueError(
                key: "configuration.id",
                value: paymentMethod.id
            )
        }
        
        if AppState.current.amount == nil {
            throw ACHHelpers.getInvalidSettingError(name: "amount")
        }
        
        if AppState.current.currency == nil {
            throw ACHHelpers.getInvalidSettingError(name: "currency")
        }
        
        let lineItems = clientSession?.order?.lineItems ?? []
        if lineItems.isEmpty {
            throw ACHHelpers.getInvalidValueError(key: "lineItems")
        }
        
        if !(lineItems.filter({ $0.amount == nil })).isEmpty {
            throw ACHHelpers.getInvalidValueError(key: "settings.orderItems")
        }
        
        guard let publishableKey = PrimerSettings.current.paymentMethodOptions.stripeOptions?.publishableKey,
              !publishableKey.isEmpty
        else {
            throw ACHHelpers.getInvalidValueError(key: "stripeOptions.publishableKey")
        }
        
        do {
            _ = try PrimerSettings.current.paymentMethodOptions.validSchemeForUrlScheme()
        } catch let error {
            throw error
        }
    }
}

/**
 * Constructs a tokenization request body for an ACH tokenize method.
 *
 * This private function generates the necessary payload for tokenization by assembling data related to
 * the payment method and additional session information.
 *
 * - Returns: A promise that resolves with a `Request.Body.Tokenization` containing the payment instrument data.
 */
extension ACHTokenizationService {
    private func getRequestBody() -> Promise<Request.Body.Tokenization> {
        return Promise { seal in
            guard let paymentInstrument = ACHHelpers.getACHPaymentInstrument(paymentMethod: paymentMethod) else {
                let error = ACHHelpers.getInvalidValueError(
                    key: "configuration.type",
                    value: paymentMethod.type
                )
                seal.reject(error)
                return
            }
            
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }
}
