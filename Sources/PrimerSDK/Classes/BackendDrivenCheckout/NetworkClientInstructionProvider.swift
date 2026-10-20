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
        let endpoint: BackendDrivenCheckoutEndpoint = .pay(paymentMethod: paymentMethod)
        let response: ClientSessionInstructionResponse = try await request(endpoint)
        return response.clientInstruction.toClientInstruction(response: response)
    }

    func fetchPayInstruction(paymentInstrumentTokenId: String) async throws -> ClientInstruction {
        let response: ClientSessionInstructionResponse = try await request(.payWithToken(paymentInstrumentTokenId: paymentInstrumentTokenId))
        return response.clientInstruction.toClientInstruction(response: response)
    }

    func fetchSetupFlow() async throws -> SetupFlow {
        let endpoint: BackendDrivenCheckoutEndpoint = .setup(paymentMethod: paymentMethod)
        let response: ClientInstructionSetupResponse = try await request(endpoint)
        return SetupFlow(
            schema: response.instruction.payload.schema,
            parameters: response.instruction.payload.parameters,
            setupId: response.paymentMethodSetupId,
            nextPoll: response.instruction.nextPoll
        )
    }

    func fetchSetupState(setupId: String) async throws -> SetupState {
        let endpoint: BackendDrivenCheckoutEndpoint = .pollSetup(setupId: setupId)
        let response: ClientInstructionSetupStateResponse = try await request(endpoint)
        let nextPoll = response.instruction.nextPoll ?? .suspend
        return SetupState(instruction: try response.toSetupInstruction(), nextPoll: nextPoll)
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
            .wait(delayMilliseconds: waitResponse.pollDelayMilliseconds ?? 0)
        case let .execute(executeResponse):
            .execute(
                delayMilliseconds: executeResponse.pollDelayMilliseconds ?? 0,
                schema: executeResponse.schema,
                parameters: executeResponse.parameters,
                currentAttempt: response.currentAttempt
            )
        case let .end(endResponse):
            .end(
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

private extension ClientInstructionSetupStateResponse {
    func toSetupInstruction() throws -> SetupInstruction {
        switch instruction.type {
        case .wait:
            return .wait
        case .execute:
            guard let schema = instruction.payload?.schema else { throw SetupStateError.missingScreen }
            return .execute(screen: schema)
        case .setupComplete:
            guard let token = instruction.payload?.paymentInstrumentToken?.token else { throw SetupStateError.missingToken }
            return .setupComplete(token: token)
        }
    }
}

private enum SetupStateError: Error {
    case missingScreen
    case missingToken
}
