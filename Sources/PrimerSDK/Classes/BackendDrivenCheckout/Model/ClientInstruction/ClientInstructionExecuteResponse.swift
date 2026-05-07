//
//  ClientInstructionExecuteResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

struct ClientInstructionExecuteResponse: Decodable {
    let pollDelayMilliseconds: Int?
    let schema: CodableValue
    let parameters: CodableValue
    
    enum CodingKeys: CodingKey {
        case pollDelayMilliseconds
        case payload
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        pollDelayMilliseconds = try container.decodeIfPresent(Int.self, forKey: .pollDelayMilliseconds)

        let payload = try container.decode(ClientInstructionExecutePayload.self, forKey: .payload)
        schema = payload.schema
        parameters = payload.parameters
    }
    
}

private struct ClientInstructionExecutePayload: Decodable {
    let schema: CodableValue
    let parameters: CodableValue
}
