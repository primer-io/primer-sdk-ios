//
//  MockProcessCardPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved.
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockProcessCardPaymentInteractor: ProcessCardPaymentInteractor {

    var resultToReturn: PaymentResult = PaymentResult(paymentId: "test-payment-id", status: .success)
    var errorToThrow: Error?

    func execute(cardData: CardPaymentData) async throws -> PaymentResult {
        if let error = errorToThrow {
            throw error
        }
        return resultToReturn
    }
}
