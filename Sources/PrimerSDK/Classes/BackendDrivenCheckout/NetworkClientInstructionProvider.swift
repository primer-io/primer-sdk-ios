//
//  NetworkClientInstructionProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCCore
import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking

struct NetworkClientInstructionProvider: ClientInstructionProvider {
    
    let paymentMethod: PrimerPaymentMethod
    
    func fetchPayInstruction() async throws -> ClientInstruction {
        let response: ClientSessionInstructionResponse = try await request(.pay(paymentMethod: paymentMethod))
        return response.clientInstruction.toClientInstruction(response: response)
    }
    
    func fetchNextInstruction() async throws -> ClientInstruction {
        let response: ClientSessionInstructionResponse = try await request(.expandClientSession)
        return response.clientInstruction.toClientInstruction(response: response)
    }
    
    private func request<T: Decodable>(_ endpoint: BackendDrivenCheckoutEndpoint) async throws -> T {
        try await defaultNetworkService.request(endpoint)
    }
}

private extension ClientInstructionDataResponse {
    func toClientInstruction(response: ClientSessionInstructionResponse) -> ClientInstruction {
        switch response.clientInstruction.type {
        case let .wait(waitResponse):
            return .wait(delayMilliseconds: waitResponse.pollDelayMilliseconds ?? 0)
        case let .execute(executeResponse):
            return .execute(
                delayMilliseconds: executeResponse.pollDelayMilliseconds ?? 0,
                schema: executeResponse.schema,
                parameters: executeResponse.parameters,
                currentAttempt: response.currentAttempt
            )
        case let .end(endResponse):
            return .end(
                outcome: endResponse.payload.checkoutOutcome?.toCheckoutOutcome(),
                payment: endResponse.payload.payment?.toPaymentInfo()
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
