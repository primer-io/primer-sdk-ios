//
//  StepCapability.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@_spi(PrimerInternal)
public enum StepCapability: String, CaseIterable, Sendable {
    case httpRequest = "http.request"
    case urlOpen = "url.open"
    case platformLog = "platform.log"
}

@_spi(PrimerInternal)
public extension PrimerStepResolverRegistry {
    func register(_ resolver: StepResolver, for capability: StepCapability) {
        register(resolver, for: capability.rawValue)
    }
}
