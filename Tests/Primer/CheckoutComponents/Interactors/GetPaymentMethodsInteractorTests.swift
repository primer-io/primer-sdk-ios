//
//  GetPaymentMethodsInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class GetPaymentMethodsInteractorTests: XCTestCase {

    private var sut: GetPaymentMethodsInteractorImpl!
    private var mockRepository: MockHeadlessRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockHeadlessRepository()
        sut = GetPaymentMethodsInteractorImpl(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Success Tests

    func test_execute_returnsPaymentMethodsFromRepository() async throws {
        // Given
        let expectedMethods = [
            InternalPaymentMethod(
                id: "card-1",
                type: "PAYMENT_CARD",
                name: "Credit Card",
                isEnabled: true
            ),
            InternalPaymentMethod(
                id: "paypal-1",
                type: "PAYPAL",
                name: "PayPal",
                isEnabled: true
            )
        ]
        mockRepository.paymentMethodsToReturn = expectedMethods

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertEqual(result[0].id, "card-1")
        XCTAssertEqual(result[0].type, "PAYMENT_CARD")
        XCTAssertEqual(result[1].id, "paypal-1")
        XCTAssertEqual(result[1].type, "PAYPAL")
    }

    func test_execute_withEmptyPaymentMethods_returnsEmptyArray() async throws {
        // Given
        mockRepository.paymentMethodsToReturn = []

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertTrue(result.isEmpty)
    }

    func test_execute_withDisabledPaymentMethods_returnsAllMethods() async throws {
        // Given
        mockRepository.paymentMethodsToReturn = [
            InternalPaymentMethod(
                id: "card-1",
                type: "PAYMENT_CARD",
                name: "Credit Card",
                isEnabled: true
            ),
            InternalPaymentMethod(
                id: "klarna-1",
                type: "KLARNA",
                name: "Klarna",
                isEnabled: false
            )
        ]

        // When
        let result = try await sut.execute()

        // Then
        XCTAssertEqual(result.count, 2)
        XCTAssertTrue(result[0].isEnabled)
        XCTAssertFalse(result[1].isEnabled)
    }

    // MARK: - Error Tests

    func test_execute_whenRepositoryThrowsError_propagatesError() async {
        // Given
        mockRepository.getPaymentMethodsError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.execute()
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
            XCTAssertEqual(error as? TestError, TestError.networkFailure)
        }
    }

    // MARK: - State Change Tests

    func test_execute_repositoryCanReturnDifferentResultsOnSubsequentCalls() async throws {
        // Given - first call returns one method
        mockRepository.paymentMethodsToReturn = [
            InternalPaymentMethod(
                id: "card-1",
                type: "PAYMENT_CARD",
                name: "Credit Card",
                isEnabled: true
            )
        ]

        // When - first call
        let firstResult = try await sut.execute()

        // Given - update for second call
        mockRepository.paymentMethodsToReturn = [
            InternalPaymentMethod(
                id: "card-1",
                type: "PAYMENT_CARD",
                name: "Credit Card",
                isEnabled: true
            ),
            InternalPaymentMethod(
                id: "paypal-1",
                type: "PAYPAL",
                name: "PayPal",
                isEnabled: true
            )
        ]

        // When - second call
        let secondResult = try await sut.execute()

        // Then
        XCTAssertEqual(firstResult.count, 1)
        XCTAssertEqual(secondResult.count, 2)
    }
}
