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
                        This is used to identify the customer and their payment session.
       - completion: A completion handler that returns a result which is either a `PrimerPaymentMethodTokenData` on successful tokenization or an `Error` if the tokenization fails.
     */
    func tokenize(
        customerToken: Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?,
        completion: @escaping (Result<PrimerPaymentMethodTokenData, Error>) -> Void
    )
}

class KlarnaTokenizationManager: KlarnaTokenizationManagerProtocol {

    // MARK: - Properties
    private let tokenizationService: TokenizationServiceProtocol
    
    // MARK: - Init
    init() {
        self.tokenizationService = TokenizationService()
    }

    // MARK: - Tokenize
    func tokenize(
        customerToken: Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?,
        completion: @escaping (Result<PrimerPaymentMethodTokenData, Error>) -> Void
    ) {
        var customerTokenId: String?
        
        // Checks if the session type is for recurring payments. If so, it attempts to extract the customer token ID.
        // Otherwise it sets the 'customerTokenId' with 'offSessionAuthorizationId' value which is 'authToken' returned from 'primerKlarnaWrapperFinalized' KlarnaProvider delegate method
        // If the token ID is not found, it generates an error indicating an invalid value for `tokenization.customerToken`
        if KlarnaHelpers.getSessionType() == .recurringPayment {
            guard let klarnaCustomerToken = customerToken?.customerTokenId else {
                let error = self.getInvalidValueError(key: "tokenization.customerToken", value: nil)
                completion(.failure(error))
                return
            }
            customerTokenId = klarnaCustomerToken
        } else {
            customerTokenId = offSessionAuthorizationId
        }
        
        // Validates the presence of session data.
        // If the session data is missing, it generates an error indicating an invalid value for `tokenization.sessionData`
        guard let sessionData = customerToken?.sessionData else {
            let error = self.getInvalidValueError(key: "tokenization.sessionData", value: nil)
            completion(.failure(error))
            return
        }
        
        // Prepares the payment instrument by creating a `KlarnaCustomerTokenPaymentInstrument` object
        let paymentInstrument = KlarnaCustomerTokenPaymentInstrument(klarnaCustomerToken: customerTokenId, sessionData: sessionData)
        
        // Constructs a request body with the payment instrument and initiates a tokenization request through the `tokenizationService`.
        let requestBody = Request.Body.Tokenization(paymentInstrument: paymentInstrument)
        self.tokenizationService.tokenize(requestBody: requestBody) { (result) in
            completion(result)
        }
    }
}

// MARK: - Errors
extension KlarnaTokenizationManager {
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
