//
//  MockProcessAchPaymentInteractor.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit

@available(iOS 15.0, *)
final class MockProcessAchPaymentInteractor: ProcessAchPaymentInteractor {

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

    // MARK: - Closures for Custom Behavior

    var onLoadUserDetails: (() async throws -> AchUserDetailsResult)?
    var onPatchUserDetails: ((String, String, String) async throws -> Void)?
    var onValidate: (() async throws -> Void)?
    var onStartPaymentAndGetStripeData: (() async throws -> AchStripeData)?
    var onCreateBankCollector: ((String, String, String, String, AchBankCollectorDelegate) async throws -> UIViewController)?
    var onGetMandateData: (() async throws -> AchMandateResult)?
    var onTokenize: (() async throws -> PrimerPaymentMethodTokenData)?
    var onCreatePayment: ((PrimerPaymentMethodTokenData) async throws -> PaymentResult)?
    var onCompletePayment: ((AchStripeData) async throws -> PaymentResult)?

    // MARK: - ProcessAchPaymentInteractor Protocol

    func loadUserDetails() async throws -> AchUserDetailsResult {
        loadUserDetailsCallCount += 1

        if let onLoadUserDetails {
            return try await onLoadUserDetails()
        }

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

        if let onPatchUserDetails {
            try await onPatchUserDetails(firstName, lastName, emailAddress)
            return
        }

        if let patchUserDetailsError {
            throw patchUserDetailsError
        }
    }

    func validate() async throws {
        validateCallCount += 1

        if let onValidate {
            try await onValidate()
            return
        }

        if let validateError {
            throw validateError
        }
    }

    func startPaymentAndGetStripeData() async throws -> AchStripeData {
        startPaymentAndGetStripeDataCallCount += 1

        if let onStartPaymentAndGetStripeData {
            return try await onStartPaymentAndGetStripeData()
        }

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

        if let onCreateBankCollector {
            return try await onCreateBankCollector(firstName, lastName, emailAddress, clientSecret, delegate)
        }

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

        if let onGetMandateData {
            return try await onGetMandateData()
        }

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

        if let onTokenize {
            return try await onTokenize()
        }

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

        if let onCreatePayment {
            return try await onCreatePayment(tokenData)
        }

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

        if let onCompletePayment {
            return try await onCompletePayment(stripeData)
        }

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
extension MockProcessAchPaymentInteractor {

    static func withSuccessfulUserDetails() -> MockProcessAchPaymentInteractor {
        let interactor = MockProcessAchPaymentInteractor()
        interactor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        return interactor
    }

    static func withFullSuccessFlow() -> MockProcessAchPaymentInteractor {
        let interactor = MockProcessAchPaymentInteractor()
        interactor.userDetailsResultToReturn = AchTestData.defaultUserDetails
        interactor.stripeDataToReturn = AchTestData.defaultStripeData
        interactor.bankCollectorViewControllerToReturn = UIViewController()
        interactor.mandateResultToReturn = AchTestData.fullMandateResult
        interactor.tokenDataToReturn = AchTestData.mockTokenData
        interactor.paymentResultToReturn = AchTestData.successPaymentResult
        return interactor
    }
}
