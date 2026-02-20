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
}

struct ClientInstructionEndResponse: Decodable {
    let payload: PrimerCheckoutData
}
