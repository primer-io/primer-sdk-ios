//
//  UnmetClientRequirement.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public struct UnmetClientRequirement: Codable, Equatable {
    public let kind: String
    public let type: String?
    public let name: String
    public let required: String?
    public let available: String?
    public let reason: String

    public init(
        kind: String,
        type: String? = nil,
        name: String,
        required: String? = nil,
        available: String? = nil,
        reason: String
    ) {
        self.kind = kind
        self.type = type
        self.name = name
        self.required = required
        self.available = available
        self.reason = reason
    }
}
