//
//  AnalyticsService+BDC.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation
import PrimerStepResolver

extension Analytics.Service: StepResolver {
    func resolve(_ step: CodableValue) async throws -> StepResolutionResult {
        fire(event: RawAnalyticsEvent(payload: step))
        return StepResolutionResult(outcome: .success)
    }
}
