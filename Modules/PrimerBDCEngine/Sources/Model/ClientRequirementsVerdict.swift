//
//  ClientRequirementsVerdict.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public struct ClientRequirementsVerdict: Decodable, Equatable {
    public let satisfied: Bool
    public let unmet: [UnmetClientRequirement]

    public init(satisfied: Bool, unmet: [UnmetClientRequirement] = []) {
        self.satisfied = satisfied
        self.unmet = unmet
    }
}
