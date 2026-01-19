//
//  MockKlarnaTokenizationComponent.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
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
        case let .failure(error): throw error
        case nil: throw PrimerError.unknown()
        }
    }

    func createPaymentSession() async throws -> PrimerSDK.Response.Body.Klarna.PaymentSession {
        switch createPaymentSessionResult {
        case let .success(paymentSession): return paymentSession
        case let .failure(error): throw error
        case nil: throw PrimerError.unknown()
        }
    }

    func authorizePaymentSession(
        authorizationToken: String
    ) async throws -> PrimerSDK.Response.Body.Klarna.CustomerToken {
        switch authorizePaymentSessionResult {
        case let .success(customerToken): return customerToken
        case let .failure(error): throw error
        case nil: throw PrimerError.unknown()
        }
    }

    func tokenizeHeadless(
        customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) async throws -> PrimerSDK.PrimerCheckoutData {
        switch tokenizeHeadlessResult {
        case let .success(primerCheckoutData): return primerCheckoutData
        case let .failure(error): throw error
        case nil: throw PrimerError.unknown()
        }
    }

    func tokenizeDropIn(
        customerToken: PrimerSDK.Response.Body.Klarna.CustomerToken?,
        offSessionAuthorizationId: String?
    ) async throws -> PrimerSDK.PrimerPaymentMethodTokenData {
        switch tokenizeDropInResult {
        case let .success(paymentMethodToken): return paymentMethodToken
        case let .failure(error): throw error
        case nil: throw PrimerError.unknown()
        }
    }
}
