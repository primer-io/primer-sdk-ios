//
//  RequiredCapabilities.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public struct RequiredCapabilities: Equatable, Sendable, Decodable {
    public let steps: [String: VersionRequirement]
    public let nodes: [String: VersionRequirement]
    public let nativeModules: [String]

    private enum CodingKeys: String, CodingKey { case steps, nodes, nativeModules }

    public init(
        steps: [String: VersionRequirement] = [:],
        nodes: [String: VersionRequirement] = [:],
        nativeModules: [String] = []
    ) {
        self.steps = steps
        self.nodes = nodes
        self.nativeModules = nativeModules
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        steps = try Self.requirements(in: container, forKey: .steps)
        nodes = try Self.requirements(in: container, forKey: .nodes)
        nativeModules = try container.decodeIfPresent([String].self, forKey: .nativeModules) ?? []
    }

    private static func requirements(
        in container: KeyedDecodingContainer<CodingKeys>,
        forKey key: CodingKeys
    ) throws -> [String: VersionRequirement] {
        try container.decodeIfPresent([String: String].self, forKey: key)?
            .mapValues(VersionRequirement.init) ?? [:]
    }
}
