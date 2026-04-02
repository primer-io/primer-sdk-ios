//
//  MockBDCEngine.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  MockBDCEngine.swift
//  PrimerBDCCore
//
//  Created by Henry Cooper on 02/04/2026.
//
import Foundation
@testable import PrimerBDCCore
import PrimerFoundation

@MainActor
final class MockBDCEngine: BDCEngineProtocol {
    var startResult: AnyDict = [:]
    var startError: Error?
    var applyResultResult: AnyDict = [:]
    var applyEventResult: AnyDict = [:]

    var lastStartSchema: String?
    var lastApplyResultActionId: String?
    var lastApplyResultState: CodableState?

    func start(
        schema: String,
        context: SDKContext,
        state: CodableValue
    ) async throws -> AnyDict {
        lastStartSchema = schema
        if let startError { throw startError }
        return startResult
    }

    func applyResult(
        schema: String,
        actionId: String,
        state: CodableState,
        outcome: String,
        data: Data?
    ) async throws -> AnyDict {
        lastApplyResultActionId = actionId
        lastApplyResultState = state
        return applyResultResult
    }

    func applyEvent(
        _ event: CodableValue,
        schema: String,
        state: CodableState
    ) async throws -> AnyDict {
        applyEventResult
    }
}
