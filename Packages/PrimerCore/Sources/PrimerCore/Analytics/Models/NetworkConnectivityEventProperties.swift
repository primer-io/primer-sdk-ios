//
//  NetworkConnectivityEventProperties.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

public struct NetworkConnectivityEventProperties: AnalyticsEventProperties {

    public let networkType: String
    public let params: [String: AnyCodable]?

    private enum CodingKeys: String, CodingKey {
        case networkType
        case params
    }
    
    public init(networkType: String, params: [String: AnyCodable]? = nil) {
        self.networkType = networkType
        self.params = params
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.networkType = try container.decode(String.self, forKey: .networkType)
        self.params = try container.decodeIfPresent([String: AnyCodable].self, forKey: .params)
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(networkType, forKey: .networkType)
        try container.encodeIfPresent(params, forKey: .params)
    }
}
