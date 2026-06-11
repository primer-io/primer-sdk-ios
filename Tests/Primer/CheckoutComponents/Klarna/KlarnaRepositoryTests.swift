//
//  KlarnaRepositoryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
import XCTest
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class KlarnaRepositoryTests: XCTestCase {

    private var sut: MockKlarnaRepository!

    override func setUp() {
        super.setUp()
        sut = MockKlarnaRepository()
    }

    override func tearDown() {
        sut = nil
        super.tearDown()
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
