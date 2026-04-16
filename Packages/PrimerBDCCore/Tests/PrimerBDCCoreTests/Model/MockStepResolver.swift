//
//  MockStepResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  MockStepResolver.swift
//  PrimerBDCCore
//
//  Created by Henry Cooper on 14/04/2026.
//
import PrimerFoundation
import PrimerStepResolver

final class MockStepResolver: StepResolver {
    nonisolated(unsafe) var resolveCallCount = 0

    func resolve(_ step: CodableValue) async throws -> StepResolutionResult {
        resolveCallCount += 1
        return StepResolutionResult(outcome: .success)
    }
}
