//
//  ClientInstructionSetupStateResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerFoundation

struct ClientInstructionSetupStateResponse: Decodable {
    let instruction: SetupInstructionType
    let screen: CodableValue?
    let token: String?
    let nextPoll: NextPoll
}

enum SetupInstructionType: String, SingleValueContained {
    case wait = "WAIT"
    case execute = "EXECUTE"
    case setupComplete = "SETUP_COMPLETE"
}
