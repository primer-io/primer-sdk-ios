//
//  MockStepOrchestrator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerBDCCore
@_spi(PrimerInternal) import PrimerFoundation

final class MockStepOrchestrator: StepOrchestrating {
    var onURLOpen: (() -> Void)?
    var startCallCount = 0
    var startError: Swift.Error?
    var startedInitialStates: [CodableValue] = []
    var pollWakes = 0
    private(set) var pollWaits: [Int] = []

    func start(rawSchema: String, initialState: CodableValue) async throws {
        startCallCount += 1
        startedInitialStates.append(initialState)
        if let startError { throw startError }
    }
    
    func applyEvent(_ value: PrimerFoundation.CodableValue) async throws {}

    func waitToPoll(milliseconds: Int) async throws {
        pollWaits.append(milliseconds)
        guard pollWaits.count <= pollWakes else { throw CancellationError() }
    }

}
