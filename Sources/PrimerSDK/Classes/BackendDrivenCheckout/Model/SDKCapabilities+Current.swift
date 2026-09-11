//
//  SDKCapabilities+Current.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

extension SDKCapabilities {
    static let current = SDKCapabilities(
        steps: StepCapability.allCases.reduce(into: [:]) { result, capability in
            result[capability.rawValue] = capability.supportedVersions
        }
    )
}
