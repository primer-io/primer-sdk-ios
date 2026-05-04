//
//  HeadlessRepositoryOneShotContinuationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class OneShotContinuationTests: XCTestCase {

    func test_resumeReturning_deliversValue() async throws {
        // Given
        let expected = 42

        // When
        let result: Int = try await withCheckedThrowingContinuation { continuation in
            let oneShot = OneShotContinuation(continuation)
            oneShot.resume(returning: expected)
        }

        // Then
        XCTAssertEqual(result, expected)
    }

    func test_resumeThrowing_deliversError() async {
        // Given
        let expectedError = TestError.networkFailure

        // When / Then
        do {
            let _: Int = try await withCheckedThrowingContinuation { continuation in
                let oneShot = OneShotContinuation(continuation)
                oneShot.resume(throwing: expectedError)
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, expectedError)
        }
    }

    func test_resumeWithSuccess_deliversValue() async throws {
        // Given
        let expected = "payment-123"

        // When
        let result: String = try await withCheckedThrowingContinuation { continuation in
            let oneShot = OneShotContinuation(continuation)
            oneShot.resume(with: .success(expected))
        }

        // Then
        XCTAssertEqual(result, expected)
    }

    func test_resumeWithFailure_deliversError() async {
        // Given
        let expectedError = TestError.timeout

        // When / Then
        do {
            let _: String = try await withCheckedThrowingContinuation { continuation in
                let oneShot = OneShotContinuation(continuation)
                oneShot.resume(with: .failure(expectedError))
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, expectedError)
        }
    }

    func test_doubleResume_onlyDeliversFirstValue() async throws {
        // Given
        let firstValue = 1

        // When
        let result: Int = try await withCheckedThrowingContinuation { continuation in
            let oneShot = OneShotContinuation(continuation)
            oneShot.resume(returning: firstValue)
            // Second resume should be safely ignored
            oneShot.resume(returning: 999)
        }

        // Then
        XCTAssertEqual(result, firstValue)
    }

    func test_doubleResume_returningThenThrowing_onlyDeliversFirst() async throws {
        // Given
        let expected = "first"

        // When
        let result: String = try await withCheckedThrowingContinuation { continuation in
            let oneShot = OneShotContinuation(continuation)
            oneShot.resume(returning: expected)
            oneShot.resume(throwing: TestError.unknown)
        }

        // Then
        XCTAssertEqual(result, expected)
    }

    func test_doubleResume_throwingThenReturning_onlyDeliversError() async {
        // Given
        let expectedError = TestError.cancelled

        // When / Then
        do {
            let _: Int = try await withCheckedThrowingContinuation { continuation in
                let oneShot = OneShotContinuation(continuation)
                oneShot.resume(throwing: expectedError)
                oneShot.resume(returning: 42)
            }
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertEqual(error as? TestError, expectedError)
        }
    }

    func test_concurrentResumes_onlyOneDelivers() async throws {
        // Given / When
        let result: Int = try await withCheckedThrowingContinuation { continuation in
            let oneShot = OneShotContinuation(continuation)

            DispatchQueue.concurrentPerform(iterations: 10) { index in
                oneShot.resume(returning: index)
            }
        }

        // Then - exactly one value should be delivered (0..9)
        XCTAssertTrue((0 ..< 10).contains(result))
    }
}
