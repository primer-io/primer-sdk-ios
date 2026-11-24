//
//  EngineScript.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

struct EngineScript {
    let body: String
    let arguments: [String: String]
}

extension EngineScript {
    static func start(schema: String, context: SDKContext, state: CodableValue) throws -> EngineScript {
        let encoder = JSONEncoder()
        return EngineScript(
            body: """
            try {
                const processor = await StateProcessor.createStateProcessor(schema, JSON.parse(context));
                const result = await processor.initialize(JSON.parse(state));
                return JSON.stringify(result);
            } catch (e) {
                return JSON.stringify({ error: e.toString() });
            }
            """,
            arguments: [
                "schema": schema,
                "context": try context.literal(encoder),
                "state": try state.literal(encoder)
            ]
        )
    }

    static func applyEvent<State: Encodable>(
        _ event: CodableValue,
        context: SDKContext,
        schema: String,
        state: State
    ) throws -> EngineScript {
        let encoder = JSONEncoder()
        return EngineScript(
            body: """
            try {
                const processor = await StateProcessor.createStateProcessor(schema, JSON.parse(context));
                const result = await processor.applyEvent(JSON.parse(state), JSON.parse(event));
                return JSON.stringify(result);
            } catch (e) {
                return JSON.stringify({ error: e.toString() });
            }
            """,
            arguments: [
                "schema": schema,
                "context": try context.literal(encoder),
                "state": try state.literal(encoder),
                "event": try event.jsonString
            ]
        )
    }

    static func applyResult(
        schema: String,
        context: SDKContext,
        actionId: String,
        state: CodableState,
        outcome: String,
        data: Data?
    ) throws -> EngineScript {
        let encoder = JSONEncoder()
        return EngineScript(
            body: """
            try {
                const processor = await StateProcessor.createStateProcessor(schema, JSON.parse(context));
                const result = await processor.applyResult(JSON.parse(state), actionId, outcome, JSON.parse(data));
                return JSON.stringify(result);
            } catch (e) {
                return JSON.stringify({ error: e.toString() });
            }
            """,
            arguments: [
                "schema": schema,
                "context": try context.literal(encoder),
                "actionId": actionId,
                "state": try state.literal(encoder),
                "outcome": outcome,
                "data": data.flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
            ]
        )
    }

    static func probesToRun(items: [PaymentMethodRequirements], client: BDCClient) throws -> EngineScript {
        let encoder = JSONEncoder()
        return EngineScript(
            body: """
            try {
                if (typeof StateProcessor.probesToRun !== 'function') {
                    return JSON.stringify({ result: [] });
                }
                const result = await StateProcessor.probesToRun(JSON.parse(items), JSON.parse(client));
                return JSON.stringify({ result });
            } catch (e) {
                return JSON.stringify({ error: e.toString() });
            }
            """,
            arguments: [
                "items": try items.literal(encoder),
                "client": try client.literal(encoder)
            ]
        )
    }

    static func checkClientRequirements(
        items: [PaymentMethodRequirements],
        client: BDCClient,
        results: [String: ProbeResult]
    ) throws -> EngineScript {
        let encoder = JSONEncoder()
        return EngineScript(
            body: """
            try {
                const parsedClient = JSON.parse(client);
                const parsedResults = JSON.parse(results);
                const result = {};
                for (const item of JSON.parse(items)) {
                    result[item.id] = await StateProcessor.checkClientRequirements(item.clientRequirements, parsedClient, parsedResults);
                }
                return JSON.stringify({ result });
            } catch (e) {
                return JSON.stringify({ error: e.toString() });
            }
            """,
            arguments: [
                "items": try items.literal(encoder),
                "client": try client.literal(encoder),
                "results": try results.literal(encoder)
            ]
        )
    }
}

struct ScriptResult<Value: Decodable>: Decodable {
    let result: Value?
    let error: String?
}

extension Encodable {
    func literal(_ encoder: JSONEncoder) throws -> String {
        guard let literal = String(data: try encoder.encode(self), encoding: .utf8) else {
            throw EncodableError.literalEncodingFailed
        }
        return literal
    }
}

enum EncodableError: Error {
    case literalEncodingFailed
}
