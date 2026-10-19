//
//  KlarnaAuthorizeResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
import PrimerKlarnaSDK
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

final class KlarnaAuthorizeResolver: NSObject, StepResolver, LogReporter {
    private nonisolated(unsafe) var continuation: CheckedContinuation<StepResolutionResult, Never>?
    private nonisolated(unsafe) var provider: PrimerKlarnaProviding?
    private nonisolated(unsafe) weak var widgetErrorDelegate: PrimerKlarnaProviderErrorDelegate?

    @MainActor
    func resolve(_ data: CodableValue) async throws -> StepResolutionResult {
        let params = try? data.casted(to: Params.self)
        guard let provider = KlarnaProviderStore.shared.provider(for: params?.category) else {
            return StepResolutionResult(outcome: .error)
        }
        provider.authorizationDelegate = self
        widgetErrorDelegate = provider.errorDelegate
        provider.errorDelegate = self
        self.provider = provider

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            provider.authorize(autoFinalize: true, jsonData: nil)
        }
    }
}

extension KlarnaAuthorizeResolver: PrimerKlarnaProviderAuthorizationDelegate {
    func primerKlarnaWrapperAuthorized(approved: Bool, authToken: String?, finalizeRequired _: Bool) {
        guard approved, let authToken else { return resume(.error) }
        resume(.success, data: .object(["authorization_token": .string(authToken)]))
    }

    func primerKlarnaWrapperReauthorized(approved _: Bool, authToken _: String?) {
        // klarna.authorize never reauthorizes, so Klarna doesn't call this
    }

    private func resume(_ outcome: TerminalOutcome, data: CodableValue? = nil) {
        continuation?.resume(returning: StepResolutionResult(outcome: outcome, data: data))
        continuation = nil
        provider?.errorDelegate = widgetErrorDelegate
        provider = nil
    }
}

extension KlarnaAuthorizeResolver: PrimerKlarnaProviderErrorDelegate {
    func primerKlarnaWrapperFailed(with error: PrimerKlarnaError) {
        logger.error(message: "klarna.authorize failed: \(error.localizedDescription)")
        resume(.error)
    }
}

private extension KlarnaAuthorizeResolver {
    struct Params: Decodable {
        let category: String?
    }
}
#endif
