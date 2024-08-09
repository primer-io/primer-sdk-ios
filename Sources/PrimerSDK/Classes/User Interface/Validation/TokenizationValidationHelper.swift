//
//  TokenizationValidationHelper.swift
//  PrimerSDK
//
//  Created by Jack Newcombe on 24/06/2024.
//

import Foundation

class TokenizationValidationHelper {

    static let shared = TokenizationValidationHelper()

    private init() {}

    @discardableResult
    func validateClientToken() throws -> DecodedJWTToken {
        guard let decodedJWTToken = PrimerAPIConfigurationModule.decodedJWTToken, decodedJWTToken.isValid else {
            let err = PrimerError.invalidClientToken(
                userInfo: .errorUserInfoDictionary(),
                diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
        return decodedJWTToken
    }

    func validatePciUrl() throws {
        let decodedJWTToken = try validateClientToken()
        guard decodedJWTToken.pciUrl != nil else {
            let err = PrimerError.invalidValue(key: "decodedClientToken.pciUrl",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }

    func validateId(in config: PrimerPaymentMethod) throws {
        guard config.id != nil else {
            let err = PrimerError.invalidValue(key: "configuration.id",
                                               value: config.id,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }

    func validateAppStateAmount() throws {
        guard AppState.current.amount != nil else {
            let err = PrimerError.invalidValue(key: "amount",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }

    func validateAppStateCurrency() throws {
        guard AppState.current.currency != nil else {
            let err = PrimerError.invalidValue(key: "currency",
                                               value: nil,
                                               userInfo: .errorUserInfoDictionary(),
                                               diagnosticsId: UUID().uuidString)
            ErrorHandler.handle(error: err)
            throw err
        }
    }
}
