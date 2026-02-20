//
//  UIRenderStepHandler.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import PrimerBDCEngine
import PrimerFoundation
import PrimerStepResolver

protocol UIRenderStepHandlerDelegate: @MainActor AnyObject {
    func applyEventDidComplete(with result: AnyDict) async throws
}

@MainActor
final class UIRenderStepHandler {
    weak var delegate: UIRenderStepHandlerDelegate?
    
    private typealias WorkflowStepHandler = (any SDKWorkflowStepHandler)
    
    private let registry: PrimerStepResolverRegistry
    private let engine: PrimerBDCEngine
    private var state: CodableState = [:]
    private var workflowStepHandler: WorkflowStepHandler?
    
    init(registry: PrimerStepResolverRegistry, engine: PrimerBDCEngine) {
        self.registry = registry
        self.engine = engine
    }
    
    func resolve(ui: String, rawSchema: String, state: CodableState) async throws -> CodableValue? {
        let handler = try await registry.resolver(for: .uiRender)
        guard let handler = handler as? WorkflowStepHandler else { throw Error.unexpectedResolver }
        handler.state = state
        handler.callback = { [weak self] callback in try await self?.handleCallback(callback, schema: rawSchema) }
        self.workflowStepHandler = handler
        handler.updateUITree?(try ui.jsonObject())
        return nil
    }
    
    private func handleCallback(_ callback: ApplyEventCallback, schema: String) async throws {
        try await self.applyEvent(callback, schema: schema)
    }
    
    private func applyEvent(_ callback: ApplyEventCallback, schema: String) async throws {
        let event = callback.event
        let screenId = callback.screenId
        let result = try await engine.applyEvent(event, schema: schema, screenId: screenId, state: callback.state)
        
        guard let newState = result["newState"] as? AnyDict else {
            throw CastError.typeMismatch(value: result["newState"], type: AnyDict.self)
        }
        guard let ui = result["processedUI"] as? AnyDict else {
            throw CastError.typeMismatch(value: result["processedUI"], type: AnyDict.self)
        }
        
        workflowStepHandler?.state = try CodableState(newState)
        workflowStepHandler?.updateUITree?(ui)
        
        try await delegate?.applyEventDidComplete(with: result)
    }
}

private extension UIRenderStepHandler {
    private enum Error: Swift.Error {
        case unexpectedResolver
    }
}
