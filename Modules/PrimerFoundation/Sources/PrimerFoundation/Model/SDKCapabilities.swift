//
//  SDKCapabilities.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public struct SDKCapabilities: Equatable, Sendable, Encodable {
    public let steps: [String: SemanticVersion]
    public let nodes: [String: SemanticVersion]
    public let nativeModules: Set<String>

    private enum CodingKeys: String, CodingKey { case steps, nodes, nativeModules }

    public init(
        steps: [String: SemanticVersion] = [:],
        nodes: [String: SemanticVersion] = [:],
        nativeModules: Set<String> = []
    ) {
        self.steps = steps
        self.nodes = nodes
        self.nativeModules = nativeModules
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(steps.mapValues(\.description), forKey: .steps)
        try container.encode(nodes.mapValues(\.description), forKey: .nodes)
        try container.encode(nativeModules.sorted(), forKey: .nativeModules)
    }
}

@_spi(PrimerInternal)
public extension SDKCapabilities {
    func canExecute(_ required: RequiredCapabilities) -> Bool {
        satisfies(required.steps, with: steps)
            && satisfies(required.nodes, with: nodes)
            && required.nativeModules.allSatisfy(nativeModules.contains)
    }

    private func satisfies(
        _ required: [String: VersionRequirement],
        with declared: [String: SemanticVersion]
    ) -> Bool {
        required.allSatisfy { name, requirement in
            guard let version = declared[name] else { return false }
            return requirement.isSatisfied(by: version)
        }
    }
}
