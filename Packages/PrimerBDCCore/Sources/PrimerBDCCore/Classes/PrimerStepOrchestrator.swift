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
    var onCancelled: (() -> Void)? { get set }
    func start(rawSchema: String, initialState: CodableValue) async throws
}

@MainActor
final class PrimerStepOrchestrator: StepOrchestrating {
    var onCancelled: (() -> Void)?

    private let logger = Logger()
    
    private let analyticsHandler: AnalyticsHandler
    private let urlOpenHandler: URLOpenHandler
    private let httpHandler: HTTPInteractionStepHandler
    
    private let engine: any BDCEngineProtocol
    private let context: SDKContext
    private var state: CodableState = [:]
        
    init(
        engine: any BDCEngineProtocol,
        context: SDKContext,
        registry: PrimerStepResolverRegistry = .shared
    ) {
        self.engine = engine
        self.context = context
        analyticsHandler = AnalyticsHandler(registry: registry)
        urlOpenHandler = URLOpenHandler()
        httpHandler = HTTPInteractionStepHandler(registry: registry)
    }

    func start(rawSchema: String, initialState: CodableValue) async throws {
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
            if let error = response.error {
                throw error
            } else if let next = response.action {
                try await resolveStepResponse(next) { [weak self] in
                    try await self?.applyResult($0, rawSchema: rawSchema)
                }
            } else if let outcome = response.terminal?.outcome {
                switch outcome {
                case .cancelled: onCancelled?()
                case .error: throw PrimerStepOrchestratorError.checkoutTerminalError
                case .unsupported: throw PrimerStepOrchestratorError.receivedUnexpectedTerminalOutcome(outcome: outcome)
                case .success: break
                }
            } else {
                throw PrimerStepOrchestratorError.missingActionAndOutcome
            }
        } catch {
            if let error = error as? StateProcessorError {
                throw error
            } else {
                throw PrimerStepOrchestratorError.decodeResultFailed(error: error)
            }
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
    
    private func applyResult(_ response: StepResponse, rawSchema: String) async throws {
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
            try await decodeResult(result, rawSchema: rawSchema)
        } catch {
            throw PrimerStepOrchestratorError.applyWorkflowStepResponseFailed(error: error)
        }
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
    case checkoutTerminalError
    case missingActionAndOutcome

    var errorDescription: String? {
        switch self {
        case let .startFailed(error): "Start failed: \(error.localizedDescription)"
        case let .decodeResultFailed(error): "Decode result failed: \(error.localizedDescription)"
        case let .resolvingFailed(error): "Resolving failed: \(error.localizedDescription)"
        case let .applyWorkflowStepResponseFailed(error): "Apply workflow step response failed: \(error.localizedDescription)"
        case let .receivedUnexpectedTerminalOutcome(outcome): "Received unexpected terminal outcome: \(outcome)"
        case .checkoutTerminalError: "Checkout ended with an error outcome."
        case .missingActionAndOutcome: "Processing result has no action nor outcome."
        }
    }
}
