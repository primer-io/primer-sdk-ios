//
//  MockWebRedirectRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockWebRedirectRepository: WebRedirectRepository {

    // MARK: - Configurable Return Values

    var tokenizeResult: Result<(redirectUrl: URL, statusUrl: URL), Error> = .success((
        redirectUrl: URL(string: "https://redirect.example.com")!,
        statusUrl: URL(string: "https://status.example.com")!
    ))

    var openWebAuthResult: Result<URL, Error> = .success(URL(string: "https://callback.example.com")!)

    var pollResult: Result<String, Error> = .success("mock_resume_token")

    var resumePaymentResult: Result<PaymentResult, Error> = .success(PaymentResult(
        paymentId: "mock_payment_id",
        status: .success,
        paymentMethodType: "ADYEN_SOFORT"
    ))

    // MARK: - Call Tracking

    private(set) var tokenizeCallCount = 0
    private(set) var openWebAuthCallCount = 0
    private(set) var pollCallCount = 0
    private(set) var resumePaymentCallCount = 0
    private(set) var cancelPollingCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastTokenizePaymentMethodType: String?
    private(set) var lastTokenizeSessionInfo: WebRedirectSessionInfo?
    private(set) var lastOpenWebAuthPaymentMethodType: String?
    private(set) var lastOpenWebAuthUrl: URL?
    private(set) var lastPollStatusUrl: URL?
    private(set) var lastResumePaymentMethodType: String?
    private(set) var lastResumeToken: String?

    // MARK: - WebRedirectRepository Protocol

    func tokenize(
        paymentMethodType: String,
        sessionInfo: WebRedirectSessionInfo
    ) async throws -> (redirectUrl: URL, statusUrl: URL) {
        tokenizeCallCount += 1
        lastTokenizePaymentMethodType = paymentMethodType
        lastTokenizeSessionInfo = sessionInfo

        switch tokenizeResult {
        case let .success(result):
            return result
        case let .failure(error):
            throw error
        }
    }

    func openWebAuthentication(paymentMethodType: String, url: URL) async throws -> URL {
        openWebAuthCallCount += 1
        lastOpenWebAuthPaymentMethodType = paymentMethodType
        lastOpenWebAuthUrl = url

        switch openWebAuthResult {
        case let .success(url):
            return url
        case let .failure(error):
            throw error
        }
    }

    func pollForCompletion(statusUrl: URL) async throws -> String {
        pollCallCount += 1
        lastPollStatusUrl = statusUrl

        switch pollResult {
        case let .success(token):
            return token
        case let .failure(error):
            throw error
        }
    }

    func resumePayment(paymentMethodType: String, resumeToken: String) async throws -> PaymentResult {
        resumePaymentCallCount += 1
        lastResumePaymentMethodType = paymentMethodType
        lastResumeToken = resumeToken

        switch resumePaymentResult {
        case let .success(result):
            return result
        case let .failure(error):
            throw error
        }
    }

    func cancelPolling(paymentMethodType: String) {
        cancelPollingCallCount += 1
    }

    // MARK: - Test Helpers

    func reset() {
        tokenizeCallCount = 0
        openWebAuthCallCount = 0
        pollCallCount = 0
        resumePaymentCallCount = 0
        cancelPollingCallCount = 0

        lastTokenizePaymentMethodType = nil
        lastTokenizeSessionInfo = nil
        lastOpenWebAuthPaymentMethodType = nil
        lastOpenWebAuthUrl = nil
        lastPollStatusUrl = nil
        lastResumePaymentMethodType = nil
        lastResumeToken = nil

        tokenizeResult = .success((
            redirectUrl: URL(string: "https://redirect.example.com")!,
            statusUrl: URL(string: "https://status.example.com")!
        ))
        openWebAuthResult = .success(URL(string: "https://callback.example.com")!)
        pollResult = .success("mock_resume_token")
        resumePaymentResult = .success(PaymentResult(
            paymentId: "mock_payment_id",
            status: .success,
            paymentMethodType: "ADYEN_SOFORT"
        ))
    }
}
