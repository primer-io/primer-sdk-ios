//
//  NetworkClientInstructionProvider.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerNetworking

struct NetworkClientInstructionProvider: ClientInstructionProvider {

    let paymentMethod: PrimerPaymentMethod

    private static let defaultPollDelayMilliseconds = 1000
    private static let startAttempts = 3
    private static let pollAttempts = 4
    private static let retryDelayMilliseconds = 250

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
        switch try await request(endpoint, attempts: Self.startAttempts) as SetupStartResponse {
        case let .ended(ended):
            throw SetupEnded(reason: ended.reason)
        case let .started(response):
            return SetupFlow(
                schema: response.instruction.payload.schema,
                parameters: response.instruction.payload.parameters,
                setupId: response.paymentMethodSetupId,
                nextPoll: response.instruction.nextPoll,
                pollDelayMilliseconds: response.instruction.pollDelayMilliseconds ?? Self.defaultPollDelayMilliseconds
            )
        }
    }

    func fetchSetupState(setupId: String) async throws -> SetupState {
        let endpoint: BackendDrivenCheckoutEndpoint = .pollSetup(setupId: setupId)
        let response: SetupStateResponse
        do {
            response = try await request(endpoint, attempts: Self.pollAttempts)
        } catch where Self.isTransient(error) {
            throw SetupEnded(reason: .failed)
        }
        switch response {
        case let .ended(ended):
            return SetupState(instruction: .ended(reason: ended.reason), nextPoll: .suspend)
        case let .state(response):
            return SetupState(
                instruction: try response.toSetupInstruction(),
                nextPoll: response.instruction.nextPoll ?? .suspend,
                pollDelayMilliseconds: response.instruction.pollDelayMilliseconds ?? Self.defaultPollDelayMilliseconds
            )
        }
    }

    func fetchNextInstruction() async throws -> ClientInstruction {
        let response: ClientSessionInstructionResponse = try await request(.expandClientSession)
        return response.clientInstruction.toClientInstruction(response: response)
    }

    private func request<T: Decodable>(_ endpoint: BackendDrivenCheckoutEndpoint, attempts: Int = 1) async throws -> T {
        var attempt = 1
        while true {
            do {
                return try await defaultNetworkService.request(endpoint)
            } catch where attempt < attempts && Self.isTransient(error) {
                attempt += 1
                try await Task.sleep(nanoseconds: UInt64(Self.retryDelayMilliseconds) * 1_000_000)
            }
        }
    }

    private static func isTransient(_ error: Error) -> Bool {
        if error.isNetworkError { return true }
        if case let InternalError.serverError(status, _, _) = error { return (500...599).contains(status) }
        return false
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
