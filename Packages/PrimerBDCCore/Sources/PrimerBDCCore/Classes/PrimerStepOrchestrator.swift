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
public final class PrimerStepOrchestrator: ObservableObject {
    private let logger = Logger()
    
    private let analyticsHandler: AnalyticsHandler
    private let urlOpenHandler: URLOpenHandler
    private let httpHandler: HTTPInteractionStepHandler
    private let sdkHandler: UIRenderStepHandler
    
    private let engine: PrimerBDCEngine
    private var rawSchema: String!
    private var state: CodableState = [:]
    
    public init(registry: PrimerStepResolverRegistry = .shared) {
        self.engine = PrimerBDCEngine()
        
        analyticsHandler = AnalyticsHandler(registry: registry)
        urlOpenHandler = URLOpenHandler(registry: registry)
        httpHandler = HTTPInteractionStepHandler(registry: registry)
        sdkHandler = UIRenderStepHandler(registry: registry, engine: engine)
        
        urlOpenHandler.delegate = self
        sdkHandler.delegate = self
    }
    
    public func start(rawSchema: String, initialState: CodableValue) async throws {
        let result = try await engine.start(schema: rawSchema, state: initialState)
        self.rawSchema = rawSchema
        try await decodeResult(result)
    }
    
    private func decodeResult(_ result: AnyDict) async throws {
        let response = try JSONDecoder().decode(StateProcessorResponse.self, from: try result.data())
        state = response.newState
        for workflowToRun in response.workflowsToRun {
            try await resolveNextStep(
                workflowToRun.currentStep,
                workflowId: workflowToRun.workflowId,
                result: result
            )
        }
    }
    
    private func resolveNextStep(_ step: WorkflowStep, workflowId: String, result: AnyDict) async throws {
        let response: CodableValue?
        switch step.type {
        case let .analytics(value):
            logger.info("Received instruction; executing analytics step")
            response = try await analyticsHandler.resolve(value)
        case let .httpCall(value):
            logger.info("Received instruction; executing http step")
            response = try await httpHandler.resolve(value)
        case let .urlOpen(value):
            logger.info("Received instruction; executing web view step")
            response = try await urlOpenHandler.resolve(value)
        case .uiRender:
            logger.info("Received instruction; executing rendering UI step")
            response = try await resolveUIRender(from: result)
        }
        
        let result = try await engine.applyWorkflowStepResponse(
            schema: rawSchema,
            state: state,
            workflowId: workflowId,
            stepId: step.stepId,
            response: response?.casted(to: Data.self)
        )
        
        try await decodeResult(result)
    }
    
    private func resolveUIRender(from result: AnyDict) async throws -> CodableValue? {
        guard let processedUI = result["processedUI"] as? AnyDict else { throw CastError.typeMismatch(value: result, type: AnyDict.self) }
        guard let ui = try processedUI.jsonString() else { return nil }
        return try await sdkHandler.resolve(ui: ui, rawSchema: rawSchema, state: state)
    }
}

extension PrimerStepOrchestrator: @MainActor UIRenderStepHandlerDelegate {
    func applyEventDidComplete(with result: AnyDict) async throws  {
        try await decodeResult(result)
    }
}

extension PrimerStepOrchestrator: @MainActor URLOpenDelegate {
    func urlOpenDidComplete() { applyOpenBrowserEvent(event: "completed") }
    func urlOpenDidCancel() { applyOpenBrowserEvent(event: "cancelled") }
    func urlOpenDidFail(with error: any Error) { /*TODO: Not implemented yet*/ }
    
    private func applyOpenBrowserEvent(event: String) {
        Task {
            let id = Event.custom(id: "openBrowser", value: event)
            let result = try await engine.applyEvent(id, schema: rawSchema, state: state)
            try await decodeResult(result)
        }
    }
}
