//
//  BackendDrivenCheckoutViewModel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerBDCCore

final class BackendDrivenCheckoutViewModel: PaymentMethodTokenizationViewModel {
    
    override func start() {
        Task {
            try await ingestResponse(try await request(.pay(paymentMethod: config)))
        }
    }
    
    override func validate() throws {
        if PrimerAPIConfigurationModule.decodedJWTToken?.isValid != true {
            throw handled(primerError: .invalidClientToken())
        }
    }
    
    @MainActor
    private func ingestResponse(_ response: ClientSessionInstructionResponse) async throws  {
        let payload = response.clientInstruction.payload
        
        switch response.clientInstruction.type {
        case .wait: return try await ingestResponse(request(.expandClientSession))
        default: break
        }
        
        guard
            let rawSchema = try payload?.schema.jsonString,
            let initialState = payload?.parameters else {
            fatalError("[SDK] No raw schema found in response")
        }
        let orchestrator = PrimerStepOrchestrator()
        try await orchestrator.start(rawSchema: rawSchema, initialState: initialState)
    }
    
    private func request<T: Decodable>(_ endpoint: BackendDrivenCheckoutEndpoint) async throws -> T {
        try await defaultNetworkService.request(endpoint)
    }
}
