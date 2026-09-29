//
//  MockProcessWebRedirectPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
final class MockProcessWebRedirectPaymentInteractor: ProcessWebRedirectPaymentInteractor {

    // MARK: - Configurable Return Values

    var paymentResultToReturn: PaymentResult?
    var errorToThrow: Error?
    /// When set, execute() suspends until release() is called.
    var shouldHold = false

    // MARK: - Call Tracking

    private(set) var executeCallCount = 0
    private(set) var lastPaymentMethodType: String?
    private var heldExecutions: [CheckedContinuation<Void, Never>] = []

    // MARK: - ProcessWebRedirectPaymentInteractor Protocol

    func execute(paymentMethodType: String) async throws -> PaymentResult {
        executeCallCount += 1
        lastPaymentMethodType = paymentMethodType

        if shouldHold {
            await withCheckedContinuation { heldExecutions.append($0) }
        }

        if let errorToThrow {
            throw errorToThrow
        }

        guard let result = paymentResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    // MARK: - Test Helpers

    func release() {
        heldExecutions.forEach { $0.resume() }
        heldExecutions = []
    }

    func reset() {
        executeCallCount = 0
        lastPaymentMethodType = nil
        paymentResultToReturn = nil
        errorToThrow = nil
        shouldHold = false
    }
}
