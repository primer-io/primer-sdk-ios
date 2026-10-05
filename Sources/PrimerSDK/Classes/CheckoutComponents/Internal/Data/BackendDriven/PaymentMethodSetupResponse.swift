//
//  PaymentMethodSetupResponse.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

/// The poll answer from the ADR. The ADR shows no start answer as JSON, so the start call is decoded
/// with the same envelope: a setup id plus one instruction.
struct PaymentMethodSetupResponse: Decodable {
  let paymentMethodSetupId: String
  let instruction: Instruction

  struct Instruction: Decodable {
    let type: Kind
    let pollDelayMilliseconds: Int?
    let nextPoll: NextPoll?
    let payload: Screen?
    let paymentInstrumentToken: Token?
  }

  enum Kind: String, Decodable {
    case execute = "EXECUTE"
    case wait = "WAIT"
    case setupComplete = "SETUP_COMPLETE"
  }

  /// `suspend`: nothing changes until the shopper acts. `interval`: the server can move on its own.
  enum NextPoll: String, Decodable {
    case interval
    case suspend
  }

  struct Screen: Decodable {
    let schema: CodableValue
    let parameters: CodableValue
  }

  struct Token: Decodable {
    let token: String
  }
}
