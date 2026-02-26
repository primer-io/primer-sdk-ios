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
    let payload: Payload?
}

struct Payload: Decodable {
    let schema: CodableValue
    let parameters: CodableValue
}

enum ClientInstructionType: String, Decodable {
    case wait = "WAIT"
    case execute = "EXECUTE"
    case end = "END"
}
