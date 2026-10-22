//
//  MockProcessFormRedirectPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
final class MockProcessFormRedirectPaymentInteractor: ProcessFormRedirectPaymentInteractor {

    // MARK: - Execute

    private(set) var executeCallCount = 0
    private(set) var executePaymentMethodType: String?
    private(set) var executeSessionInfo: (any OffSessionPaymentSessionInfo)?
    var executeResult: Result<PaymentResult, Error> = .success(FormRedirectTestData.successPaymentResult)
    var executeDelay: TimeInterval = 0
    /// When set, execute() suspends until release() is called.
    var shouldHold = false
    var shouldCallOnPollingStarted: Bool = false
    private(set) var executeOnPollingStarted: (() -> Void)?
    private var heldExecutions: [CheckedContinuation<Void, Never>] = []

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

        if shouldHold {
            await withCheckedContinuation { heldExecutions.append($0) }
        }

        switch executeResult {
        case let .success(result):
            return result
        case let .failure(error):
            throw error
        }
    }

    func release() {
        heldExecutions.forEach { $0.resume() }
        heldExecutions = []
    }

    // MARK: - Cancel Polling

    private(set) var cancelPollingCallCount = 0
    private(set) var cancelPollingPaymentMethodType: String?

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
        shouldHold = false
        shouldCallOnPollingStarted = false
        executeOnPollingStarted = nil
        cancelPollingCallCount = 0
        cancelPollingPaymentMethodType = nil
    }
}
