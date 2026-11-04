//
//  KlarnaLoadResolver.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

struct KlarnaLoadResolver: StepResolver {
    @MainActor
    func resolve(_: CodableValue) async throws -> StepResolutionResult {
        guard let widget = KlarnaWidgetStore.shared.widget(for: nil), await widget.load() else {
            return StepResolutionResult(outcome: .error)
        }
        return StepResolutionResult(
            outcome: .success,
            data: .object(["category": .string(widget.category), "show_form": .bool(true)])
        )
    }
}
#endif
