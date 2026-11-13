//
//  ClientInstructionSetupEndedResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerBDCCore
@_spi(PrimerInternal) import PrimerNetworking

struct ClientInstructionSetupEndedResponse: Decodable {
    let paymentMethodSetupId: String
    let reason: SetupEndedReason

    private enum CodingKeys: String, CodingKey {
        case paymentMethodSetupId = "id"
        case reason
    }

    init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        paymentMethodSetupId = try container.decode(String.self, forKey: .paymentMethodSetupId)
        let reason = try container.decodeIfPresent(String.self, forKey: .reason)
        self.reason = reason.flatMap(SetupEndedReason.init(rawValue:)) ?? .failed
    }
}

enum SetupStartResponse: Decodable, NonSuccessDecodable {
    case started(ClientInstructionSetupResponse)
    case ended(ClientInstructionSetupEndedResponse)

    static let decodableStatusCodes: Set<Int> = [410]

    init(from decoder: any Decoder) throws {
        if try SetupStatusProbe(from: decoder).isEnded {
            self = .ended(try ClientInstructionSetupEndedResponse(from: decoder))
        } else {
            self = .started(try ClientInstructionSetupResponse(from: decoder))
        }
    }
}

enum SetupStateResponse: Decodable, NonSuccessDecodable {
    case state(ClientInstructionSetupStateResponse)
    case ended(ClientInstructionSetupEndedResponse)

    static let decodableStatusCodes: Set<Int> = [410]

    init(from decoder: any Decoder) throws {
        if try SetupStatusProbe(from: decoder).isEnded {
            self = .ended(try ClientInstructionSetupEndedResponse(from: decoder))
        } else {
            self = .state(try ClientInstructionSetupStateResponse(from: decoder))
        }
    }
}

private struct SetupStatusProbe: Decodable {
    let status: String?
    var isEnded: Bool { status == "ENDED" }
}
