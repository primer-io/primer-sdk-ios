//
//  SDKCapabilities.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal)
public struct SDKCapabilities: Equatable, Sendable, Encodable {
    public let stepTypes: [String: String]
    public let uiComponents: [String: String]
    public let probes: [String: String]

    public init(
        stepTypes: [String: String] = [:],
        uiComponents: [String: String] = [:],
        probes: [String: String] = [:]
    ) {
        self.stepTypes = stepTypes
        self.uiComponents = uiComponents
        self.probes = probes
    }
}
