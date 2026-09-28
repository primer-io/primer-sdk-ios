//
//  StepCapability+Versions.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public extension StepCapability {
    /// The version of the step's contract this SDK implements.
    var version: String {
        switch self {
        case .httpRequest, .urlOpen, .platformLog: "1.0.0"
        }
    }

    static var declaredVersions: [String: String] {
        allCases.reduce(into: [:]) { $0[$1.rawValue] = $1.version }
    }
}
