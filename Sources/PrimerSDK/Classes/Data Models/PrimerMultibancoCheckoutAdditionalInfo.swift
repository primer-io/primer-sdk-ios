//
//  PrimerMultibancoCheckoutAdditionalInfo.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@objc public final class MultibancoCheckoutAdditionalInfo: PrimerCheckoutAdditionalInfo {

    public let expiresAt: String?
    public let entity: String?
    public let reference: String?

    private enum CodingKeys: String, CodingKey {
        case expiresAt
        case entity
        case reference
    }

    public init(expiresAt: String?, entity: String?, reference: String?) {
        self.expiresAt = expiresAt
        self.entity = entity
        self.reference = reference
        super.init()
    }

    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        expiresAt = try? container.decode(String.self, forKey: .expiresAt)
        entity = try? container.decode(String.self, forKey: .entity)
        reference = try? container.decode(String.self, forKey: .reference)
        super.init()
    }

    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try? container.encode(expiresAt, forKey: .expiresAt)
        try? container.encode(entity, forKey: .entity)
        try? container.encode(reference, forKey: .reference)
    }
}
