//
//  ProbeRequest.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal)
public struct ProbeRequest: Decodable, Equatable, Sendable {
    public let key: String
    public let probe: String
    public let params: CodableValue

    public init(key: String, probe: String, params: CodableValue) {
        self.key = key
        self.probe = probe
        self.params = params
    }
}
