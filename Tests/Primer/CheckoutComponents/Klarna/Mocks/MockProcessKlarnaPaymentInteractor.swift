//
//  MockProcessKlarnaPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit

@available(iOS 15.0, *)
final class MockProcessKlarnaPaymentInteractor: ProcessKlarnaPaymentInteractor {

    // MARK: - Configurable Return Values

    var sessionResultToReturn: KlarnaSessionResult?
    var paymentViewToReturn: UIView?
    var authorizationResultToReturn: KlarnaAuthorizationResult?
    var finalizationResultToReturn: KlarnaAuthorizationResult?
    var paymentResultToReturn: PaymentResult?

    // MARK: - Error Configuration

    var createSessionError: Error?
    var configureForCategoryError: Error?
    var authorizeError: Error?
    var finalizeError: Error?
    var tokenizeError: Error?

    // MARK: - Call Tracking

    private(set) var createSessionCallCount = 0
    private(set) var configureForCategoryCallCount = 0
    private(set) var authorizeCallCount = 0
    private(set) var finalizeCallCount = 0
    private(set) var tokenizeCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastClientToken: String?
    private(set) var lastCategoryId: String?
    private(set) var lastAuthToken: String?

    // MARK: - Closures for Custom Behavior

    var onCreateSession: (() async throws -> KlarnaSessionResult)?
    var onConfigureForCategory: ((String, String) async throws -> UIView?)?
    var onAuthorize: (() async throws -> KlarnaAuthorizationResult)?
    var onFinalize: (() async throws -> KlarnaAuthorizationResult)?
    var onTokenize: ((String) async throws -> PaymentResult)?

    // MARK: - ProcessKlarnaPaymentInteractor Protocol

    func createSession() async throws -> KlarnaSessionResult {
        createSessionCallCount += 1

        if let onCreateSession {
            return try await onCreateSession()
        }

        if let createSessionError {
            throw createSessionError
        }

        guard let result = sessionResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    func configureForCategory(clientToken: String, categoryId: String) async throws -> UIView? {
        configureForCategoryCallCount += 1
        lastClientToken = clientToken
        lastCategoryId = categoryId

        if let onConfigureForCategory {
            return try await onConfigureForCategory(clientToken, categoryId)
        }

        if let configureForCategoryError {
            throw configureForCategoryError
        }

        return paymentViewToReturn
    }

    func authorize() async throws -> KlarnaAuthorizationResult {
        authorizeCallCount += 1

        if let onAuthorize {
            return try await onAuthorize()
        }

        if let authorizeError {
            throw authorizeError
        }

        guard let result = authorizationResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    func finalize() async throws -> KlarnaAuthorizationResult {
        finalizeCallCount += 1

        if let onFinalize {
            return try await onFinalize()
        }

        if let finalizeError {
            throw finalizeError
        }

        guard let result = finalizationResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    func tokenize(authToken: String) async throws -> PaymentResult {
        tokenizeCallCount += 1
        lastAuthToken = authToken

        if let onTokenize {
            return try await onTokenize(authToken)
        }

        if let tokenizeError {
            throw tokenizeError
        }

        guard let result = paymentResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    // MARK: - Test Helpers

    func reset() {
        createSessionCallCount = 0
        configureForCategoryCallCount = 0
        authorizeCallCount = 0
        finalizeCallCount = 0
        tokenizeCallCount = 0

        lastClientToken = nil
        lastCategoryId = nil
        lastAuthToken = nil

        createSessionError = nil
        configureForCategoryError = nil
        authorizeError = nil
        finalizeError = nil
        tokenizeError = nil
    }
}
