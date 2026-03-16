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
    private let logger = Logger()
    
    private let analyticsHandler: AnalyticsHandler
    private let urlOpenHandler: URLOpenHandler
    private let httpHandler: HTTPInteractionStepHandler
    
    private let engine: PrimerBDCEngine
    private var rawSchema: String!
    private var state: CodableState = [:]
    
    public init(manifest: Manifest, registry: PrimerStepResolverRegistry = .shared) {
        self.engine = PrimerBDCEngine(manifest: manifest)
        
        analyticsHandler = AnalyticsHandler(registry: registry)
        urlOpenHandler = URLOpenHandler()
        httpHandler = HTTPInteractionStepHandler(registry: registry)
    }
    
    public func start(rawSchema: String, initialState: CodableValue) async throws {
        do {
            let result = try await engine.start(schema: rawSchema, state: initialState)
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
            if let next = response.nextToExecute {
                try await resolveStepResponse(next, completion: applyResult)
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
                let response = try await analyticsHandler.resolve(value)
                try await completion(StepResponse(outcome: .success, data: response))
            case let .httpCall(value):
                logger.info("Received instruction; executing http step")
                let response = try await httpHandler.resolve(value)
                try await completion(StepResponse(outcome: .success, data: response))
            case let .urlOpen(value):
                logger.info("Received instruction; executing web view step")
                let response = try await urlOpenHandler.resolve(value)
                
                urlOpenHandler.onClose = { [weak self] in
                    try await completion(StepResponse(outcome: .cancelled, data: response))
                }
                
                urlOpenHandler.onComplete = { [weak self] in
                    try await completion(StepResponse(outcome: .success, data: response))
                }
            }
        } catch {
            throw PrimerStepOrchestratorError.resolvingFailed(error: error)
        }
    }
    
    private func applyResult(_ response: StepResponse) async throws{
        do {
            let data = try response.data?.casted(to: Data.self)
            let outcome = response.outcome.rawValue
            let result = try await engine.applyResult(schema: rawSchema, state: state, outcome: outcome, data: data)
            try await decodeResult(result)
        } catch {
            throw PrimerStepOrchestratorError.applyWorkflowStepResponseFailed(error: error)
        }
    }
}

extension PrimerStepOrchestrator {
    private func applyOpenBrowserEvent(event: CodableValue) async throws {
        let result = try await engine.applyEvent(event, schema: rawSchema, state: state)
        try await decodeResult(result)
    }
}

private struct StepResponse {
    let outcome: TerminalOutcome
    let data: CodableValue?
}

private enum PrimerStepOrchestratorError: LocalizedError {
    case startFailed(error: Error)
    case decodeResultFailed(error: Error)
    case resolvingFailed(error: Error)
    case applyWorkflowStepResponseFailed(error: Error)
}
