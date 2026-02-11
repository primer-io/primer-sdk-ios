//
//  MockAchRepository.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit

@available(iOS 15.0, *)
@MainActor
final class MockAchRepository: AchRepository {

    // MARK: - Configurable Return Values

    var userDetailsResultToReturn: AchUserDetailsResult?
    var stripeDataToReturn: AchStripeData?
    var bankCollectorViewControllerToReturn: UIViewController?
    var mandateResultToReturn: AchMandateResult?
    var tokenDataToReturn: PrimerPaymentMethodTokenData?
    var paymentResultToReturn: PaymentResult?

    // MARK: - Error Configuration

    var loadUserDetailsError: Error?
    var patchUserDetailsError: Error?
    var validateError: Error?
    var startPaymentAndGetStripeDataError: Error?
    var createBankCollectorError: Error?
    var getMandateDataError: Error?
    var tokenizeError: Error?
    var createPaymentError: Error?
    var completePaymentError: Error?

    // MARK: - Call Tracking

    private(set) var loadUserDetailsCallCount = 0
    private(set) var patchUserDetailsCallCount = 0
    private(set) var validateCallCount = 0
    private(set) var startPaymentAndGetStripeDataCallCount = 0
    private(set) var createBankCollectorCallCount = 0
    private(set) var getMandateDataCallCount = 0
    private(set) var tokenizeCallCount = 0
    private(set) var createPaymentCallCount = 0
    private(set) var completePaymentCallCount = 0

    // MARK: - Captured Parameters

    private(set) var lastPatchedFirstName: String?
    private(set) var lastPatchedLastName: String?
    private(set) var lastPatchedEmailAddress: String?
    private(set) var lastBankCollectorFirstName: String?
    private(set) var lastBankCollectorLastName: String?
    private(set) var lastBankCollectorEmailAddress: String?
    private(set) var lastBankCollectorClientSecret: String?
    private(set) var lastBankCollectorDelegate: AchBankCollectorDelegate?
    private(set) var lastTokenData: PrimerPaymentMethodTokenData?
    private(set) var lastStripeData: AchStripeData?

    // MARK: - AchRepository Protocol

    func loadUserDetails() async throws -> AchUserDetailsResult {
        loadUserDetailsCallCount += 1

        if let loadUserDetailsError {
            throw loadUserDetailsError
        }

        guard let result = userDetailsResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    func patchUserDetails(firstName: String, lastName: String, emailAddress: String) async throws {
        patchUserDetailsCallCount += 1
        lastPatchedFirstName = firstName
        lastPatchedLastName = lastName
        lastPatchedEmailAddress = emailAddress

        if let patchUserDetailsError {
            throw patchUserDetailsError
        }
    }

    func validate() async throws {
        validateCallCount += 1

        if let validateError {
            throw validateError
        }
    }

    func startPaymentAndGetStripeData() async throws -> AchStripeData {
        startPaymentAndGetStripeDataCallCount += 1

        if let startPaymentAndGetStripeDataError {
            throw startPaymentAndGetStripeDataError
        }

        guard let result = stripeDataToReturn else {
            throw TestError.unknown
        }
        return result
    }

    func createBankCollector(
        firstName: String,
        lastName: String,
        emailAddress: String,
        clientSecret: String,
        delegate: AchBankCollectorDelegate
    ) async throws -> UIViewController {
        createBankCollectorCallCount += 1
        lastBankCollectorFirstName = firstName
        lastBankCollectorLastName = lastName
        lastBankCollectorEmailAddress = emailAddress
        lastBankCollectorClientSecret = clientSecret
        lastBankCollectorDelegate = delegate

        if let createBankCollectorError {
            throw createBankCollectorError
        }

        guard let viewController = bankCollectorViewControllerToReturn else {
            throw TestError.unknown
        }
        return viewController
    }

    func getMandateData() async throws -> AchMandateResult {
        getMandateDataCallCount += 1

        if let getMandateDataError {
            throw getMandateDataError
        }

        guard let result = mandateResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    func tokenize() async throws -> PrimerPaymentMethodTokenData {
        tokenizeCallCount += 1

        if let tokenizeError {
            throw tokenizeError
        }

        guard let result = tokenDataToReturn else {
            throw TestError.unknown
        }
        return result
    }

    func createPayment(tokenData: PrimerPaymentMethodTokenData) async throws -> PaymentResult {
        createPaymentCallCount += 1
        lastTokenData = tokenData

        if let createPaymentError {
            throw createPaymentError
        }

        guard let result = paymentResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    func completePayment(stripeData: AchStripeData) async throws -> PaymentResult {
        completePaymentCallCount += 1
        lastStripeData = stripeData

        if let completePaymentError {
            throw completePaymentError
        }

        guard let result = paymentResultToReturn else {
            throw TestError.unknown
        }
        return result
    }

    // MARK: - Test Helpers

    func reset() {
        loadUserDetailsCallCount = 0
        patchUserDetailsCallCount = 0
        validateCallCount = 0
        startPaymentAndGetStripeDataCallCount = 0
        createBankCollectorCallCount = 0
        getMandateDataCallCount = 0
        tokenizeCallCount = 0
        createPaymentCallCount = 0
        completePaymentCallCount = 0

        lastPatchedFirstName = nil
        lastPatchedLastName = nil
        lastPatchedEmailAddress = nil
        lastBankCollectorFirstName = nil
        lastBankCollectorLastName = nil
        lastBankCollectorEmailAddress = nil
        lastBankCollectorClientSecret = nil
        lastBankCollectorDelegate = nil
        lastTokenData = nil
        lastStripeData = nil

        loadUserDetailsError = nil
        patchUserDetailsError = nil
        validateError = nil
        startPaymentAndGetStripeDataError = nil
        createBankCollectorError = nil
        getMandateDataError = nil
        tokenizeError = nil
        createPaymentError = nil
        completePaymentError = nil
    }
}

// MARK: - Factory Methods

@available(iOS 15.0, *)
extension MockAchRepository {

    static func withSuccessfulUserDetails() -> MockAchRepository {
        let repository = MockAchRepository()
        repository.userDetailsResultToReturn = AchTestData.defaultUserDetails
        return repository
    }

    static func withFullSuccessFlow() -> MockAchRepository {
        let repository = MockAchRepository()
        repository.userDetailsResultToReturn = AchTestData.defaultUserDetails
        repository.stripeDataToReturn = AchTestData.defaultStripeData
        repository.bankCollectorViewControllerToReturn = UIViewController()
        repository.mandateResultToReturn = AchTestData.fullMandateResult
        repository.tokenDataToReturn = AchTestData.mockTokenData
        repository.paymentResultToReturn = AchTestData.successPaymentResult
        return repository
    }
}
