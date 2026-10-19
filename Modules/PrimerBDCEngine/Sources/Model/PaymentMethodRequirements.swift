//
//  PaymentMethodRequirements.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal)
public struct PaymentMethodRequirements: Encodable, Equatable {
    public let id: String
    public let type: String
    public let clientRequirements: CodableValue?

    public init(id: String, type: String, clientRequirements: CodableValue?) {
        self.id = id
        self.type = type
        self.clientRequirements = clientRequirements
    }
}
