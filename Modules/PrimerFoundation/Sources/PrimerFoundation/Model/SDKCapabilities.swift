//
//  SDKCapabilities.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public struct SDKCapabilities: Equatable, Sendable, Encodable {
    public let steps: [String: Set<Int>]
    public let nodes: [String: Set<Int>]
    public let presentations: Set<String>
  
    private enum CodingKeys: String, CodingKey {
        case steps
        case nodes
        case presentations
    }

    public init(
        steps: [String: Set<Int>] = [:],
        nodes: [String: Set<Int>] = [:],
        presentations: Set<String> = []
    ) {
        self.steps = steps
        self.nodes = nodes
        self.presentations = presentations
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(steps.mapValues( { $0.sorted() }), forKey: .steps)
        try container.encode(nodes.mapValues { $0.sorted() }, forKey: .nodes)
        try container.encode(presentations.sorted(), forKey: .presentations)
    }
}

@_spi(PrimerInternal)
public extension SDKCapabilities {
    func canExecute(_ required: RequiredCapabilities) -> Bool {
        required.steps.allSatisfy { requiredStep, versions in supports(versions, given: steps[requiredStep]) }
            && required.nodes.allSatisfy { requiredNode, versions in supports(versions, given: nodes[requiredNode]) }
            && required.presentations.isSubset(of: presentations)
    }

    private func supports(_ versions: Set<Int>, given supported: Set<Int>?) -> Bool {
        let wanted = versions.isEmpty ? [1] : versions
        return !wanted.isDisjoint(with: supported ?? [])
    }
}
