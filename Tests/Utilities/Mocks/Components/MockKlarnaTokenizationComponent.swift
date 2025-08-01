//
//  MockKlarnaTokenizationComponent.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK

class MockKlarnaTokenizationComponent: KlarnaTokenizationComponentProtocol {
    var validateResult: Result<Void, Error>?
    var createPaymentSessionResult: Result<PrimerSDK.Response.Body.Klarna.PaymentSession, Error>?
    var tokenizeHeadlessResult: Result<PrimerSDK.PrimerCheckoutData, Error>?
    var authorizePaymentSessionResult: Result<PrimerSDK.Response.Body.Klarna.CustomerToken, Error>?
    var tokenizeDropInResult: Result<PrimerSDK.PrimerPaymentMethodTokenData, Error>?

    func validate() throws {
        switch validateResult {
        case .success: return
        case .failure(let error): throw error
        case nil: throw PrimerError.unknown()
        }
    }

    func createPaymentSession() -> PrimerSDK.Promise<PrimerSDK.Response.Body.Klarna.PaymentSession> {
        return Promise { seal in
            switch createPaymentSessionResult {
            case .success(let paymentSession): seal.fulfill(paymentSession)
            case .failure(let error): seal.reject(error)
            case nil: seal.reject(PrimerError.unknown())
            }
        }
    }

    func createPaymentSession() async throws -> PrimerSDK.Response.Body.Klarna.PaymentSession {
        switch createPaymentSessionResult {
        case .success(let paymentSession): return paymentSession
        case .failure(let error): throw error
        case nil: throw PrimerError.unknown()
        }
    }

    func authorizePaymentSession(
        authorizationToken: String
    ) -> PrimerSDK.Promise<PrimerSDK.Response.Body.Klarna.CustomerToken> {
        return Promise { seal in
            switch authorizePaymentSessionResult {
            case .success(let customerToken): seal.fulfill(customerToken)
            case .failure(let error): seal.reject(error)
            case nil: seal.reject(PrimerError.unknown())
            }
        }
    }

    func authorizePaymentSession(
        authorizationToken: String
    ) async throws -> PrimerSDK.Response.Body.Klarna.CustomerToken {
        switch authorizePaymentSessionResult {
        case .success(let customerToken): return customerToken
        case .failure(let error): throw error
        case nil: throw PrimerError.unknown()
        }
    }

    func tokenizeHeadless(
        customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) -> PrimerSDK.Promise<PrimerSDK.PrimerCheckoutData> {
        return Promise { seal in
            switch tokenizeHeadlessResult {
            case .success(let primerCheckoutData): seal.fulfill(primerCheckoutData)
            case .failure(let error): seal.reject(error)
            case nil: seal.reject(PrimerError.unknown())
            }
        }
    }

    func tokenizeHeadless(
        customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) async throws -> PrimerSDK.PrimerCheckoutData {
        switch tokenizeHeadlessResult {
        case .success(let primerCheckoutData): return primerCheckoutData
        case .failure(let error): throw error
        case nil: throw PrimerError.unknown()
        }
    }

    func tokenizeDropIn(
        customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) -> PrimerSDK.Promise<PrimerSDK.PrimerPaymentMethodTokenData> {
        return Promise { seal in
            switch tokenizeDropInResult {
            case .success(let paymentMethodToken): seal.fulfill(paymentMethodToken)
            case .failure(let error): seal.reject(error)
            case nil: seal.reject(PrimerError.unknown())
            }
        }
    }

    func tokenizeDropIn(
        customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) async throws -> PrimerSDK.PrimerPaymentMethodTokenData {
        switch tokenizeDropInResult {
        case .success(let paymentMethodToken): return paymentMethodToken
        case .failure(let error): throw error
        case nil: throw PrimerError.unknown()
        }
    }
}
