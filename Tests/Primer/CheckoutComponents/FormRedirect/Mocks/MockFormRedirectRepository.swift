//
//  MockFormRedirectRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@testable import PrimerSDK

@available(iOS 15.0, *)
final class MockFormRedirectRepository: FormRedirectRepository {

    // MARK: - Tokenize

    var tokenizeCallCount = 0
    var tokenizePaymentMethodType: String?
    var tokenizeSessionInfo: (any OffSessionPaymentSessionInfo)?
    var tokenizeResult: Result<FormRedirectTokenizationResponse, Error> = .success(FormRedirectTestData.tokenizationResponse)

    func tokenize(
        paymentMethodType: String,
        sessionInfo: any OffSessionPaymentSessionInfo
    ) async throws -> FormRedirectTokenizationResponse {
        tokenizeCallCount += 1
        tokenizePaymentMethodType = paymentMethodType
        tokenizeSessionInfo = sessionInfo

        switch tokenizeResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    // MARK: - Create Payment

    var createPaymentCallCount = 0
    var createPaymentToken: String?
    var createPaymentPaymentMethodType: String?
    var createPaymentResult: Result<FormRedirectPaymentResponse, Error> = .success(FormRedirectTestData.successPaymentResponse)

    func createPayment(token: String, paymentMethodType: String) async throws -> FormRedirectPaymentResponse {
        createPaymentCallCount += 1
        createPaymentToken = token
        createPaymentPaymentMethodType = paymentMethodType

        switch createPaymentResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    // MARK: - Resume Payment

    var resumePaymentCallCount = 0
    var resumePaymentPaymentId: String?
    var resumePaymentResumeToken: String?
    var resumePaymentPaymentMethodType: String?
    var resumePaymentResult: Result<FormRedirectPaymentResponse, Error> = .success(FormRedirectTestData.successPaymentResponse)

    func resumePayment(paymentId: String, resumeToken: String, paymentMethodType: String) async throws -> FormRedirectPaymentResponse {
        resumePaymentCallCount += 1
        resumePaymentPaymentId = paymentId
        resumePaymentResumeToken = resumeToken
        resumePaymentPaymentMethodType = paymentMethodType

        switch resumePaymentResult {
        case let .success(response):
            return response
        case let .failure(error):
            throw error
        }
    }

    // MARK: - Poll for Completion

    var pollForCompletionCallCount = 0
    var pollForCompletionStatusUrl: URL?
    var pollForCompletionResult: Result<String, Error> = .success(FormRedirectTestData.Constants.resumeToken)

    func pollForCompletion(statusUrl: URL) async throws -> String {
        pollForCompletionCallCount += 1
        pollForCompletionStatusUrl = statusUrl

        switch pollForCompletionResult {
        case let .success(token):
            return token
        case let .failure(error):
            throw error
        }
    }

    // MARK: - Cancel Polling

    var cancelPollingCallCount = 0
    var cancelPollingError: PrimerError?

    func cancelPolling(error: PrimerError) {
        cancelPollingCallCount += 1
        cancelPollingError = error
    }

    // MARK: - Reset

    func reset() {
        tokenizeCallCount = 0
        tokenizePaymentMethodType = nil
        tokenizeSessionInfo = nil
        tokenizeResult = .success(FormRedirectTestData.tokenizationResponse)

        createPaymentCallCount = 0
        createPaymentToken = nil
        createPaymentPaymentMethodType = nil
        createPaymentResult = .success(FormRedirectTestData.successPaymentResponse)

        resumePaymentCallCount = 0
        resumePaymentPaymentId = nil
        resumePaymentResumeToken = nil
        resumePaymentPaymentMethodType = nil
        resumePaymentResult = .success(FormRedirectTestData.successPaymentResponse)

        pollForCompletionCallCount = 0
        pollForCompletionStatusUrl = nil
        pollForCompletionResult = .success(FormRedirectTestData.Constants.resumeToken)

        cancelPollingCallCount = 0
        cancelPollingError = nil
    }
}
