//
//  ClientInstruction.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation

@_spi(PrimerInternal)
public enum ClientInstruction {
    case wait(delayMilliseconds: Int)
    case execute(delayMilliseconds: Int, schema: CodableValue, parameters: CodableValue, currentAttempt: CurrentAttemptDataResponse?)
    case end(outcome: CheckoutOutcome?, payment: PaymentInfo?)
}

@_spi(PrimerInternal)
public struct CurrentAttemptDataResponse: Codable {
    let id: String
    let paymentInstrumentTokenId: String?
    let paymentId: String?
    let approvalStatus: String?
}

@_spi(PrimerInternal)
public enum SetupInstruction {
    case wait
    case execute(screen: CodableValue)
    case setupComplete(token: String)
}

@_spi(PrimerInternal)
public struct SetupState {
    public let instruction: SetupInstruction
    public let nextPoll: NextPoll

    public init(instruction: SetupInstruction, nextPoll: NextPoll) {
        self.instruction = instruction
        self.nextPoll = nextPoll
    }
}

@_spi(PrimerInternal)
public enum NextPoll: String, SingleValueContained {
    case interval
    case suspend
}

@_spi(PrimerInternal)
public struct SetupFlow {
    public let schema: CodableValue
    public let parameters: CodableValue
    public let setupId: String
    public let nextPoll: NextPoll

    public init(schema: CodableValue, parameters: CodableValue, setupId: String, nextPoll: NextPoll) {
        self.schema = schema
        self.parameters = parameters
        self.setupId = setupId
        self.nextPoll = nextPoll
    }
}

public enum CheckoutOutcome {
    case complete
    case failure
    case determineFromPaymentStatus
}

public struct PaymentInfo: Equatable {
    public let id: String?
    public let orderId: String?
    public let status: String

    public init(id: String?, orderId: String?, status: String) {
        self.id = id
        self.orderId = orderId
        self.status = status
    }
}
