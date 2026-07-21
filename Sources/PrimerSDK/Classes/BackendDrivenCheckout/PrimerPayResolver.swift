//
//  PrimerPayResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

@MainActor
final class PrimerPayResolver: StepResolver {
    private let tokenizationService: TokenizationServiceProtocol
    private let paymentMethodType: String

    init(tokenizationService: TokenizationServiceProtocol, paymentMethodType: String) {
        self.tokenizationService = tokenizationService
        self.paymentMethodType = paymentMethodType
    }

    func resolve(_ data: CodableValue) async throws -> StepResolutionResult {
        let params = try JSONDecoder().decode(Params.self, from: JSONEncoder().encode(data))

        let checkoutType = PrimerCheckoutPaymentMethodType(type: paymentMethodType)
        let decision = await PrimerDelegateProxy.primerWillCreatePaymentWithData(
            PrimerCheckoutPaymentMethodData(type: checkoutType)
        )
        if case let .abort(message) = decision.type {
            print("[PrimerPay] merchant aborted payment creation: \(message ?? "")")
            return StepResolutionResult(outcome: .error)
        }

        let instrument = KlarnaAuthorizationPaymentInstrument(
            klarnaAuthorizationToken: params.authorizationToken,
            sessionData: params.sessionData
        )
        let tokenData = try await tokenizationService.tokenize(
            requestBody: Request.Body.Tokenization(paymentInstrument: instrument)
        )
        print("[PrimerPay] tokenized — token \(tokenData.token == nil ? "MISSING" : "present")")
        return StepResolutionResult(outcome: .success)
    }
}

private extension PrimerPayResolver {
    struct Params: Decodable {
        let authorizationToken: String
        let sessionData: Response.Body.Klarna.SessionData
    }
}
