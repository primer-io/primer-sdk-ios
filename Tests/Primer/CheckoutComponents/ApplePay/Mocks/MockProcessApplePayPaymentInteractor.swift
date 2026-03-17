//
//  MockProcessApplePayPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import PassKit
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockProcessApplePayPaymentInteractor: ProcessApplePayPaymentInteractor {

    var onExecute: ((PKPayment) async throws -> PaymentResult)?
    private(set) var executeCallCount = 0
    private(set) var lastPaymentReceived: PKPayment?

    func execute(payment: PKPayment) async throws -> PaymentResult {
        executeCallCount += 1
        lastPaymentReceived = payment

        guard let onExecute else {
            throw PrimerError.unknown(message: "MockProcessApplePayPaymentInteractor: onExecute not set")
        }

        return try await onExecute(payment)
    }
}
