//
//  PrimerPayResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver
@_spi(PrimerInternal) import PrimerNetworking

@MainActor
final class PrimerPayResolver: StepResolver {
    private let tokenizationService: TokenizationServiceProtocol
    private let paymentService: CreateResumePaymentServiceProtocol
    private let paymentMethodType: String

    init(
        tokenizationService: TokenizationServiceProtocol,
        paymentService: CreateResumePaymentServiceProtocol,
        paymentMethodType: String
    ) {
        self.tokenizationService = tokenizationService
        self.paymentService = paymentService
        self.paymentMethodType = paymentMethodType
    }

    func resolve(_ data: CodableValue) async throws -> StepResolutionResult {
        let checkoutType = PrimerCheckoutPaymentMethodType(type: paymentMethodType)
        let paymentData = PrimerCheckoutPaymentMethodData(type: checkoutType)
        let decision = await PrimerDelegateProxy.primerWillCreatePaymentWithData(paymentData)
        
        if case .abort = decision.type { return StepResolutionResult(outcome: .error) }
        
        let body = Request.Body.Tokenization(paymentInstrument: RawPaymentInstrument(json: data))
        let tokenData = try await tokenizationService.tokenize(requestBody: body)
        
        guard let token = tokenData.token else { return StepResolutionResult(outcome: .error) }
        
        let paymentRequest = Request.Body.Payment.Create(token: token)
        _ = try await paymentService.createPayment(paymentRequest: paymentRequest)
                                             
        return StepResolutionResult(outcome: .success)
    }
}
