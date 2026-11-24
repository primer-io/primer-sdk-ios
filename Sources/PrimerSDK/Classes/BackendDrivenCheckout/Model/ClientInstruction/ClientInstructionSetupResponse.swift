//
//  ClientInstructionSetupResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerFoundation

struct ClientInstructionSetupResponse: Decodable {
    let paymentMethodSetupId: String
    let instruction: Instruction

    private enum CodingKeys: String, CodingKey {
        case paymentMethodSetupId = "id"
        case instruction
    }

    struct Instruction: Decodable {
        let nextPoll: NextPoll
        let pollDelayMilliseconds: Int?
        let payload: Payload
    }

    struct Payload: Decodable {
        let schema: CodableValue
        let parameters: CodableValue
    }
}
