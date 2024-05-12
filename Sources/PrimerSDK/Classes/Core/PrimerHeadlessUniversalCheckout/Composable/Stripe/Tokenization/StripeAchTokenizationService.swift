//
//  StripeAchTokenizationManager.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 25.04.2024.
//

import Foundation

/**
 * Protocol for tokenization process regarding a Stripe ACH payment.
 *
 * - Returns: A `Promise<PrimerPaymentMethodTokenData>` which resolves to a `PrimerPaymentMethodTokenData`
 * object on successful tokenization or rejects with an `Error` if the tokenization process fails.
 */
protocol StripeAchTokenizationDelegate {
    func tokenize() -> Promise<PrimerPaymentMethodTokenData>
}

/**
 * Validation method to ensure data integrity before proceeding with tokenization or session updates.
 */
protocol StripeAchValidationDelegate {
    func validate() throws
}

class StripeAchTokenizationService: StripeAchTokenizationDelegate, StripeAchValidationDelegate {
    
    // MARK: - Properties
    private let tokenizationService: TokenizationServiceProtocol
    private let paymentMethod: PrimerPaymentMethod
    private var clientSession: ClientSession.APIResponse?

    // MARK: - Init
    init(paymentMethod: PrimerPaymentMethod) {
        self.paymentMethod = paymentMethod
        self.tokenizationService = TokenizationService()
        self.clientSession = PrimerAPIConfigurationModule.apiConfiguration?.clientSession
    }

    // MARK: - Tokenize
    func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            // Ensure the payment method has a valid ID
            guard let paymentMethodConfigId = paymentMethod.id else {
                seal.reject(KlarnaHelpers.getInvalidValueError(key: "configuration.id", value: paymentMethod.id))
                return
            }
            
            firstly {
                getRequestBody(paymentMethodConfigId: paymentMethodConfigId)
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
 * Constructs a tokenization request body for a Stripe ACH tokenize method.
 *
 * This private function generates the necessary payload for tokenization by assembling data related to
 * the payment method and additional session information.
 *
 * - Returns: A promise that resolves with a `Request.Body.Tokenization` containing the payment instrument data.
 */
extension StripeAchTokenizationService {
    private func getRequestBody(paymentMethodConfigId: String) -> Promise<Request.Body.Tokenization> {
        return Promise { seal in
            let sessionInfo = StripeHelpers.constructLocaleData()
            let paymentInstrument = StripeAchPaymentInstrument(paymentMethodConfigId: paymentMethodConfigId,
                                                               paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue,
                                                               authenticationProvider: PrimerPaymentMethodType.stripeAch.provider,
                                                               type: PaymentInstrumentType.stripeAch.rawValue,
                                                               sessionInfo: sessionInfo)
            
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }
}
