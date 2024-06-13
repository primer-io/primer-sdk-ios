//
//  KlarnaTokenizationManager.swift
//  PrimerSDK
//
//  Created by Stefan Vrancianu on 26.01.2024.
//

import Foundation

protocol KlarnaTokenizationManagerProtocol {
    /**
     Tokenizes the payment information for a customer using Klarna's payment service.
     - Parameters:
     - customerToken: An optional `Response.Body.Klarna.CustomerToken` object containing the customer's token and session data.
     - `offSessionAuthorizationId`: An optional `String` representing an off-session authorization ID. This is used when the session `intent` is `checkout`.

     - Returns: A `Promise<PrimerPaymentMethodTokenData>` which resolves to a `PrimerPaymentMethodTokenData`
     object on successful tokenization or rejects with an `Error` if the tokenization process fails.
     */
    func tokenizeHeadless(customerToken: Response.Body.Klarna.CustomerToken?, offSessionAuthorizationId: String?) -> Promise<PrimerCheckoutData>
    func tokenizeDropIn(customerToken: Response.Body.Klarna.CustomerToken?, offSessionAuthorizationId: String?) -> Promise<PrimerPaymentMethodTokenData>
}

class KlarnaTokenizationManager: KlarnaTokenizationManagerProtocol {

    // MARK: - Properties

    private let tokenizationService: TokenizationServiceProtocol

    private let createResumePaymentService: CreateResumePaymentServiceProtocol

    // MARK: - Init
    init(createResumePaymentService: CreateResumePaymentServiceProtocol,
         tokenizationService: TokenizationServiceProtocol = TokenizationService()) {
        self.tokenizationService = tokenizationService
        self.createResumePaymentService = createResumePaymentService
    }

    // MARK: - Tokenize Headless
    func tokenizeHeadless(customerToken: Response.Body.Klarna.CustomerToken?, offSessionAuthorizationId: String?) -> Promise<PrimerCheckoutData> {
        return Promise { seal in
            firstly {
                getRequestBody(customerToken: customerToken, offSessionAuthorizationId: offSessionAuthorizationId)
            }
            .then { requestBody in
                self.tokenizationService.tokenize(requestBody: requestBody)
            }
            .then { paymentMethodTokenData in
                self.startPaymentFlow(with: paymentMethodTokenData)
            }
            .done { checkoutData in
                seal.fulfill(checkoutData)
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }

    // MARK: - Tokenize DropIn
    func tokenizeDropIn(customerToken: Response.Body.Klarna.CustomerToken?, offSessionAuthorizationId: String?) -> Promise<PrimerPaymentMethodTokenData> {
        return Promise { seal in
            firstly {
                getRequestBody(customerToken: customerToken, offSessionAuthorizationId: offSessionAuthorizationId)
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

extension KlarnaTokenizationManager {
    func startPaymentFlow(with paymentMethodTokenData: PrimerPaymentMethodTokenData) -> Promise<PrimerCheckoutData> {
        return Promise { seal in
            guard let token = paymentMethodTokenData.token else {
                seal.reject(KlarnaHelpers.getInvalidTokenError())
                return
            }
            firstly {
                self.createPaymentEvent(token)
            }
            .done { paymentResponse -> Void in
                let paymentCheckoutData = PrimerCheckoutData(payment: PrimerCheckoutDataPayment(from: paymentResponse))
                seal.fulfill(paymentCheckoutData)
            }
            .catch { error in
                seal.reject(error)
            }
        }
    }

    // Create payment with Payment method token
    private func createPaymentEvent(_ paymentMethodData: String) -> Promise<Response.Body.Payment> {
        let paymentRequest = Request.Body.Payment.Create(token: paymentMethodData)
        return createResumePaymentService.createPayment(paymentRequest: paymentRequest)
    }

    private func getRequestBody(customerToken: Response.Body.Klarna.CustomerToken?, offSessionAuthorizationId: String?) -> Promise<Request.Body.Tokenization> {
        return Promise { seal in
            var customerTokenId: String?
            var paymentInstrument: TokenizationRequestBodyPaymentInstrument
            // Validates the presence of session data.
            // If the session data is missing, it generates an error indicating an invalid value for `tokenization.sessionData`
            guard let sessionData = customerToken?.sessionData else {
                let error = KlarnaHelpers.getInvalidValueError(key: "tokenization.sessionData", value: nil)
                seal.reject(error)
                return
            }
            // Checks if the session type is for recurring payments. If so, it attempts to extract the
            // customer token ID and sets 'KlarnaCustomerTokenPaymentInstrument' as a payment instrument.
            // Otherwise it sets the 'customerTokenId' with 'offSessionAuthorizationId' value
            // which is 'authToken' returned from 'primerKlarnaWrapperFinalized' KlarnaProvider
            // delegate method and sets 'KlarnaAuthorizationPaymentInstrument' as a payment instrument.
            // If the token ID is not found, it generates an error indicating an invalid value
            // for `tokenization.customerToken`
            if KlarnaHelpers.getSessionType() == .recurringPayment {
                guard let klarnaCustomerToken = customerToken?.customerTokenId else {
                    let error = KlarnaHelpers.getInvalidValueError(key: "tokenization.customerToken", value: nil)
                    seal.reject(error)
                    return
                }
                customerTokenId = klarnaCustomerToken
                // Prepares the payment instrument by creating a `KlarnaCustomerTokenPaymentInstrument` object
                paymentInstrument = KlarnaCustomerTokenPaymentInstrument(klarnaCustomerToken: customerTokenId, sessionData: sessionData)
            } else {
                customerTokenId = offSessionAuthorizationId
                // Prepares the payment instrument by creating a `KlarnaCustomerTokenPaymentInstrument` object
                paymentInstrument = KlarnaAuthorizationPaymentInstrument(klarnaAuthorizationToken: customerTokenId, sessionData: sessionData)
            }
            // Constructs a request body with the payment instrument and initiates a tokenization request through the `tokenizationService`.
            let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
            seal.fulfill(requestBody)
        }
    }
}
