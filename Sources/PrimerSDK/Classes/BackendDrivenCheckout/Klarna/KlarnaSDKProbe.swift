//
//  KlarnaSDKProbe.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

#if canImport(PrimerKlarnaSDK)
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerStepResolver

struct KlarnaSDKProbe: Probe {
    static let name = "klarna.sdk"

    let version = "1.0.0"

    func run(_ params: CodableValue) async throws -> ProbeResult {
        ProbeResult(outcome: .success)
    }
}
#endif
