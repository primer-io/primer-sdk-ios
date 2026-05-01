//
//  PrimerStepOrchestrator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerBDCEngine
import PrimerFoundation
import PrimerStepResolver

@MainActor
protocol StepOrchestrating: AnyObject {
    var onURLOpen: (() -> Void)? { get set }
    var onCancelled: (() -> Void)? { get set }
    func start(rawSchema: String, initialState: CodableValue) async throws
}

@MainActor
final class PrimerStepOrchestrator: StepOrchestrating {
    
    var onURLOpen: (() -> Void)? {
        didSet { harness.onURLOpen = onURLOpen }
    }
    
    var onCancelled: (() -> Void)?

    private let logger = Logger()
    private let engine: any BDCEngineProtocol
    private let context: SDKContext
    private let registry: PrimerStepResolverRegistry
    private let harness = SFSafariViewControllerHarness()
    private var state: CodableState = [:]

    init(
        engine: any BDCEngineProtocol,
        context: SDKContext,
        registry: PrimerStepResolverRegistry = .shared
    ) {
        self.engine = engine
        self.context = context
        self.registry = registry
    }

    func start(rawSchema: String, initialState: CodableValue) async throws {
        await registry.register(harness, for: "url.open")
        do {
            let result = try await engine.start(schema: rawSchema, context: context, state: initialState)
            try await decodeResult(result, rawSchema: rawSchema)
        } catch {
            throw PrimerStepOrchestratorError.startFailed(error: error)
        }
    }

    private func decodeResult(_ result: AnyDict, rawSchema: String) async throws {
        do {
            let response = try JSONDecoder().decode(StateProcessorResponse.self, from: try result.data())
            state = response.newState
            try await handleResponse(response, rawSchema: rawSchema)
        } catch {
            if let error = error as? StateProcessorError {
                throw error
            } else {
                throw PrimerStepOrchestratorError.decodeResultFailed(error: error)
            }
        }
    }
    
    private func handleResponse(_ response: StateProcessorResponse, rawSchema: String) async throws {
        if let error = response.error {
            throw error
        } else if let action = response.action {
            try await handleAction(action, rawSchema: rawSchema)
        } else if let outcome = response.terminal?.outcome {
            try handleOutcome(outcome)
        } else {
            throw PrimerStepOrchestratorError.missingActionAndOutcome
        }
    }
    
    private func handleAction(_ action: WorkflowStep, rawSchema: String) async throws {
        let resolution = try await registry.resolve(action.type, params: action.params)
        try await applyResult(resolution, actionId: action.id, rawSchema: rawSchema)
    }
    
    private func handleOutcome(_ outcome: TerminalOutcome) throws {
        switch outcome {
        case .cancelled: onCancelled?()
        case .error: throw PrimerStepOrchestratorError.checkoutTerminalError
        case .unsupported: throw PrimerStepOrchestratorError.receivedUnexpectedTerminalOutcome(outcome: outcome)
        case .success: break
        }
    }

    private func applyResult(_ resolution: StepResolutionResult, actionId: String, rawSchema: String) async throws {
        do {
            let data = try resolution.data?.casted(to: Data.self)
            let result = try await engine.applyResult(
                schema: rawSchema,
                context: context,
                actionId: actionId,
                state: state,
                outcome: resolution.outcome.rawValue,
                data: data
            )
            try await decodeResult(result, rawSchema: rawSchema)
        } catch {
            throw PrimerStepOrchestratorError.applyWorkflowStepResponseFailed(error: error)
        }
    }
}

private enum PrimerStepOrchestratorError: LocalizedError {
    case startFailed(error: Error)
    case decodeResultFailed(error: Error)
    case applyWorkflowStepResponseFailed(error: Error)
    case receivedUnexpectedTerminalOutcome(outcome: TerminalOutcome)
    case checkoutTerminalError
    case missingActionAndOutcome

    var errorDescription: String? {
        switch self {
        case let .startFailed(error): "Start failed: \(error.localizedDescription)"
        case let .decodeResultFailed(error): "Decode result failed: \(error.localizedDescription)"
        case let .applyWorkflowStepResponseFailed(error): "Apply workflow step response failed: \(error.localizedDescription)"
        case let .receivedUnexpectedTerminalOutcome(outcome): "Received unexpected terminal outcome: \(outcome)"
        case .checkoutTerminalError: "Checkout ended with an error outcome."
        case .missingActionAndOutcome: "Processing result has no action nor outcome."
        }
    }
}
