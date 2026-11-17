//
//  FlowStep.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

@_spi(PrimerInternal)
public enum FlowStep: Decodable {
    case runAction(state: CodableState, layers: [RenderLayer], action: WorkflowStep, reply: EventReply?)
    case awaitInput(state: CodableState, layers: [RenderLayer], reply: EventReply?)
    case finished(outcome: TerminalOutcome, reply: EventReply?)
    case failed(error: StateProcessorError, reply: EventReply?)

    public var reply: EventReply? {
        switch self {
        case let .runAction(_, _, _, reply), let .awaitInput(_, _, reply), let .finished(_, reply), let .failed(_, reply): reply
        }
    }

    private enum CodingKeys: String, CodingKey {
        case kind, state, layers, action, outcome, error, reply
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let reply = try container.decodeIfPresent(EventReply.self, forKey: .reply)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "runAction":
            self = .runAction(
                state: try container.decode(CodableState.self, forKey: .state),
                layers: try container.decodeIfPresent([RenderLayer].self, forKey: .layers) ?? [],
                action: try container.decode(WorkflowStep.self, forKey: .action),
                reply: reply
            )
        case "awaitInput":
            self = .awaitInput(
                state: try container.decode(CodableState.self, forKey: .state),
                layers: try container.decodeIfPresent([RenderLayer].self, forKey: .layers) ?? [],
                reply: reply
            )
        case "finished":
            self = .finished(outcome: try container.decode(TerminalOutcome.self, forKey: .outcome), reply: reply)
        case "failed":
            self = .failed(error: try container.decode(StateProcessorError.self, forKey: .error), reply: reply)
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown flow step kind '\(kind)'")
        }
    }
}

@_spi(PrimerInternal)
public enum EventReply: Decodable, Equatable {
    case unhandled
    case handled(value: CodableValue?)
    case failed(message: String)

    private enum CodingKeys: String, CodingKey {
        case kind, value, error
    }

    private struct ReplyError: Decodable {
        let message: String
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let kind = try container.decode(String.self, forKey: .kind)
        switch kind {
        case "unhandled": self = .unhandled
        case "handled": self = .handled(value: try container.decodeIfPresent(CodableValue.self, forKey: .value))
        case "failed": self = .failed(message: try container.decode(ReplyError.self, forKey: .error).message)
        default:
            throw DecodingError.dataCorruptedError(forKey: .kind, in: container, debugDescription: "Unknown event reply kind '\(kind)'")
        }
    }
}

@_spi(PrimerInternal)
public struct RenderLayer: Decodable {
    public let stepId: String
    public let processedUI: CodableValue
}

public struct StateProcessorError: Decodable, LocalizedError {
    public let code: String
    public let message: String
    public let diagnosticsId: String

    public var errorDescription: String? {
        "State processor error [\(code)] (diagnosticsId=\(diagnosticsId)): \(message)"
    }
}
