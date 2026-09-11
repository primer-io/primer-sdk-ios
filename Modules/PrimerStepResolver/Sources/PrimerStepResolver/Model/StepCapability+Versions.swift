//
//  StepCapability+Versions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal)
public extension StepCapability {
    var version: SemanticVersion {
        switch self {
        case .httpRequest, .urlOpen, .platformLog: SemanticVersion(1, 0, 0)
        }
    }

    static var declaredVersions: [String: SemanticVersion] {
        allCases.reduce(into: [:]) { $0[$1.rawValue] = $1.version }
    }
}
