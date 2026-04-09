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
public final class PrimerStepOrchestrator {
    public var onCancelled: (() -> Void)?

    private let logger = Logger()
    
    private let analyticsHandler: AnalyticsHandler
    private let urlOpenHandler: URLOpenHandler
    private let httpHandler: HTTPInteractionStepHandler
    
    private let engine: PrimerBDCEngine
    private let context: SDKContext
    private var rawSchema: String!
    private var state: CodableState = [:]
        
    public init(
        manifest: Manifest,
        context: SDKContext,
        registry: PrimerStepResolverRegistry = .shared
    ) {
        self.engine = PrimerBDCEngine(manifest: manifest)
        self.context = context
        analyticsHandler = AnalyticsHandler(registry: registry)
        urlOpenHandler = URLOpenHandler()
        httpHandler = HTTPInteractionStepHandler(registry: registry)
    }

    public func start(rawSchema: String, initialState: CodableValue) async throws {
        do {
            let result = try await engine.start(schema: rawSchema, context: context, state: initialState)
            self.rawSchema = rawSchema
            try await decodeResult(result)
        } catch {
            throw PrimerStepOrchestratorError.startFailed(error: error)
        }
    }
    
    private func decodeResult(_ result: AnyDict) async throws {
        do {
            let response = try JSONDecoder().decode(StateProcessorResponse.self, from: try result.data())
            state = response.newState
            if let next = response.action {
                try await resolveStepResponse(next) { [weak self] in try await self?.applyResult($0) }
            } else if let outcome = response.terminal?.outcome {
                switch outcome {
                case .cancelled: onCancelled?()
                case .unsupported, .error: throw PrimerStepOrchestratorError.receivedUnexpectedTerminalOutcome(outcome: outcome)
                case .success: break
                }
            }
        } catch {
            throw PrimerStepOrchestratorError.decodeResultFailed(error: error)
        }
    }
    
    private func resolveStepResponse(
        _ step: WorkflowStep,
        completion: @escaping (StepResponse) async throws -> Void
    ) async throws {
        do {
            switch step.type {
            case let .log(value):
                logger.info("Received instruction; executing log step")
                try await attemptResolution(
                    actionId: step.id,
                    resolutionHandler: { try await analyticsHandler.resolve(value) },
                    completion: completion
                )
                
            case let .httpCall(value):
                logger.info("Received instruction; executing http step")
                try await attemptResolution(
                    actionId: step.id,
                    resolutionHandler: { try await httpHandler.resolve(value) },
                    completion: completion
                )
            case let .urlOpen(value):
                logger.info("Received instruction; executing web view step")
                
                do {
                    let response = try await urlOpenHandler.resolve(value)

                    urlOpenHandler.onClose = {
                        try await completion(StepResponse(outcome: .cancelled, data: response, actionId: step.id))
                    }
                    
                    urlOpenHandler.onComplete = {
                        try await completion(StepResponse(outcome: .success, data: response, actionId: step.id))
                    }
                } catch {
                    try await handle(error, actionId: step.id, completion: completion)
                }
            }
        } catch {
            throw PrimerStepOrchestratorError.resolvingFailed(error: error)
        }
    }
    
    private func attemptResolution(
        actionId: String,
        resolutionHandler: () async throws -> CodableValue?,
        completion: @escaping (StepResponse) async throws -> Void
    ) async throws {
        do {
            let response = try await resolutionHandler()
            try await completion(StepResponse(outcome: .success, data: response, actionId: actionId))
        } catch {
           try await handle(error, actionId: actionId, completion: completion)
        }
    }
    
    private func handle(
        _ error: Error,
        actionId: String,
        completion: @escaping (StepResponse) async throws -> Void
    ) async throws {
        if let error = error as? PrimerStepResolver.StepResolutionError, error == .noResolverFound {
           try await completion(StepResponse(outcome: .unsupported, data: nil, actionId: actionId))
        } else {
            throw error
        }
    }
    
    private func applyResult(_ response: StepResponse) async throws {
        do {
            let data = try response.data?.casted(to: Data.self)
            let outcome = response.outcome.rawValue
            let result = try await engine.applyResult(
                schema: rawSchema,
                context: context,
                actionId: response.actionId,
                state: state,
                outcome: outcome,
                data: data
            )
            try await decodeResult(result)
        } catch {
            throw PrimerStepOrchestratorError.applyWorkflowStepResponseFailed(error: error)
        }
    }
}

extension PrimerStepOrchestrator {
    private func applyOpenBrowserEvent(event: CodableValue) async throws {
        let result = try await engine.applyEvent(event, context: context, schema: rawSchema, state: state)
        try await decodeResult(result)
    }
}

private struct StepResponse {
    let outcome: TerminalOutcome
    let data: CodableValue?
    let actionId: String
}

private enum PrimerStepOrchestratorError: LocalizedError {
    case startFailed(error: Error)
    case decodeResultFailed(error: Error)
    case resolvingFailed(error: Error)
    case applyWorkflowStepResponseFailed(error: Error)
    case receivedUnexpectedTerminalOutcome(outcome: TerminalOutcome)
}
