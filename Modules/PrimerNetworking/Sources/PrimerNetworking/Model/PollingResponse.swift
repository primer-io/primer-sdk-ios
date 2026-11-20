//
//  PollingResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

enum PollingStatus: String, Codable {
    case pending = "PENDING"
    case complete = "COMPLETE"
}

@_spi(PrimerInternal) public struct PollingResponse: Decodable {

    let status: PollingStatus
    let id: String
    let source: String

    enum CodingKeys: CodingKey {
        case status
        case id
        case source
    }

    init(
        status: PollingStatus,
        id: String,
        source: String
    ) {
        self.status = status
        self.id = id
        self.source = source
    }

    public init(from decoder: Decoder) throws {
        do {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            status = try container.decode(PollingStatus.self, forKey: .status)
            id = try container.decode(String.self, forKey: .id)
            source = try container.decode(String.self, forKey: .source)
        } catch {
            throw error
        }

    }
}
