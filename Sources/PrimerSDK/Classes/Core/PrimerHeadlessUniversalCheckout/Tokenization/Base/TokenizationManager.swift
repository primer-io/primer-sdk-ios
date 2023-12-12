//
//  TokenizationManager.swift
//  PrimerSDK
//
//  Created by Illia Khrypunov on 11.12.2023.
//

import Foundation

protocol TokenizationManagerProtocol {
    func tokenize(
        customerToken: Response.Body.Klarna.CustomerToken?,
        completion: @escaping (Result<PrimerPaymentMethodTokenData, Error>) -> Void
    )
}

class TokenizationManager: TokenizationManagerProtocol {
    
    // MARK: - Properties
    private let tokenizationService: TokenizationServiceProtocol
    
    // MARK: - Init
    init() {
        self.tokenizationService = TokenizationService()
    }
    
    // MARK: - Tokenize
    func tokenize(
        customerToken: Response.Body.Klarna.CustomerToken?,
        completion: @escaping (Result<PrimerPaymentMethodTokenData, Error>) -> Void
    ) {
        guard let klarnaCustomerToken = customerToken?.customerTokenId else {
            let error = self.getInvalidValueError(
                key: "tokenization.customerToken",
                value: nil
            )
            completion(.failure(error))
            return
        }

        guard let sessionData = customerToken?.sessionData else {
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

// MARK: - Errors
extension TokenizationManager {
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
