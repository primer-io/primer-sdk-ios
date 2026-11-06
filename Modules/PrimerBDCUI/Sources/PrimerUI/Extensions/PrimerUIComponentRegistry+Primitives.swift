//
//  PrimerUIComponentRegistry+Primitives.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerStepResolver

@_spi(PrimerInternal)
public extension PrimerUIComponentRegistry {
    func declarePrimitives() {
        for component in Component.ComponentType.allCases {
            declare(component.rawValue, version: Self.primitiveVersion) 
        }
    }
}

private extension PrimerUIComponentRegistry {
    static let primitiveVersion = "1.0.0"
}
