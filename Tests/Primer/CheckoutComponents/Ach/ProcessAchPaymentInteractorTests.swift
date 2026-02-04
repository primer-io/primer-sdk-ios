//
//  ProcessAchPaymentInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
import XCTest

@available(iOS 15.0, *)
@MainActor
final class ProcessAchPaymentInteractorTests: XCTestCase {

    // MARK: - Properties

    var sut: ProcessAchPaymentInteractorImpl!
    var mockRepository: MockAchRepository!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockAchRepository()
        sut = ProcessAchPaymentInteractorImpl(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - loadUserDetails Tests

    func test_loadUserDetails_success_returnsUserDetailsResult() async throws {
        // Given
        mockRepository.userDetailsResultToReturn = AchTestData.defaultUserDetails

        // When
        let result = try await sut.loadUserDetails()

        // Then
        XCTAssertEqual(result.firstName, AchTestData.Constants.firstName)
        XCTAssertEqual(result.lastName, AchTestData.Constants.lastName)
        XCTAssertEqual(result.emailAddress, AchTestData.Constants.emailAddress)
        XCTAssertEqual(mockRepository.loadUserDetailsCallCount, 1)
    }

    func test_loadUserDetails_failure_throwsError() async {
        // Given
        mockRepository.loadUserDetailsError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.loadUserDetails()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
            XCTAssertEqual(mockRepository.loadUserDetailsCallCount, 1)
        }
    }

    func test_loadUserDetails_delegatesToRepository() async throws {
        // Given
        mockRepository.userDetailsResultToReturn = AchTestData.defaultUserDetails

        // When
        _ = try await sut.loadUserDetails()

        // Then
        XCTAssertEqual(mockRepository.loadUserDetailsCallCount, 1)
    }

    // MARK: - patchUserDetails Tests

    func test_patchUserDetails_success_completesWithoutError() async throws {
        // Given
        let firstName = AchTestData.Constants.firstName
        let lastName = AchTestData.Constants.lastName
        let email = AchTestData.Constants.emailAddress

        // When
        try await sut.patchUserDetails(firstName: firstName, lastName: lastName, emailAddress: email)

        // Then
        XCTAssertEqual(mockRepository.patchUserDetailsCallCount, 1)
        XCTAssertEqual(mockRepository.lastPatchedFirstName, firstName)
        XCTAssertEqual(mockRepository.lastPatchedLastName, lastName)
        XCTAssertEqual(mockRepository.lastPatchedEmailAddress, email)
    }

    func test_patchUserDetails_failure_throwsError() async {
        // Given
        mockRepository.patchUserDetailsError = TestError.networkFailure

        // When/Then
        do {
            try await sut.patchUserDetails(
                firstName: "John",
                lastName: "Doe",
                emailAddress: "john@example.com"
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    func test_patchUserDetails_capturesParameters() async throws {
        // Given
        let firstName = "Test"
        let lastName = "User"
        let email = "test@example.com"

        // When
        try await sut.patchUserDetails(firstName: firstName, lastName: lastName, emailAddress: email)

        // Then
        XCTAssertEqual(mockRepository.lastPatchedFirstName, firstName)
        XCTAssertEqual(mockRepository.lastPatchedLastName, lastName)
        XCTAssertEqual(mockRepository.lastPatchedEmailAddress, email)
    }

    // MARK: - validate Tests

    func test_validate_success_completesWithoutError() async throws {
        // When
        try await sut.validate()

        // Then
        XCTAssertEqual(mockRepository.validateCallCount, 1)
    }

    func test_validate_failure_throwsError() async {
        // Given
        mockRepository.validateError = TestError.validationFailed("Invalid configuration")

        // When/Then
        do {
            try await sut.validate()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .validationFailed("Invalid configuration"))
        }
    }

    // MARK: - startPaymentAndGetStripeData Tests

    func test_startPaymentAndGetStripeData_success_returnsStripeData() async throws {
        // Given
        mockRepository.stripeDataToReturn = AchTestData.defaultStripeData

        // When
        let result = try await sut.startPaymentAndGetStripeData()

        // Then
        XCTAssertEqual(result.stripeClientSecret, AchTestData.Constants.stripeClientSecret)
        XCTAssertEqual(result.paymentId, AchTestData.Constants.paymentId)
        XCTAssertEqual(mockRepository.startPaymentAndGetStripeDataCallCount, 1)
    }

    func test_startPaymentAndGetStripeData_failure_throwsError() async {
        // Given
        mockRepository.startPaymentAndGetStripeDataError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.startPaymentAndGetStripeData()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    // MARK: - createBankCollector Tests

    func test_createBankCollector_success_returnsViewController() async throws {
        // Given
        let expectedVC = UIViewController()
        mockRepository.bankCollectorViewControllerToReturn = expectedVC

        // When
        let result = try await sut.createBankCollector(
            firstName: AchTestData.Constants.firstName,
            lastName: AchTestData.Constants.lastName,
            emailAddress: AchTestData.Constants.emailAddress,
            clientSecret: AchTestData.Constants.stripeClientSecret,
            delegate: MockBankCollectorDelegate()
        )

        // Then
        XCTAssertTrue(result === expectedVC)
        XCTAssertEqual(mockRepository.createBankCollectorCallCount, 1)
    }

    func test_createBankCollector_capturesParameters() async throws {
        // Given
        let firstName = AchTestData.Constants.firstName
        let lastName = AchTestData.Constants.lastName
        let email = AchTestData.Constants.emailAddress
        let clientSecret = AchTestData.Constants.stripeClientSecret
        let delegate = MockBankCollectorDelegate()
        mockRepository.bankCollectorViewControllerToReturn = UIViewController()

        // When
        _ = try await sut.createBankCollector(
            firstName: firstName,
            lastName: lastName,
            emailAddress: email,
            clientSecret: clientSecret,
            delegate: delegate
        )

        // Then
        XCTAssertEqual(mockRepository.lastBankCollectorFirstName, firstName)
        XCTAssertEqual(mockRepository.lastBankCollectorLastName, lastName)
        XCTAssertEqual(mockRepository.lastBankCollectorEmailAddress, email)
        XCTAssertEqual(mockRepository.lastBankCollectorClientSecret, clientSecret)
        XCTAssertTrue(mockRepository.lastBankCollectorDelegate === delegate)
    }

    func test_createBankCollector_failure_throwsError() async {
        // Given
        mockRepository.createBankCollectorError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.createBankCollector(
                firstName: "John",
                lastName: "Doe",
                emailAddress: "john@example.com",
                clientSecret: "secret",
                delegate: MockBankCollectorDelegate()
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    // MARK: - getMandateData Tests

    func test_getMandateData_success_returnsMandateResult() async throws {
        // Given
        mockRepository.mandateResultToReturn = AchTestData.fullMandateResult

        // When
        let result = try await sut.getMandateData()

        // Then
        XCTAssertEqual(result.fullMandateText, AchTestData.Constants.mandateText)
        XCTAssertEqual(mockRepository.getMandateDataCallCount, 1)
    }

    func test_getMandateData_failure_throwsError() async {
        // Given
        mockRepository.getMandateDataError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.getMandateData()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    // MARK: - tokenize Tests

    func test_tokenize_success_returnsTokenData() async throws {
        // Given
        mockRepository.tokenDataToReturn = AchTestData.mockTokenData

        // When
        let result = try await sut.tokenize()

        // Then
        XCTAssertEqual(result.token, "pm_token_123")
        XCTAssertEqual(mockRepository.tokenizeCallCount, 1)
    }

    func test_tokenize_failure_throwsError() async {
        // Given
        mockRepository.tokenizeError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.tokenize()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    // MARK: - createPayment Tests

    func test_createPayment_success_returnsPaymentResult() async throws {
        // Given
        mockRepository.paymentResultToReturn = AchTestData.successPaymentResult
        let tokenData = AchTestData.mockTokenData

        // When
        let result = try await sut.createPayment(tokenData: tokenData)

        // Then
        XCTAssertEqual(result.paymentId, AchTestData.Constants.paymentId)
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(mockRepository.createPaymentCallCount, 1)
        XCTAssertNotNil(mockRepository.lastTokenData)
    }

    func test_createPayment_failure_throwsError() async {
        // Given
        mockRepository.createPaymentError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.createPayment(tokenData: AchTestData.mockTokenData)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    // MARK: - completePayment Tests

    func test_completePayment_success_returnsPaymentResult() async throws {
        // Given
        mockRepository.paymentResultToReturn = AchTestData.successPaymentResult
        let stripeData = AchTestData.defaultStripeData

        // When
        let result = try await sut.completePayment(stripeData: stripeData)

        // Then
        XCTAssertEqual(result.paymentId, AchTestData.Constants.paymentId)
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(mockRepository.completePaymentCallCount, 1)
    }

    func test_completePayment_capturesStripeData() async throws {
        // Given
        mockRepository.paymentResultToReturn = AchTestData.successPaymentResult
        let stripeData = AchTestData.defaultStripeData

        // When
        _ = try await sut.completePayment(stripeData: stripeData)

        // Then
        XCTAssertNotNil(mockRepository.lastStripeData)
        XCTAssertEqual(mockRepository.lastStripeData?.stripeClientSecret, stripeData.stripeClientSecret)
    }

    func test_completePayment_failure_throwsError() async {
        // Given
        mockRepository.completePaymentError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.completePayment(stripeData: AchTestData.defaultStripeData)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    // MARK: - Call Delegation Tests

    func test_allMethods_delegateToRepository() async throws {
        // Given
        mockRepository.userDetailsResultToReturn = AchTestData.defaultUserDetails
        mockRepository.stripeDataToReturn = AchTestData.defaultStripeData
        mockRepository.bankCollectorViewControllerToReturn = UIViewController()
        mockRepository.mandateResultToReturn = AchTestData.fullMandateResult
        mockRepository.tokenDataToReturn = AchTestData.mockTokenData
        mockRepository.paymentResultToReturn = AchTestData.successPaymentResult

        // When
        _ = try await sut.loadUserDetails()
        try await sut.patchUserDetails(
            firstName: AchTestData.Constants.firstName,
            lastName: AchTestData.Constants.lastName,
            emailAddress: AchTestData.Constants.emailAddress
        )
        try await sut.validate()
        _ = try await sut.startPaymentAndGetStripeData()
        _ = try await sut.createBankCollector(
            firstName: AchTestData.Constants.firstName,
            lastName: AchTestData.Constants.lastName,
            emailAddress: AchTestData.Constants.emailAddress,
            clientSecret: AchTestData.Constants.stripeClientSecret,
            delegate: MockBankCollectorDelegate()
        )
        _ = try await sut.getMandateData()
        _ = try await sut.tokenize()
        _ = try await sut.createPayment(tokenData: AchTestData.mockTokenData)
        _ = try await sut.completePayment(stripeData: AchTestData.defaultStripeData)

        // Then
        XCTAssertEqual(mockRepository.loadUserDetailsCallCount, 1)
        XCTAssertEqual(mockRepository.patchUserDetailsCallCount, 1)
        XCTAssertEqual(mockRepository.validateCallCount, 1)
        XCTAssertEqual(mockRepository.startPaymentAndGetStripeDataCallCount, 1)
        XCTAssertEqual(mockRepository.createBankCollectorCallCount, 1)
        XCTAssertEqual(mockRepository.getMandateDataCallCount, 1)
        XCTAssertEqual(mockRepository.tokenizeCallCount, 1)
        XCTAssertEqual(mockRepository.createPaymentCallCount, 1)
        XCTAssertEqual(mockRepository.completePaymentCallCount, 1)
    }
}

// MARK: - Mock Bank Collector Delegate

@available(iOS 15.0, *)
private class MockBankCollectorDelegate: AchBankCollectorDelegate {
    var didSucceedPaymentId: String?
    var didCancelCalled = false
    var didFailError: PrimerError?

    func achBankCollectorDidSucceed(paymentId: String) {
        didSucceedPaymentId = paymentId
    }

    func achBankCollectorDidCancel() {
        didCancelCalled = true
    }

    func achBankCollectorDidFail(error: PrimerError) {
        didFailError = error
    }
}
