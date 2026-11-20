//
//  KlarnaAuthorizeResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
@_spi(PrimerInternal) import PrimerFoundation
import PrimerKlarnaSDK
@_spi(PrimerInternal) import PrimerStepResolver

final class KlarnaAuthorizeResolver: NSObject, StepResolver, LogReporter {
    private nonisolated(unsafe) var continuation: CheckedContinuation<StepResolutionResult, Never>?
    private nonisolated(unsafe) var provider: PrimerKlarnaProviding?
    private nonisolated(unsafe) weak var widgetErrorDelegate: PrimerKlarnaProviderErrorDelegate?

    @MainActor
    func resolve(_ data: CodableValue) async throws -> StepResolutionResult {
        let params = (try? data.casted(to: KlarnaAuthorizeParams.self)) ?? KlarnaAuthorizeParams()
        guard let provider = KlarnaProviderStore.shared.provider(for: params.instanceId ?? params.category) else {
            return StepResolutionResult(outcome: .error)
        }
        provider.authorizationDelegate = self
        widgetErrorDelegate = provider.errorDelegate
        provider.errorDelegate = self
        self.provider = provider

        return await withCheckedContinuation { continuation in
            self.continuation = continuation
            provider.authorize(autoFinalize: params.autoFinalize, jsonData: params.sessionData)
        }
    }
}

extension KlarnaAuthorizeResolver: PrimerKlarnaProviderAuthorizationDelegate {
    func primerKlarnaWrapperAuthorized(approved: Bool, authToken: String?, finalizeRequired: Bool) {
        var answer: [String: CodableValue] = ["approved": .bool(approved), "show_form": .bool(true)]
        if approved, let authToken { answer["authorization_token"] = .string(authToken) }
        if approved, finalizeRequired { answer["finalize_required"] = .bool(true) }
        resume(.success, data: .object(answer))
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
        resume(.success, data: .object([
            "approved": .bool(false),
            "show_form": .bool(true),
            "error": .object(["code": .string(error.errorId), "message": .string(error.localizedDescription)])
        ]))
    }
}

struct KlarnaAuthorizeParams: Decodable {
    let instanceId: String?
    let category: String?
    let sessionData: String?
    let autoFinalize: Bool

    init() {
        instanceId = nil
        category = nil
        sessionData = nil
        autoFinalize = true
    }

    private enum CodingKeys: String, CodingKey {
        case instanceId, category, data, options
    }

    private struct Options: Decodable {
        let autoFinalize: Bool?

        private enum CodingKeys: String, CodingKey {
            case autoFinalize = "auto_finalize"
        }
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        instanceId = try container.decodeIfPresent(String.self, forKey: .instanceId).flatMap { $0.isEmpty ? nil : $0 }
        category = try container.decodeIfPresent(String.self, forKey: .category).flatMap { $0.isEmpty ? nil : $0 }
        if case let .object(fields) = try container.decodeIfPresent(CodableValue.self, forKey: .data), !fields.isEmpty {
            sessionData = try CodableValue.object(fields).jsonString
        } else {
            sessionData = nil
        }
        autoFinalize = try container.decodeIfPresent(Options.self, forKey: .options)?.autoFinalize ?? true
    }
}
#endif
