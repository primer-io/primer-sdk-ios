//
//  PrimerProbeRegistry.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal)
public actor PrimerProbeRegistry {
    public static let shared = PrimerProbeRegistry()

    private let logger = Logger()
    private var probes: [String: Probe] = [:]

    public init() {}

    public var declaredVersions: [String: String] {
        probes.mapValues(\.version)
    }

    public func register(_ probe: Probe, for name: String) {
        logger.info("Registering probe: \(name)")
        probes[name] = probe
    }

    public func run(_ name: String, params: CodableValue) async -> ProbeResult {
        guard let probe = probes[name] else {
            logger.info("No probe named '\(name)' — returning error")
            return ProbeResult(outcome: .error)
        }
        do {
            return try await probe.run(params)
        } catch {
            logger.error("Probe '\(name)' threw: \(error)")
            return ProbeResult(outcome: .error)
        }
    }
}
