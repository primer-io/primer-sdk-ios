//
//  SDKCapabilities+Current.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

extension SDKCapabilities {
    static func current(
        uiComponents: PrimerUIComponentRegistry = .shared,
        probes: PrimerProbeRegistry = .shared
    ) async -> SDKCapabilities {
        await SDKCapabilities(
            stepTypes: StepCapability.declaredVersions,
            uiComponents: uiComponents.declaredVersions,
            probes: probes.declaredVersions
        )
    }
}
