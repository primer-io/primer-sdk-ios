//
//  MockProcessQRCodePaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockProcessQRCodePaymentInteractor: ProcessQRCodePaymentInteractor {

    // MARK: - Configurable Return Values

    var startPaymentResult: Result<QRCodePaymentData, Error>?
    var pollAndCompleteResult: Result<PaymentResult, Error>?

    // MARK: - Closures for Custom Behavior

    var onPollAndComplete: (() async throws -> PaymentResult)?

    // MARK: - Call Tracking

    private(set) var startPaymentCallCount = 0
    private(set) var pollAndCompleteCallCount = 0
    private(set) var cancelPollingCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastPollStatusUrl: URL?
    private(set) var lastPollPaymentId: String?

    // MARK: - ProcessQRCodePaymentInteractor Protocol

    func startPayment() async throws -> QRCodePaymentData {
        startPaymentCallCount += 1
        guard let result = startPaymentResult else { throw TestError.unknown }
        return try result.get()
    }

    func pollAndComplete(statusUrl: URL, paymentId: String) async throws -> PaymentResult {
        pollAndCompleteCallCount += 1
        lastPollStatusUrl = statusUrl
        lastPollPaymentId = paymentId

        if let onPollAndComplete {
            return try await onPollAndComplete()
        }

        guard let result = pollAndCompleteResult else { throw TestError.unknown }
        return try result.get()
    }

    func cancelPolling() {
        cancelPollingCallCount += 1
    }
}

// MARK: - Factory Methods

@available(iOS 15.0, *)
extension MockProcessQRCodePaymentInteractor {

    static func withFullSuccessFlow() -> MockProcessQRCodePaymentInteractor {
        let interactor = MockProcessQRCodePaymentInteractor()
        interactor.startPaymentResult = .success(QRCodeTestData.defaultPaymentData)
        interactor.pollAndCompleteResult = .success(QRCodeTestData.successPaymentResult)
        return interactor
    }
}
