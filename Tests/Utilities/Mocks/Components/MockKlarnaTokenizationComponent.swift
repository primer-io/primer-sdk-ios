//
//  MockKlarnaTokenizationComponent.swift
//
//
//  Created by Onur Var on 19.04.2025.
//

@testable import PrimerSDK

class MockKlarnaTokenizationComponent: KlarnaTokenizationComponentProtocol {
    var validateResult: Result<Void, Error>?
    func validate() throws {
        guard let result = validateResult else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }

        switch result {
        case .success:
            return
        case .failure(let error):
            throw error
        }
    }

    var createPaymentSessionResult: Result<PrimerSDK.Response.Body.Klarna.PaymentSession, Error>?

    func createPaymentSession() -> PrimerSDK.Promise<PrimerSDK.Response.Body.Klarna.PaymentSession> {
        return Promise { seal in
            guard let result = self.createPaymentSessionResult else {
                seal.reject(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
                return
            }

            switch result {
            case .success(let paymentSession):
                seal.fulfill(paymentSession)
            case .failure(let error):
                seal.reject(error)
            }
        }
    }

    func createPaymentSession() async throws -> PrimerSDK.Response.Body.Klarna.PaymentSession {
        guard let result = createPaymentSessionResult else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }

        switch result {
        case .success(let paymentSession):
            return paymentSession
        case .failure(let error):
            throw error
        }
    }

    var authorizePaymentSessionResult: Result<PrimerSDK.Response.Body.Klarna.CustomerToken, Error>?

    func authorizePaymentSession(authorizationToken: String) -> PrimerSDK.Promise<PrimerSDK.Response.Body.Klarna.CustomerToken> {
        return Promise { seal in
            guard let result = self.authorizePaymentSessionResult else {
                seal.reject(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
                return
            }

            switch result {
            case .success(let customerToken):
                seal.fulfill(customerToken)
            case .failure(let error):
                seal.reject(error)
            }
        }
    }

    func authorizePaymentSession(authorizationToken: String) async throws -> PrimerSDK.Response.Body.Klarna.CustomerToken {
        guard let result = authorizePaymentSessionResult else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }

        switch result {
        case .success(let customerToken):
            return customerToken
        case .failure(let error):
            throw error
        }
    }

    var tokenizeHeadlessResult: Result<PrimerSDK.PrimerCheckoutData, Error>?

    func tokenizeHeadless(
        customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) -> PrimerSDK.Promise<PrimerSDK.PrimerCheckoutData> {
        return Promise { seal in
            guard let result = self.tokenizeHeadlessResult else {
                seal.reject(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
                return
            }

            switch result {
            case .success(let primerCheckoutData):
                seal.fulfill(primerCheckoutData)
            case .failure(let error):
                seal.reject(error)
            }
        }
    }

    func tokenizeHeadless(
        customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) async throws -> PrimerSDK.PrimerCheckoutData {
        guard let result = tokenizeHeadlessResult else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }

        switch result {
        case .success(let primerCheckoutData):
            return primerCheckoutData
        case .failure(let error):
            throw error
        }
    }

    var tokenizeDropInResult: Result<PrimerSDK.PrimerPaymentMethodTokenData, Error>?

    func tokenizeDropIn(
        customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) -> PrimerSDK.Promise<PrimerSDK.PrimerPaymentMethodTokenData> {
        return Promise { seal in
            guard let result = self.tokenizeDropInResult else {
                seal.reject(PrimerError.unknown(userInfo: nil, diagnosticsId: ""))
                return
            }

            switch result {
            case .success(let paymentMethodToken):
                seal.fulfill(paymentMethodToken)
            case .failure(let error):
                seal.reject(error)
            }
        }
    }

    func tokenizeDropIn(
        customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) async throws -> PrimerSDK.PrimerPaymentMethodTokenData {
        guard let result = tokenizeDropInResult else {
            throw PrimerError.unknown(userInfo: nil, diagnosticsId: "")
        }

        switch result {
        case .success(let paymentMethodToken):
            return paymentMethodToken
        case .failure(let error):
            throw error
        }
    }
}
