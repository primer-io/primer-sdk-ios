//
//  ClientToken.swift
//  primer-checkout-api
//
//  Created by Evangelos Pittas on 1/3/21.
//

import Foundation

struct ClientTokenDecodable: Codable {
    
    var value: String
    var expiresAt: Date
    
    private enum CodingKeys : String, CodingKey {
        case value = "clientToken"
        case expiresAt = "expirationDate"
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.value = try container.decode(String.self, forKey: .value)
        let expiresAtStr = try container.decode(String.self, forKey: .expiresAt)
        self.expiresAt = expiresAtStr.toDate()!
    }
    
}
