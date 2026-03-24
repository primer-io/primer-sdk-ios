//
//  MockProcessWebRedirectPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockProcessWebRedirectPaymentInteractor: ProcessWebRedirectPaymentInteractor {

    // MARK: - Configurable Return Values

    var paymentResultToReturn: PaymentResult?
    var errorToThrow: Error?

    // MARK: - Call Tracking

    private(set) var executeCallCount = 0
    private(set) var lastPaymentMethodType: String?

    // MARK: - ProcessWebRedirectPaymentInteractor Protocol

    func execute(paymentMethodType: String) async throws -> PaymentResult {
        executeCallCount += 1
        lastPaymentMethodType = paymentMethodType

        if let errorToThrow {
            throw errorToThrow
        }

        guard let result = paymentResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    // MARK: - Test Helpers

    func reset() {
        executeCallCount = 0
        lastPaymentMethodType = nil
        paymentResultToReturn = nil
        errorToThrow = nil
    }
}
