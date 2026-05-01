//
//  MockStepOrchestrator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCCore
import PrimerFoundation

final class MockStepOrchestrator: StepOrchestrating {
    var onURLOpen: (() -> Void)?
    var onCancelled: (() -> Void)?
    var startCallCount = 0
    var startError: Swift.Error?

    func start(rawSchema: String, initialState: CodableValue) async throws {
        startCallCount += 1
        if let startError { throw startError }
    }
}
