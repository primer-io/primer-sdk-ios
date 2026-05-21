//
//  RawEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

//
//  RawEventProperties.swift
//  PrimerSDK
//
//  Created by Henry Cooper on 27/05/2026.
//
import Foundation
@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal) public struct RawEventProperties: AnalyticsEventProperties {
    private let values: [String: AnyCodable]

    public init(data: Data) throws {
        values = try JSONDecoder().decode([String: AnyCodable].self, from: data)
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        values = try container.decode([String: AnyCodable].self)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(values)
    }
}
