//
//  RequiredCapabilities.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public struct RequiredCapabilities: Equatable, Sendable, Decodable {
    public let steps: [String: Set<Int>]
    public let nodes: [String: Set<Int>]
    public let presentations: Set<String>

    private enum CodingKeys: String, CodingKey { case steps, nodes, presentations }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        steps = try container.decodeIfPresent([String: Set<Int>].self, forKey: .steps) ?? [:]
        nodes = try container.decodeIfPresent([String: Set<Int>].self, forKey: .nodes) ?? [:]
        presentations = try container.decodeIfPresent(Set<String>.self, forKey: .presentations) ?? []
    }
}
