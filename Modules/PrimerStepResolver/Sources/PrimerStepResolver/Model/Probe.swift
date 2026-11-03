//
//  Probe.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal)
public protocol Probe: Sendable {
    var version: String { get }

    func run(_ params: CodableValue) async throws -> ProbeResult
}

@_spi(PrimerInternal)
public struct ProbeResult: Encodable, Equatable, Sendable {
    public let outcome: ProbeOutcome
    public let data: CodableValue?

    public init(outcome: ProbeOutcome, data: CodableValue? = nil) {
        self.outcome = outcome
        self.data = data
    }
}

@_spi(PrimerInternal)
public enum ProbeOutcome: String, Encodable, Sendable {
    case success
    case failure
    case error
}
