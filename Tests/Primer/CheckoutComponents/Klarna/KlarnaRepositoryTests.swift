//
//  KlarnaRepositoryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
import XCTest

/// Tests for KlarnaRepository protocol contract via MockKlarnaRepository.
/// KlarnaRepositoryImpl requires actual Klarna SDK and network connectivity,
/// so these tests verify the repository interface contract and mock behavior.
@available(iOS 15.0, *)
final class KlarnaRepositoryTests: XCTestCase {

    // MARK: - Properties

    var sut: MockKlarnaRepository!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        sut = MockKlarnaRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
    }

    // MARK: - createSession Tests

    func test_createSession_success_returnsSessionWithCategories() async throws {
        // Given
        sut.sessionResultToReturn = KlarnaTestData.defaultSessionResult

        // When
        let result = try await sut.createSession()

        // Then
        XCTAssertEqual(result.clientToken, KlarnaTestData.Constants.clientToken)
        XCTAssertEqual(result.sessionId, KlarnaTestData.Constants.sessionId)
        XCTAssertEqual(result.categories.count, 3)
        XCTAssertEqual(result.hppSessionId, KlarnaTestData.Constants.hppSessionId)
        XCTAssertEqual(sut.createSessionCallCount, 1)
    }

    func test_createSession_failure_throwsError() async {
        // Given
        sut.createSessionError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    func test_createSession_singleCategory_returnsOneCategory() async throws {
        // Given
        sut.sessionResultToReturn = KlarnaTestData.singleCategorySessionResult

        // When
        let result = try await sut.createSession()

        // Then
        XCTAssertEqual(result.categories.count, 1)
        XCTAssertEqual(result.categories.first?.id, KlarnaTestData.Constants.categoryPayNow)
        XCTAssertNil(result.hppSessionId)
    }

    // MARK: - configureForCategory Tests

    func test_configureForCategory_returnsPaymentView() async throws {
        // Given
        let expectedView = UIView()
        sut.paymentViewToReturn = expectedView

        // When
        let view = try await sut.configureForCategory(
            clientToken: KlarnaTestData.Constants.clientToken,
            categoryId: KlarnaTestData.Constants.categoryPayNow
        )

        // Then
        XCTAssertTrue(view === expectedView)
        XCTAssertEqual(sut.configureForCategoryCallCount, 1)
        XCTAssertEqual(sut.lastClientToken, KlarnaTestData.Constants.clientToken)
        XCTAssertEqual(sut.lastCategoryId, KlarnaTestData.Constants.categoryPayNow)
    }

    func test_configureForCategory_testFlow_returnsNil() async throws {
        // Given
        sut.paymentViewToReturn = nil

        // When
        let view = try await sut.configureForCategory(
            clientToken: KlarnaTestData.Constants.clientToken,
            categoryId: KlarnaTestData.Constants.categoryPayNow
        )

        // Then
        XCTAssertNil(view)
    }

    func test_configureForCategory_failure_throwsError() async {
        // Given
        sut.configureForCategoryError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.configureForCategory(
                clientToken: KlarnaTestData.Constants.clientToken,
                categoryId: KlarnaTestData.Constants.categoryPayNow
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    func test_configureForCategory_capturesParameters() async throws {
        // Given
        sut.paymentViewToReturn = UIView()

        // When
        _ = try await sut.configureForCategory(
            clientToken: "custom_client_token",
            categoryId: "custom_category"
        )

        // Then
        XCTAssertEqual(sut.lastClientToken, "custom_client_token")
        XCTAssertEqual(sut.lastCategoryId, "custom_category")
    }

    // MARK: - authorize Tests

    func test_authorize_approved_returnsApprovedWithToken() async throws {
        // Given
        sut.authorizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)

        // When
        let result = try await sut.authorize()

        // Then
        XCTAssertEqual(result, .approved(authToken: KlarnaTestData.Constants.authToken))
        XCTAssertEqual(sut.authorizeCallCount, 1)
    }

    func test_authorize_finalizationRequired_returnsFinalizationResult() async throws {
        // Given
        sut.authorizationResultToReturn = .finalizationRequired(authToken: KlarnaTestData.Constants.authToken)

        // When
        let result = try await sut.authorize()

        // Then
        XCTAssertEqual(result, .finalizationRequired(authToken: KlarnaTestData.Constants.authToken))
    }

    func test_authorize_declined_returnsDeclined() async throws {
        // Given
        sut.authorizationResultToReturn = .declined

        // When
        let result = try await sut.authorize()

        // Then
        XCTAssertEqual(result, .declined)
    }

    func test_authorize_failure_throwsError() async {
        // Given
        sut.authorizeError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.authorize()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    // MARK: - finalize Tests

    func test_finalize_approved_returnsApprovedWithToken() async throws {
        // Given
        sut.finalizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)

        // When
        let result = try await sut.finalize()

        // Then
        XCTAssertEqual(result, .approved(authToken: KlarnaTestData.Constants.authToken))
        XCTAssertEqual(sut.finalizeCallCount, 1)
    }

    func test_finalize_declined_returnsDeclined() async throws {
        // Given
        sut.finalizationResultToReturn = .declined

        // When
        let result = try await sut.finalize()

        // Then
        XCTAssertEqual(result, .declined)
    }

    func test_finalize_failure_throwsError() async {
        // Given
        sut.finalizeError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.finalize()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    // MARK: - tokenize Tests

    func test_tokenize_success_returnsPaymentResult() async throws {
        // Given
        sut.paymentResultToReturn = KlarnaTestData.successPaymentResult

        // When
        let result = try await sut.tokenize(authToken: KlarnaTestData.Constants.authToken)

        // Then
        XCTAssertEqual(result.paymentId, KlarnaTestData.Constants.paymentId)
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.paymentMethodType, PrimerPaymentMethodType.klarna.rawValue)
        XCTAssertEqual(sut.tokenizeCallCount, 1)
        XCTAssertEqual(sut.lastAuthToken, KlarnaTestData.Constants.authToken)
    }

    func test_tokenize_failure_throwsError() async {
        // Given
        sut.tokenizeError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.tokenize(authToken: KlarnaTestData.Constants.authToken)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    // MARK: - Factory Method Tests

    func test_withSuccessfulSession_hasSessionResult() async throws {
        // Given
        let repository = MockKlarnaRepository.withSuccessfulSession()

        // When
        let result = try await repository.createSession()

        // Then
        XCTAssertEqual(result.categories.count, 3)
    }

    func test_withFullSuccessFlow_allOperationsSucceed() async throws {
        // Given
        let repository = MockKlarnaRepository.withFullSuccessFlow()

        // When
        let session = try await repository.createSession()
        let view = try await repository.configureForCategory(
            clientToken: session.clientToken,
            categoryId: KlarnaTestData.Constants.categoryPayNow
        )
        let authResult = try await repository.authorize()
        let paymentResult = try await repository.tokenize(authToken: KlarnaTestData.Constants.authToken)

        // Then
        XCTAssertEqual(session.categories.count, 3)
        XCTAssertNotNil(view)
        XCTAssertEqual(authResult, .approved(authToken: KlarnaTestData.Constants.authToken))
        XCTAssertEqual(paymentResult.status, .success)
    }

    // MARK: - Reset Tests

    func test_reset_clearsAllState() async throws {
        // Given
        sut.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        sut.paymentViewToReturn = UIView()
        sut.authorizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)
        sut.paymentResultToReturn = KlarnaTestData.successPaymentResult

        _ = try await sut.createSession()
        _ = try await sut.configureForCategory(
            clientToken: KlarnaTestData.Constants.clientToken,
            categoryId: KlarnaTestData.Constants.categoryPayNow
        )
        _ = try await sut.authorize()
        _ = try await sut.tokenize(authToken: KlarnaTestData.Constants.authToken)

        // When
        sut.reset()

        // Then
        XCTAssertEqual(sut.createSessionCallCount, 0)
        XCTAssertEqual(sut.configureForCategoryCallCount, 0)
        XCTAssertEqual(sut.authorizeCallCount, 0)
        XCTAssertEqual(sut.tokenizeCallCount, 0)
        XCTAssertNil(sut.lastClientToken)
        XCTAssertNil(sut.lastCategoryId)
        XCTAssertNil(sut.lastAuthToken)
    }

    // MARK: - KlarnaAuthorizationResult Equatable Tests

    func test_authorizationResult_approved_equatable() {
        let result1 = KlarnaAuthorizationResult.approved(authToken: "token1")
        let result2 = KlarnaAuthorizationResult.approved(authToken: "token1")
        XCTAssertEqual(result1, result2)
    }

    func test_authorizationResult_approved_differentTokens_notEqual() {
        let result1 = KlarnaAuthorizationResult.approved(authToken: "token1")
        let result2 = KlarnaAuthorizationResult.approved(authToken: "token2")
        XCTAssertNotEqual(result1, result2)
    }

    func test_authorizationResult_finalizationRequired_equatable() {
        let result1 = KlarnaAuthorizationResult.finalizationRequired(authToken: "token1")
        let result2 = KlarnaAuthorizationResult.finalizationRequired(authToken: "token1")
        XCTAssertEqual(result1, result2)
    }

    func test_authorizationResult_declined_equatable() {
        let result1 = KlarnaAuthorizationResult.declined
        let result2 = KlarnaAuthorizationResult.declined
        XCTAssertEqual(result1, result2)
    }

    func test_authorizationResult_differentCases_notEqual() {
        let approved = KlarnaAuthorizationResult.approved(authToken: "token")
        let finalization = KlarnaAuthorizationResult.finalizationRequired(authToken: "token")
        let declined = KlarnaAuthorizationResult.declined
        XCTAssertNotEqual(approved, finalization)
        XCTAssertNotEqual(approved, declined)
        XCTAssertNotEqual(finalization, declined)
    }

    // MARK: - KlarnaSessionResult Tests

    func test_sessionResult_storesAllProperties() {
        let categories = KlarnaTestData.allCategories
        let result = KlarnaSessionResult(
            clientToken: "token",
            sessionId: "session",
            categories: categories,
            hppSessionId: "hpp"
        )

        XCTAssertEqual(result.clientToken, "token")
        XCTAssertEqual(result.sessionId, "session")
        XCTAssertEqual(result.categories.count, 3)
        XCTAssertEqual(result.hppSessionId, "hpp")
    }

    func test_sessionResult_nilHppSessionId() {
        let result = KlarnaSessionResult(
            clientToken: "token",
            sessionId: "session",
            categories: [],
            hppSessionId: nil
        )

        XCTAssertNil(result.hppSessionId)
        XCTAssertTrue(result.categories.isEmpty)
    }
}
