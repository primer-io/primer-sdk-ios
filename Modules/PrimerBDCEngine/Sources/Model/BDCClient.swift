//
//  BDCClient.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal)
public struct BDCClient: Encodable {
    public let capabilities: SDKCapabilities
    public let context: SDKContext

    public init(capabilities: SDKCapabilities, context: SDKContext) {
        self.capabilities = capabilities
        self.context = context
    }
}
