//
//  ClientInstructionSetupResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

// Unlike :pay, the setup endpoint returns the schema + parameters directly — no
// `clientInstruction` envelope and no `type` — so it decodes on its own instead of
// through ClientSessionInstructionResponse. It always maps to an EXECUTE instruction.
struct ClientInstructionSetupResponse: Decodable {
    let schema: CodableValue
    let parameters: CodableValue
}
