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
    
    public init(registry: PrimerStepResolverRegistry = .shared) {
        self.engine = PrimerBDCEngine()
        
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
            for workflowToRun in response.workflowsToRun {
                try await resolveNextStep(
                    workflowToRun.currentStep,
                    workflowId: workflowToRun.workflowId,
                    result: result
                )
            }
        } catch {
            throw PrimerStepOrchestratorError.decodeResultFailed(error: error)
        }
    }
    
    private func resolveNextStep(
        _ step: WorkflowStep,
        workflowId: String,
        result: AnyDict
    ) async throws {
        do {
            let response = try await resolveStepResponse(step)
            let workflowResult = try await applyWorkflowStepResponse(
                workflowId: workflowId,
                stepId: step.stepId,
                response: response
            )
            try await decodeResult(workflowResult)
        }
    }
    
    private func resolveStepResponse(_ step: WorkflowStep) async throws -> CodableValue? {
        do {
            switch step.type {
            case let .analytics(value):
                logger.info("Received instruction; executing analytics step")
                return try await analyticsHandler.resolve(value)
            case let .httpCall(value):
                logger.info("Received instruction; executing http step")
                return try await httpHandler.resolve(value)
            case let .urlOpen(value, eventContainer):
                logger.info("Received instruction; executing web view step")
                return try await urlOpenHandler.resolve(
                    value,
                    onClose: { [weak self] in
                        try await self?.applyOpenBrowserEvent(event: eventContainer.onClose)
                    },
                    onComplete: { [weak self] in
                        try await self?.applyOpenBrowserEvent(event: eventContainer.onComplete)
                    }
                )
            }
        } catch {
            throw PrimerStepOrchestratorError.resolvingFailed(error: error)
        }
    }
    
    private func applyWorkflowStepResponse(
        workflowId: String,
        stepId: String,
        response: CodableValue?
    ) async throws -> [String: Any] {
        do {
            return try await engine.applyWorkflowStepResponse(
                schema: rawSchema,
                state: state,
                workflowId: workflowId,
                stepId: stepId,
                response: response?.casted(to: Data.self)
            )
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

private enum PrimerStepOrchestratorError: LocalizedError {
    case startFailed(error: Error)
    case decodeResultFailed(error: Error)
    case resolvingFailed(error: Error)
    case applyWorkflowStepResponseFailed(error: Error)
}
