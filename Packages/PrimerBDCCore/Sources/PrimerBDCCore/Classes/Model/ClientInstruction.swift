//
//  ClientInstruction.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PrimerFoundation

public enum ClientInstruction {
    case wait(delayMilliseconds: Int)
    case execute(delayMilliseconds: Int, schema: CodableValue, parameters: CodableValue)
    case end(outcome: CheckoutOutcome?, payment: PaymentInfo?)
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
