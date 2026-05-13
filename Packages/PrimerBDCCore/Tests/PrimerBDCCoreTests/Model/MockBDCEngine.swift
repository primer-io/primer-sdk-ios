//
//  MockBDCEngine.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation

@MainActor
final class MockBDCEngine: BDCEngineProtocol {
    var startResult: [String: Any] = [:]
    var startError: Error?
    var applyResultResult: [String: Any] = [:]
    var applyResultCallCount = 0
    var lastApplyOutcome: String?

    func start(
        schema: String,
        context: SDKContext,
        state: CodableValue
    ) async throws -> [String: Any] {
        if let startError { throw startError }
        return startResult
    }

    func applyResult(
        schema: String,
        context: SDKContext,
        actionId: String,
        state: CodableState,
        outcome: String,
        data: Data?
    ) async throws -> [String: Any] {
        applyResultCallCount += 1
        lastApplyOutcome = outcome
        return applyResultResult
    }
}
