//
//  MockProcessFormRedirectPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockProcessFormRedirectPaymentInteractor: ProcessFormRedirectPaymentInteractor {

    // MARK: - Execute

    var executeCallCount = 0
    var executePaymentMethodType: String?
    var executeSessionInfo: (any OffSessionPaymentSessionInfo)?
    var executeResult: Result<PaymentResult, Error> = .success(FormRedirectTestData.successPaymentResult)
    var executeDelay: TimeInterval = 0
    var shouldCallOnPollingStarted: Bool = false
    var executeOnPollingStarted: (() -> Void)?

    func execute(
        paymentMethodType: String,
        sessionInfo: any OffSessionPaymentSessionInfo,
        onPollingStarted: (() -> Void)? = nil
    ) async throws -> PaymentResult {
        executeCallCount += 1
        executePaymentMethodType = paymentMethodType
        executeSessionInfo = sessionInfo
        executeOnPollingStarted = onPollingStarted

        if shouldCallOnPollingStarted {
            onPollingStarted?()
        }

        if executeDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(executeDelay * 1_000_000_000))
        }

        switch executeResult {
        case let .success(result):
            return result
        case let .failure(error):
            throw error
        }
    }

    // MARK: - Cancel Polling

    var cancelPollingCallCount = 0
    var cancelPollingPaymentMethodType: String?

    func cancelPolling(paymentMethodType: String) {
        cancelPollingCallCount += 1
        cancelPollingPaymentMethodType = paymentMethodType
    }

    // MARK: - Reset

    func reset() {
        executeCallCount = 0
        executePaymentMethodType = nil
        executeSessionInfo = nil
        executeResult = .success(FormRedirectTestData.successPaymentResult)
        executeDelay = 0
        shouldCallOnPollingStarted = false
        executeOnPollingStarted = nil
        cancelPollingCallCount = 0
        cancelPollingPaymentMethodType = nil
    }
}
