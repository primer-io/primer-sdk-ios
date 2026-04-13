//
//  ClientInstructionType.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

enum ClientInstructionType: Decodable {
    case wait(ClientInstructionWaitResponse)
    case execute(ClientInstructionExecuteResponse)
    case end(ClientInstructionEndResponse)
}
