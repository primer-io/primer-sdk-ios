//
//  ClientSessionInstructionResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

struct ClientSessionInstructionResponse: Decodable {
    let clientInstruction: ClientInstructionDataResponse
}

struct ClientInstructionDataResponse: Decodable {
    let type: ClientInstructionType
    
    enum CodingKeys: CodingKey {
        case type
    }
    
    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        let type = try container.decode(String.self, forKey: .type)
        switch type {
        case "WAIT": self.type = .wait(try ClientInstructionWaitResponse(from: decoder))
        case "EXECUTE": self.type = .execute(try ClientInstructionExecuteResponse(from: decoder))
        case "END": self.type = .end(try ClientInstructionEndResponse(from: decoder))
        default: throw Error.unknownClientInstructionType(type: type)
        }
        
    }
}

private extension ClientInstructionDataResponse {
    enum Error: Swift.Error {
        case unknownClientInstructionType(type: String)
    }
}
