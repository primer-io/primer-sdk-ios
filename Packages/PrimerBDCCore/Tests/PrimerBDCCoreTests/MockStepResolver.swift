//
//  MockStepResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerStepResolver

final class MockStepResolver: StepResolver, @unchecked Sendable {
    var resolveCalled = false
    var result: CodableValue?

    func resolve(_ step: CodableValue) async throws -> CodableValue? {
        resolveCalled = true
        return result
    }
}
