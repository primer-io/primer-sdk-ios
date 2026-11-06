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
        let paymentInstrumentToken: PaymentInstrumentToken?
    }

    struct PaymentInstrumentToken: Decodable {
        let token: String

        private enum CodingKeys: String, CodingKey {
            case token
        }

        init(from decoder: Decoder) throws {
            if let token = try? decoder.singleValueContainer().decode(String.self) {
                self.token = token
            } else {
                token = try decoder.container(keyedBy: CodingKeys.self).decode(String.self, forKey: .token)
            }
        }
    }
}

enum SetupInstructionType: String, SingleValueContained {
    case wait = "WAIT"
    case execute = "EXECUTE"
    case setupComplete = "SETUP_COMPLETE"
}
