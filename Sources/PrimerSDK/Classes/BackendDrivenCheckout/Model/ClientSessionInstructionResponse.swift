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
        default: fatalError("Unhandled ClientInstructionType: \(type)")
        }
        
    }
}

enum ClientInstructionType: Decodable {
    case wait(ClientInstructionWaitResponse)
    case execute(ClientInstructionExecuteResponse)
    case end(ClientInstructionEndResponse)
}

struct ClientInstructionWaitResponse: Decodable {
    let pollDelayMilliseconds: Int?
}

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
        self.pollDelayMilliseconds = try container.decodeIfPresent(Int.self, forKey: .pollDelayMilliseconds)
        let payload = try container.decode(ClientInstructionExecutePayload.self, forKey: .payload)
        self.schema = payload.schema
        self.parameters = payload.parameters
    }
    
}

struct ClientInstructionEndResponse: Decodable {
    let payload: PrimerCheckoutData
}

struct ClientInstructionExecutePayload: Decodable {
    let schema: CodableValue
    let parameters: CodableValue
}
