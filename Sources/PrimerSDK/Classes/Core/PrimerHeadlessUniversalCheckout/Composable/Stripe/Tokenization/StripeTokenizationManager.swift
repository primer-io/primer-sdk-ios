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
protocol StripeTokenizationManagerProtocol {
    func tokenize() -> Promise<PrimerPaymentMethodTokenData>
}

class StripeTokenizationManager: StripeTokenizationManagerProtocol {
    // MARK: - Properties
    private let tokenizationService: TokenizationServiceProtocol

    // MARK: - Init
    init() {
        self.tokenizationService = TokenizationService()
    }

    // MARK: - Tokenize
    func tokenize() -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
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
}

/**
 * Constructs a tokenization request body for a Stripe ACH tokenize method.
 *
 * This private function generates the necessary payload for tokenization by assembling data related to
 * the payment method and additional session information.
 *
 * - Returns: A promise that resolves with a `Request.Body.Tokenization` containing the payment instrument data.
 */
extension StripeTokenizationManager {
    private func getRequestBody() -> Promise<Request.Body.Tokenization> {
        return Promise { seal in
            let sessionInfo = StripeHelpers.constructLocaleData()
            let paymentInstrument = StripeAchPaymentInstrument(paymentMethodConfigId: "",
                                                               paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue,
                                                               authenticationProvider: PrimerPaymentMethodType.stripeAch.provider,
                                                               type: PaymentInstrumentType.stripe.rawValue,
                                                               sessionInfo: sessionInfo)
            
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }
}
