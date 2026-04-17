//
//  NetworkClientInstructionProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerBDCCore
import PrimerFoundation

struct NetworkClientInstructionProvider: ClientInstructionProvider {

    let paymentMethod: PrimerPaymentMethod

    func fetchPayInstruction() async throws -> ClientInstruction {
        let response: ClientSessionInstructionResponse = try await request(.pay(paymentMethod: paymentMethod))
        return response.clientInstruction.toClientInstruction()
    }

    func fetchNextInstruction() async throws -> ClientInstruction {
        let response: ClientSessionInstructionResponse = try await request(.expandClientSession)
        return response.clientInstruction.toClientInstruction()
    }
    
    private func request<T: Decodable>(_ endpoint: BackendDrivenCheckoutEndpoint) async throws -> T {
        try await defaultNetworkService.request(endpoint)
    }
}

private extension ClientInstructionDataResponse {
    func toClientInstruction() -> ClientInstruction {
        switch type {
        case let .wait(response):
            return .wait(delayMilliseconds: response.pollDelayMilliseconds ?? 0)
        case let .execute(response):
            return .execute(
                delayMilliseconds: response.pollDelayMilliseconds ?? 0,
                schema: response.schema,
                parameters: response.parameters
            )
        case let .end(response):
            return .end(
                outcome: response.payload.checkoutOutcome?.toCheckoutOutcome(),
                payment: response.payload.payment?.toPaymentInfo()
            )
        }
    }
}

private extension Response.Body.Payment.CheckoutOutcome {
    func toCheckoutOutcome() -> CheckoutOutcome {
        switch self {
        case .complete: .complete
        case .failure: .failure
        case .determineFromPaymentStatus: .determineFromPaymentStatus
        }
    }
}

private extension PrimerCheckoutDataPayment {
    func toPaymentInfo() -> PaymentInfo {
        PaymentInfo(id: id, orderId: orderId, status: status)
    }
}
