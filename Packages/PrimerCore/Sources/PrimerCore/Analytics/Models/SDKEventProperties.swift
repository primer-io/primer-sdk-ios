//
//  SDKEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

public struct SDKEventProperties: AnalyticsEventProperties {

    public let name: String
    public let params: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case name
        case params
    }
    
    public init(name: String, parameters: [String: AnyCodable]? = nil) {
        self.name = name
        params = parameters
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        name = try container.decode(String.self, forKey: .name)
        params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(name, forKey: .name)
        try container.encodeIfPresent(params, forKey: .params)
    }
}
