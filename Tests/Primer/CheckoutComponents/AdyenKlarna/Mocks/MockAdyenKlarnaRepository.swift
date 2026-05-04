//
//  MockAdyenKlarnaRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockAdyenKlarnaRepository: AdyenKlarnaRepository {

    // MARK: - Configuration

    var fetchPaymentOptionsResult: Result<[AdyenKlarnaPaymentOption], Error> = .success([])
    var tokenizeResult: Result<(redirectUrl: URL, statusUrl: URL), Error> = .success(
        (redirectUrl: URL(string: "https://klarna.com/redirect")!,
         statusUrl: URL(string: "https://api.primer.io/status")!)
    )
    var openWebAuthResult: Result<URL, Error> = .success(URL(string: "testapp://callback")!)
    var pollResult: Result<String, Error> = .success("resume-token-123")
    var resumePaymentResult: Result<PaymentResult, Error> = .success(
        PaymentResult(paymentId: "pay-123", status: .success, amount: 1000, currencyCode: "EUR", paymentMethodType: "ADYEN_KLARNA")
    )

    // MARK: - Call Tracking

    private(set) var fetchPaymentOptionsCallCount = 0
    private(set) var tokenizeCallCount = 0
    private(set) var openWebAuthCallCount = 0
    private(set) var pollCallCount = 0
    private(set) var resumePaymentCallCount = 0
    private(set) var cancelPollingCallCount = 0

    private(set) var lastTokenizeSessionInfo: AdyenKlarnaSessionInfo?

    // MARK: - AdyenKlarnaRepository

    func fetchPaymentOptions(configId: String) async throws -> [AdyenKlarnaPaymentOption] {
        fetchPaymentOptionsCallCount += 1
        return try fetchPaymentOptionsResult.get()
    }

    func tokenize(paymentMethodType: String, sessionInfo: AdyenKlarnaSessionInfo) async throws -> (redirectUrl: URL, statusUrl: URL) {
        tokenizeCallCount += 1
        lastTokenizeSessionInfo = sessionInfo
        return try tokenizeResult.get()
    }

    func openWebAuthentication(paymentMethodType: String, url: URL) async throws -> URL {
        openWebAuthCallCount += 1
        return try openWebAuthResult.get()
    }

    func pollForCompletion(statusUrl: URL) async throws -> String {
        pollCallCount += 1
        return try pollResult.get()
    }

    func resumePayment(paymentMethodType: String, resumeToken: String) async throws -> PaymentResult {
        resumePaymentCallCount += 1
        return try resumePaymentResult.get()
    }

    func cancelPolling(paymentMethodType: String) {
        cancelPollingCallCount += 1
    }
}
