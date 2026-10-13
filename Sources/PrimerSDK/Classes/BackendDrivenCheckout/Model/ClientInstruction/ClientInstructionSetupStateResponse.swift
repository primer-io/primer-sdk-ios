//
//  ClientInstructionSetupStateResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerFoundation

struct ClientInstructionSetupStateResponse: Decodable {
    let paymentMethodSetupId: String
    let instruction: Instruction

    struct Instruction: Decodable {
        let type: SetupInstructionType
        let nextPoll: NextPoll?
        let payload: Payload?
    }

    struct Payload: Decodable {
        let schema: CodableValue?
        let parameters: CodableValue?
        let paymentInstrumentToken: String?
    }
}

enum SetupInstructionType: String, SingleValueContained {
    case wait = "WAIT"
    case execute = "EXECUTE"
    case setupComplete = "SETUP_COMPLETE"
}
