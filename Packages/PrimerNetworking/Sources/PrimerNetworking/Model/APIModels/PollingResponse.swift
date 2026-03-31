//
//  PollingResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

public enum PollingStatus: String, Codable {
    case pending = "PENDING"
    case complete = "COMPLETE"
}

public struct PollingResponse: Decodable {

    public let status: PollingStatus
    public let id: String
    public let source: String

    enum CodingKeys: CodingKey {
        case status
        case id
        case source
    }

    public init(
        status: PollingStatus,
        id: String,
        source: String
    ) {
        self.status = status
        self.id = id
        self.source = source
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.status = try container.decode(PollingStatus.self, forKey: .status)
        self.id = try container.decode(String.self, forKey: .id)
        self.source = try container.decode(String.self, forKey: .source)
    }
}
