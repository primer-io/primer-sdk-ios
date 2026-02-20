//
//  BackendDrivenCheckoutViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerBDCCore

@MainActor
final class BackendDrivenCheckoutViewModel: PaymentMethodTokenizationViewModel {
    
    private let orchestrator = PrimerStepOrchestrator()
    
    override func start() {
        Task {
            do {
                try await processClientInstruction(try await request(.pay(paymentMethod: config)))
            } catch {
                let event = Analytics.Event.message(
                    message: "BDC Failed: \(error)",
                    messageType: .error,
                    severity: .error
                )
                Analytics.Service.fire(event: event)
            }
        }
    }
    
    override func validate() throws {
        if PrimerAPIConfigurationModule.decodedJWTToken?.isValid != true {
            throw handled(primerError: .invalidClientToken())
        }
    }
    
    @MainActor
    private func processClientInstruction(_ response: ClientSessionInstructionResponse) async throws  {
        switch response.clientInstruction.type {
        case let .wait(response):
            let delay = response.pollDelayMilliseconds ?? 0
            try await Task.sleep(nanoseconds: UInt64(delay) * 1000_000)
            try await processClientInstruction(request(.expandClientSession))
        case let .execute(response):
            let delay = response.pollDelayMilliseconds ?? 0
            try await Task.sleep(nanoseconds: UInt64(delay) * 1000_000)
            try await startBackendDrivenCheckout(with: response)
            try await processClientInstruction(request(.expandClientSession))
        case let .end(response):
            if PrimerSettings.current.paymentHandling == .auto {
                await PrimerDelegateProxy.primerDidCompleteCheckoutWithData(response.payload)
            }
        }
    }
    
    private func startBackendDrivenCheckout(with response: ClientInstructionExecuteResponse) async throws {
        let rawSchema = try response.schema.jsonString
        let initialState = response.parameters
        try await orchestrator.start(rawSchema: rawSchema, initialState: initialState)
    }
    
    private func request<T: Decodable>(_ endpoint: BackendDrivenCheckoutEndpoint) async throws -> T {
        try await defaultNetworkService.request(endpoint)
    }
}

enum BackendDrivenCheckoutError: LocalizedError {
    case missingPayload
    
    var errorDescription: String? {
        switch self {
        case .missingPayload: "Missing payload"
        }
    }
}
