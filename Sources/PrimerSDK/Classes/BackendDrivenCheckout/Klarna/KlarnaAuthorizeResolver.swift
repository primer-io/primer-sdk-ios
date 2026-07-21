//
//  KlarnaAuthorizeResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
#endif
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

final class KlarnaAuthorizeResolver: NSObject, StepResolver {
    private nonisolated(unsafe) var continuation: CheckedContinuation<StepResolutionResult, Never>?
    
    @MainActor
    func resolve(_ data: CodableValue) async throws -> StepResolutionResult {
        let params = try data.casted(to: Params.self)
        let provider = KlarnaProviderStore.shared.provider(for: params.category)
        
        guard let provider else { return StepResolutionResult(outcome: .error) }
        provider.authorizationDelegate = self
        
        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            provider.authorize(autoFinalize: false, jsonData: nil)
        }
    }
}

extension KlarnaAuthorizeResolver: PrimerKlarnaProviderAuthorizationDelegate {
    func primerKlarnaWrapperAuthorized(approved: Bool, authToken: String?, finalizeRequired: Bool) {
        guard approved, let authToken else { return resume(.error) }
        resume(.success, data: .object(["authorization_token": .string(authToken)]))
    }
    
    func resume(_ outcome: TerminalOutcome, data: CodableValue? = nil) {
        continuation?.resume(returning: StepResolutionResult(outcome: outcome, data: data))
        continuation = nil
    }
    
    func primerKlarnaWrapperReauthorized(approved: Bool, authToken: String?) {}
}

private extension KlarnaAuthorizeResolver {
    struct Params: Decodable {
        let category: String
    }
}
