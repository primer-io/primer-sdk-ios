//
//  MockQRCodeRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockQRCodeRepository: QRCodeRepository {

    // MARK: - Configurable Return Values

    var startPaymentResult: Result<QRCodePaymentData, Error>?
    var pollResult: Result<String, Error>?
    var resumePaymentResult: Result<PaymentResult, Error>?

    // MARK: - Call Tracking

    private(set) var startPaymentCallCount = 0
    private(set) var pollForCompletionCallCount = 0
    private(set) var resumePaymentCallCount = 0
    private(set) var cancelPollingCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastStartPaymentMethodType: String?
    private(set) var lastPollStatusUrl: URL?
    private(set) var lastResumePaymentId: String?
    private(set) var lastResumeToken: String?
    private(set) var lastResumePaymentMethodType: String?
    private(set) var lastCancelPaymentMethodType: String?

    // MARK: - QRCodeRepository Protocol

    func startPayment(paymentMethodType: String) async throws -> QRCodePaymentData {
        startPaymentCallCount += 1
        lastStartPaymentMethodType = paymentMethodType
        guard let result = startPaymentResult else { throw TestError.unknown }
        return try result.get()
    }

    func pollForCompletion(statusUrl: URL) async throws -> String {
        pollForCompletionCallCount += 1
        lastPollStatusUrl = statusUrl
        guard let result = pollResult else { throw TestError.unknown }
        return try result.get()
    }

    func resumePayment(
        paymentId: String,
        resumeToken: String,
        paymentMethodType: String
    ) async throws -> PaymentResult {
        resumePaymentCallCount += 1
        lastResumePaymentId = paymentId
        lastResumeToken = resumeToken
        lastResumePaymentMethodType = paymentMethodType
        guard let result = resumePaymentResult else { throw TestError.unknown }
        return try result.get()
    }

    func cancelPolling(paymentMethodType: String) {
        cancelPollingCallCount += 1
        lastCancelPaymentMethodType = paymentMethodType
    }
}
