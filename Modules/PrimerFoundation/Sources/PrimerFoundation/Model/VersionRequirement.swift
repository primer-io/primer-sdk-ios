//
//  VersionRequirement.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public enum VersionRequirement: Equatable, Sendable {
    case caret(SemanticVersion)
    case unrecognised(String)

    public init(_ string: String) {
        guard string.hasPrefix("^"), let minimum = SemanticVersion(String(string.dropFirst())) else {
            self = .unrecognised(string)
            return
        }
        self = .caret(minimum)
    }

    public func isSatisfied(by version: SemanticVersion) -> Bool {
        guard case let .caret(minimum) = self else { return false }
        return version >= minimum && version < Self.exclusiveUpperBound(for: minimum)
    }

    private static func exclusiveUpperBound(for version: SemanticVersion) -> SemanticVersion {
        if version.major > 0 { return SemanticVersion(version.major + 1, 0, 0) }
        if version.minor > 0 { return SemanticVersion(0, version.minor + 1, 0) }
        return SemanticVersion(0, 0, version.patch + 1)
    }
}
