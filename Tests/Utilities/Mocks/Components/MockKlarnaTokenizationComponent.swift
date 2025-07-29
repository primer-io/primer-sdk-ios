//
//  MockKlarnaTokenizationComponent.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

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

    var tokenizeHeadlessResult: Result<PrimerSDK.PrimerCheckoutData, Error>?

    func tokenizeHeadless(customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?, offSessionAuthorizationId: String?) -> PrimerSDK
        .Promise<PrimerSDK.PrimerCheckoutData> {
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

    var tokenizeDropInResult: Result<PrimerSDK.PrimerPaymentMethodTokenData, Error>?

    func tokenizeDropIn(customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?, offSessionAuthorizationId: String?) -> PrimerSDK
        .Promise<PrimerSDK.PrimerPaymentMethodTokenData> {
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
}
