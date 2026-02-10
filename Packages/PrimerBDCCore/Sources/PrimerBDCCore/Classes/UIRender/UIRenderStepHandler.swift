//
//  UIRenderStepHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerBDCEngine
import PrimerFoundation
import PrimerStepResolver

@MainActor
final class UIRenderStepHandler: StepResolver {
    weak var delegate: UIRenderStepHandlerDelegate?
    private typealias WorkflowStepHandler = (any SDKWorkflowStepHandler)
    private let registry: PrimerStepResolverRegistry
    private let engine: PrimerBDCEngine
    private var state: CodableState = [:]
    private var workflowStepHandler: WorkflowStepHandler!
    
    init(registry: PrimerStepResolverRegistry, engine: PrimerBDCEngine) {
        self.registry = registry
        self.engine = engine
    }
    
    public func resolve(_ step: CodableValue) async throws -> CodableValue? {
        let workflowStep = try step.casted(to: AnyUIRenderWorkflowStep.self)
        return switch workflowStep.type {
        case .navigate: try await workflowStepHandler.resolve(step)
        }
    }
    
    func resolve(ui: String, rawSchema: String, state: CodableState) async throws -> CodableValue? {
        let handler = try await registry.resolver(for: .uiRender) as! WorkflowStepHandler
        handler.initialScreenID = "initialScreenID" //TODO: Not necessary at this point
        handler.state = state
        handler.callback = { [weak self] callback in try await self?.handleCallback(callback, schema: rawSchema) }
        self.workflowStepHandler = handler
        handler.updateUITree?(try ui.jsonObject())
        return nil
    }
    
    private func handleCallback(_ callback: SDKWorkflowCallback, schema: String) async throws {
        switch callback {
        case let .left(applyEvent):
            try await self.applyEvent(applyEvent, schema: schema, initialScreenID: "first") //TODO:
        case .right:
            break //TODO: Not necessary at this point
        }
    }
    
    private func applyEvent(_ callback: ApplyEventCallback, schema: String, initialScreenID: String) async throws {
        let event = callback.event
        let screenId = callback.screenId
        let result = try await engine.applyEvent(event, schema: schema, screenId: screenId, state: callback.state)
        workflowStepHandler?.state = try CodableState(result["newState"] as! AnyDict)
        workflowStepHandler?.updateUITree?(result["processedUI"] as! AnyDict)
        try await delegate?.applyEventDidComplete(with: result)
    }
}

protocol UIRenderStepHandlerDelegate: AnyObject {
    @MainActor func applyEventDidComplete(with result: AnyDict) async throws
}

private enum UIRenderWorkflowType: String, Decodable {
    case navigate
}

private struct AnyUIRenderWorkflowStep: UIRenderWorkflowStep {
    let type: UIRenderWorkflowType
}

private protocol UIRenderWorkflowStep: Decodable {
    var type: UIRenderWorkflowType { get }
}
