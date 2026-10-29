//
//  PrimerUIComponentRegistry.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public actor PrimerUIComponentRegistry {
    public static let shared = PrimerUIComponentRegistry()

    public private(set) var declaredVersions: [String: String] = [:]

    public init() {}

    public func declare(_ type: String, version: String) {
        declaredVersions[type] = version
    }
}
