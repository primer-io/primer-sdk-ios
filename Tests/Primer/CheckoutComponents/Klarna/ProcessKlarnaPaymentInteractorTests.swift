//
//  ProcessKlarnaPaymentInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
import XCTest

@available(iOS 15.0, *)
final class ProcessKlarnaPaymentInteractorTests: XCTestCase {

    // MARK: - Properties

    var sut: ProcessKlarnaPaymentInteractorImpl!
    var mockRepository: MockKlarnaRepository!

    // MARK: - Setup & Teardown

    override func setUp() {
        super.setUp()
        mockRepository = MockKlarnaRepository()
        sut = ProcessKlarnaPaymentInteractorImpl(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - createSession Tests

    func test_createSession_success_returnsSessionResult() async throws {
        // Given
        mockRepository.sessionResultToReturn = KlarnaTestData.defaultSessionResult

        // When
        let result = try await sut.createSession()

        // Then
        XCTAssertEqual(result.clientToken, KlarnaTestData.Constants.clientToken)
        XCTAssertEqual(result.sessionId, KlarnaTestData.Constants.sessionId)
        XCTAssertEqual(result.categories.count, 3)
        XCTAssertEqual(mockRepository.createSessionCallCount, 1)
    }

    func test_createSession_failure_throwsError() async {
        // Given
        mockRepository.createSessionError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.createSession()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
            XCTAssertEqual(mockRepository.createSessionCallCount, 1)
        }
    }

    // MARK: - configureForCategory Tests

    func test_configureForCategory_success_returnsView() async throws {
        // Given
        let expectedView = UIView()
        mockRepository.paymentViewToReturn = expectedView

        // When
        let view = try await sut.configureForCategory(
            clientToken: KlarnaTestData.Constants.clientToken,
            categoryId: KlarnaTestData.Constants.categoryPayNow
        )

        // Then
        XCTAssertTrue(view === expectedView)
        XCTAssertEqual(mockRepository.configureForCategoryCallCount, 1)
        XCTAssertEqual(mockRepository.lastClientToken, KlarnaTestData.Constants.clientToken)
        XCTAssertEqual(mockRepository.lastCategoryId, KlarnaTestData.Constants.categoryPayNow)
    }

    func test_configureForCategory_testFlow_returnsNil() async throws {
        // Given
        mockRepository.paymentViewToReturn = nil

        // When
        let view = try await sut.configureForCategory(
            clientToken: KlarnaTestData.Constants.clientToken,
            categoryId: KlarnaTestData.Constants.categoryPayNow
        )

        // Then
        XCTAssertNil(view)
        XCTAssertEqual(mockRepository.configureForCategoryCallCount, 1)
    }

    func test_configureForCategory_failure_throwsError() async {
        // Given
        mockRepository.configureForCategoryError = TestError.networkFailure

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

    // MARK: - authorize Tests

    func test_authorize_approved_returnsApprovedResult() async throws {
        // Given
        mockRepository.authorizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)

        // When
        let result = try await sut.authorize()

        // Then
        XCTAssertEqual(result, .approved(authToken: KlarnaTestData.Constants.authToken))
        XCTAssertEqual(mockRepository.authorizeCallCount, 1)
    }

    func test_authorize_finalizationRequired_returnsFinalizationResult() async throws {
        // Given
        mockRepository.authorizationResultToReturn = .finalizationRequired(authToken: KlarnaTestData.Constants.authToken)

        // When
        let result = try await sut.authorize()

        // Then
        XCTAssertEqual(result, .finalizationRequired(authToken: KlarnaTestData.Constants.authToken))
    }

    func test_authorize_declined_returnsDeclinedResult() async throws {
        // Given
        mockRepository.authorizationResultToReturn = .declined

        // When
        let result = try await sut.authorize()

        // Then
        XCTAssertEqual(result, .declined)
    }

    func test_authorize_failure_throwsError() async {
        // Given
        mockRepository.authorizeError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.authorize()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
        }
    }

    // MARK: - finalize Tests

    func test_finalize_approved_returnsApprovedResult() async throws {
        // Given
        mockRepository.finalizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)

        // When
        let result = try await sut.finalize()

        // Then
        XCTAssertEqual(result, .approved(authToken: KlarnaTestData.Constants.authToken))
        XCTAssertEqual(mockRepository.finalizeCallCount, 1)
    }

    func test_finalize_declined_returnsDeclinedResult() async throws {
        // Given
        mockRepository.finalizationResultToReturn = .declined

        // When
        let result = try await sut.finalize()

        // Then
        XCTAssertEqual(result, .declined)
    }

    func test_finalize_failure_throwsError() async {
        // Given
        mockRepository.finalizeError = TestError.networkFailure

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
        mockRepository.paymentResultToReturn = KlarnaTestData.successPaymentResult

        // When
        let result = try await sut.tokenize(authToken: KlarnaTestData.Constants.authToken)

        // Then
        XCTAssertEqual(result.paymentId, KlarnaTestData.Constants.paymentId)
        XCTAssertEqual(result.status, .success)
        XCTAssertEqual(result.paymentMethodType, PrimerPaymentMethodType.klarna.rawValue)
        XCTAssertEqual(mockRepository.tokenizeCallCount, 1)
        XCTAssertEqual(mockRepository.lastAuthToken, KlarnaTestData.Constants.authToken)
    }

    func test_tokenize_failure_throwsError() async {
        // Given
        mockRepository.tokenizeError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.tokenize(authToken: KlarnaTestData.Constants.authToken)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, .networkFailure)
            XCTAssertEqual(mockRepository.lastAuthToken, KlarnaTestData.Constants.authToken)
        }
    }

    // MARK: - Call Delegation Tests

    func test_allMethods_delegateToRepository() async throws {
        // Given
        mockRepository.sessionResultToReturn = KlarnaTestData.defaultSessionResult
        mockRepository.paymentViewToReturn = UIView()
        mockRepository.authorizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)
        mockRepository.finalizationResultToReturn = .approved(authToken: KlarnaTestData.Constants.authToken)
        mockRepository.paymentResultToReturn = KlarnaTestData.successPaymentResult

        // When
        _ = try await sut.createSession()
        _ = try await sut.configureForCategory(
            clientToken: KlarnaTestData.Constants.clientToken,
            categoryId: KlarnaTestData.Constants.categoryPayNow
        )
        _ = try await sut.authorize()
        _ = try await sut.finalize()
        _ = try await sut.tokenize(authToken: KlarnaTestData.Constants.authToken)

        // Then
        XCTAssertEqual(mockRepository.createSessionCallCount, 1)
        XCTAssertEqual(mockRepository.configureForCategoryCallCount, 1)
        XCTAssertEqual(mockRepository.authorizeCallCount, 1)
        XCTAssertEqual(mockRepository.finalizeCallCount, 1)
        XCTAssertEqual(mockRepository.tokenizeCallCount, 1)
    }
}
