//
//  EngineScriptRunning.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

@MainActor
protocol EngineScriptRunning: BDCEngineProtocol {
    func run(_ script: EngineScript) async throws -> Data
}

extension EngineScriptRunning {
    public func start(schema: String, context: SDKContext, state: CodableValue) async throws -> AnyDict {
        try await dictionary(from: .start(schema: schema, context: context, state: state))
    }

    public func applyEvent<State: Encodable>(
        _ event: CodableValue,
        context: SDKContext,
        schema: String,
        state: State
    ) async throws -> [String: Any] {
        try await dictionary(from: .applyEvent(event, context: context, schema: schema, state: state))
    }

    public func applyResult(
        schema: String,
        context: SDKContext,
        actionId: String,
        state: CodableState,
        outcome: String,
        data: Data?
    ) async throws -> AnyDict {
        try await dictionary(from: .applyResult(
            schema: schema,
            context: context,
            actionId: actionId,
            state: state,
            outcome: outcome,
            data: data
        ))
    }

    public func probesToRun(items: [PaymentMethodRequirements], client: BDCClient) async throws -> [ProbeRequest] {
        try await decoded(from: .probesToRun(items: items, client: client))
    }

    public func checkClientRequirements(
        items: [PaymentMethodRequirements],
        client: BDCClient,
        results: [String: ProbeResult]
    ) async throws -> ClientRequirementsVerdicts {
        try await decoded(from: .checkClientRequirements(items: items, client: client, results: results))
    }
}

private extension EngineScriptRunning {
    func dictionary(from script: EngineScript) async throws -> AnyDict {
        let json = try await run(script)
        guard let object = try? JSONSerialization.jsonObject(with: json) as? AnyDict else { throw EngineError.jsonToDataFailed }
        return object
    }

    func decoded<Value: Decodable>(from script: EngineScript) async throws -> Value {
        let json = try await run(script)
        let reply = try JSONDecoder().decode(ScriptResult<Value>.self, from: json)
        guard let value = reply.result else { throw EngineError.scriptFailed(reply.error ?? "No result") }
        return value
    }
}
