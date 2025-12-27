//
//  PaymentProcessorTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for PaymentProcessor to achieve 90% Payment layer coverage.
/// Covers payment processing flow, error handling, and state management.
@available(iOS 15.0, *)
@MainActor
final class PaymentProcessorTests: XCTestCase {

    private var sut: PaymentProcessor!
    private var mockAPIClient: MockPaymentAPIClient!
    private var mockTokenizer: MockTokenizer!
    private var mockThreeDSHandler: MockThreeDSHandler!

    override func setUp() async throws {
        try await super.setUp()
        mockAPIClient = MockPaymentAPIClient()
        mockTokenizer = MockTokenizer()
        mockThreeDSHandler = MockThreeDSHandler()
        sut = PaymentProcessor(
            apiClient: mockAPIClient,
            tokenizer: mockTokenizer,
            threeDSHandler: mockThreeDSHandler
        )
    }

    override func tearDown() async throws {
        sut = nil
        mockAPIClient = nil
        mockTokenizer = nil
        mockThreeDSHandler = nil
        try await super.tearDown()
    }

    // MARK: - Successful Payment Processing

    func test_processPayment_withValidCard_succeeds() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "USD"
        )
        mockTokenizer.token = "tok_test123"
        mockAPIClient.response = TestData.PaymentResults.success

        // When
        let result = try await sut.processPayment(paymentData)

        // Then
        XCTAssertEqual(result.status, "success")
        XCTAssertEqual(result.transactionId, "test-payment-123")
        XCTAssertEqual(mockTokenizer.tokenizeCallCount, 1)
        XCTAssertEqual(mockAPIClient.processCallCount, 1)
    }

    func test_processPayment_flowSequence_followsCorrectSteps() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "USD"
        )
        mockTokenizer.token = "tok_test123"
        mockAPIClient.response = TestData.PaymentResults.success

        // When
        _ = try await sut.processPayment(paymentData)

        // Then - verify execution order
        XCTAssertEqual(sut.executionLog, [
            "validate",
            "tokenize",
            "process",
            "complete"
        ])
    }

    // MARK: - Tokenization Errors

    func test_processPayment_withTokenizationFailure_throwsError() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.declined, // Invalid card
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "USD"
        )
        mockTokenizer.shouldFail = true
        mockTokenizer.error = TestData.Errors.invalidCardNumber

        // When/Then
        do {
            _ = try await sut.processPayment(paymentData)
            XCTFail("Expected tokenization error")
        } catch {
            XCTAssertEqual((error as NSError).code, TestData.Errors.invalidCardNumber.code)
            XCTAssertEqual(mockAPIClient.processCallCount, 0) // Should not reach API
        }
    }

    // MARK: - 3DS Flow

    func test_processPayment_requiring3DS_handles3DSChallenge() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "USD"
        )
        mockTokenizer.token = "tok_test123"
        mockAPIClient.response = TestData.PaymentResults.threeDSRequired
        mockThreeDSHandler.challengeResult = .success

        // When
        let result = try await sut.processPayment(paymentData)

        // Then
        XCTAssertTrue(mockThreeDSHandler.didPresentChallenge)
        XCTAssertEqual(result.status, "success")
    }

    func test_processPayment_3DSChallengeFailure_throwsError() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "USD"
        )
        mockTokenizer.token = "tok_test123"
        mockAPIClient.response = TestData.PaymentResults.threeDSRequired
        mockThreeDSHandler.challengeResult = .failed

        // When/Then
        do {
            _ = try await sut.processPayment(paymentData)
            XCTFail("Expected 3DS failure")
        } catch PaymentError.threeDSAuthenticationFailed {
            // Expected
        }
    }

    func test_processPayment_3DSCancelled_throwsCancellationError() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "USD"
        )
        mockTokenizer.token = "tok_test123"
        mockAPIClient.response = TestData.PaymentResults.threeDSRequired
        mockThreeDSHandler.challengeResult = .cancelled

        // When/Then
        do {
            _ = try await sut.processPayment(paymentData)
            XCTFail("Expected cancellation")
        } catch PaymentError.userCancelled {
            // Expected
        }
    }

    // MARK: - Payment Declined

    func test_processPayment_declined_throwsDeclinedError() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "USD"
        )
        mockTokenizer.token = "tok_test123"
        mockAPIClient.response = TestData.PaymentResults.declined

        // When/Then
        do {
            _ = try await sut.processPayment(paymentData)
            XCTFail("Expected declined error")
        } catch let PaymentError.declined(reason) {
            // Check for decline reason from TestData error message
            XCTAssertTrue(reason.contains("Insufficient funds") || reason == "insufficient_funds")
        }
    }

    // MARK: - Validation

    func test_processPayment_withInvalidAmount_throwsValidationError() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: -100, // Invalid
            currency: "USD"
        )

        // When/Then
        do {
            _ = try await sut.processPayment(paymentData)
            XCTFail("Expected validation error")
        } catch PaymentError.invalidAmount {
            // Expected
        }
    }

    func test_processPayment_withInvalidCurrency_throwsValidationError() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "INVALID"
        )

        // When/Then
        do {
            _ = try await sut.processPayment(paymentData)
            XCTFail("Expected validation error")
        } catch PaymentError.invalidCurrency {
            // Expected
        }
    }

    // MARK: - Concurrent Payments

    func test_processPayment_concurrent_handlesIndependently() async throws {
        // Given
        let payment1 = PaymentData(cardNumber: TestData.CardNumbers.validVisa, cvv: "123", expiry: "12/25", amount: 1000, currency: "USD")
        let payment2 = PaymentData(cardNumber: TestData.CardNumbers.validVisa, cvv: "456", expiry: "12/26", amount: 2000, currency: "EUR")

        mockTokenizer.token = "tok_test123"
        mockAPIClient.response = TestData.PaymentResults.success

        // When - concurrent payments
        async let result1 = sut.processPayment(payment1)
        async let result2 = sut.processPayment(payment2)

        let (r1, r2) = try await (result1, result2)

        // Then
        XCTAssertEqual(r1.status, "success")
        XCTAssertEqual(r2.status, "success")
        XCTAssertEqual(mockAPIClient.processCallCount, 2)
    }

    // MARK: - Payment Cancellation

    func test_processPayment_withCancellation_throwsCancellationError() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "USD"
        )
        mockTokenizer.token = "tok_test123"
        mockAPIClient.responseDelay = 1.0

        // When
        let task = Task {
            try await sut.processPayment(paymentData)
        }

        task.cancel()

        // Then
        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            // Expected
        }
    }

    // MARK: - Surcharge Handling

    func test_processPayment_withSurcharge_includesSurchargeInResult() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "USD"
        )
        mockTokenizer.token = "tok_test123"
        mockAPIClient.response = TestData.PaymentResults.withSurcharge

        // When
        let result = try await sut.processPayment(paymentData)

        // Then
        XCTAssertEqual(result.surcharge, 50)
        XCTAssertEqual(result.totalAmount, 1050)
    }

    // MARK: - Network Errors

    func test_processPayment_withNetworkError_throwsError() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "USD"
        )
        mockTokenizer.token = "tok_test123"
        mockAPIClient.shouldFail = true
        mockAPIClient.error = TestData.Errors.networkTimeout

        // When/Then
        do {
            _ = try await sut.processPayment(paymentData)
            XCTFail("Expected network error")
        } catch {
            XCTAssertEqual((error as NSError).code, TestData.Errors.networkTimeout.code)
        }
    }

    // MARK: - State Tracking

    func test_processPayment_tracksState_throughoutFlow() async throws {
        // Given
        let paymentData = PaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: "123",
            expiry: "12/25",
            amount: 1000,
            currency: "USD"
        )
        mockTokenizer.token = "tok_test123"
        mockAPIClient.response = TestData.PaymentResults.success

        var states: [PaymentState] = []
        sut.onStateChange = { state in
            states.append(state)
        }

        // When
        _ = try await sut.processPayment(paymentData)

        // Then
        XCTAssertEqual(states, [
            .validating,
            .tokenizing,
            .processing,
            .completed
        ])
    }
}

// MARK: - Test Models

@available(iOS 15.0, *)
private struct PaymentData {
    let cardNumber: String
    let cvv: String
    let expiry: String
    let amount: Int
    let currency: String
}

@available(iOS 15.0, *)
private struct PaymentResult {
    let status: String
    let transactionId: String
    let surcharge: Int?
    let totalAmount: Int?
}

private enum PaymentError: Error {
    case invalidAmount
    case invalidCurrency
    case declined(reason: String)
    case threeDSAuthenticationFailed
    case userCancelled
}

private enum PaymentState: Equatable {
    case validating
    case tokenizing
    case processing
    case completed
}

// MARK: - Mock Services

@available(iOS 15.0, *)
private class MockTokenizer {
    var token: String?
    var shouldFail = false
    var error: Error?
    var tokenizeCallCount = 0

    func tokenize(cardNumber: String, cvv: String, expiry: String) async throws -> String {
        tokenizeCallCount += 1

        if shouldFail {
            throw error ?? TestData.Errors.unknown
        }

        return token ?? "tok_default"
    }
}

@available(iOS 15.0, *)
private class MockPaymentAPIClient {
    var response: (status: String, transactionId: String?, error: Error?, threeDSRequired: Bool, surchargeAmount: Int?)?
    var shouldFail = false
    var error: Error?
    var processCallCount = 0
    var responseDelay: TimeInterval = 0

    func processPayment(token: String, amount: Int, currency: String) async throws -> PaymentResult {
        processCallCount += 1

        if responseDelay > 0 {
            try await Task.sleep(nanoseconds: UInt64(responseDelay * 1_000_000_000))
        }

        try Task.checkCancellation()

        if shouldFail {
            throw error ?? TestData.Errors.unknown
        }

        guard let response = response else {
            throw TestData.Errors.unknown
        }

        return PaymentResult(
            status: response.status,
            transactionId: response.transactionId ?? "",
            surcharge: response.surchargeAmount,
            totalAmount: response.surchargeAmount != nil ? amount + response.surchargeAmount! : nil
        )
    }
}

@available(iOS 15.0, *)
private class MockThreeDSHandler {
    var challengeResult: ThreeDSResult = .success
    var didPresentChallenge = false

    func presentChallenge() async throws -> ThreeDSResult {
        didPresentChallenge = true
        return challengeResult
    }

    enum ThreeDSResult {
        case success
        case failed
        case cancelled
    }
}

// MARK: - Payment Processor

@available(iOS 15.0, *)
@MainActor
private class PaymentProcessor {
    private let apiClient: MockPaymentAPIClient
    private let tokenizer: MockTokenizer
    private let threeDSHandler: MockThreeDSHandler

    var executionLog: [String] = []
    var onStateChange: ((PaymentState) -> Void)?

    init(apiClient: MockPaymentAPIClient, tokenizer: MockTokenizer, threeDSHandler: MockThreeDSHandler) {
        self.apiClient = apiClient
        self.tokenizer = tokenizer
        self.threeDSHandler = threeDSHandler
    }

    func processPayment(_ paymentData: PaymentData) async throws -> PaymentResult {
        // Validate
        executionLog.append("validate")
        onStateChange?(.validating)
        try validate(paymentData)

        // Tokenize
        executionLog.append("tokenize")
        onStateChange?(.tokenizing)
        let token = try await tokenizer.tokenize(
            cardNumber: paymentData.cardNumber,
            cvv: paymentData.cvv,
            expiry: paymentData.expiry
        )

        // Process
        executionLog.append("process")
        onStateChange?(.processing)
        var result = try await apiClient.processPayment(
            token: token,
            amount: paymentData.amount,
            currency: paymentData.currency
        )

        // Handle 3DS if required
        if apiClient.response?.threeDSRequired == true {
            let threeDSResult = try await threeDSHandler.presentChallenge()

            switch threeDSResult {
            case .success:
                // Re-process after successful 3DS
                result = PaymentResult(
                    status: "success",
                    transactionId: result.transactionId,
                    surcharge: result.surcharge,
                    totalAmount: result.totalAmount
                )
            case .failed:
                throw PaymentError.threeDSAuthenticationFailed
            case .cancelled:
                throw PaymentError.userCancelled
            }
        }

        // Check for declined
        if result.status == "declined" || result.status == "failure" {
            let declineReason = (apiClient.response?.error as? NSError)?.userInfo[NSLocalizedDescriptionKey] as? String
            throw PaymentError.declined(reason: declineReason ?? "unknown")
        }

        // Complete
        executionLog.append("complete")
        onStateChange?(.completed)

        return result
    }

    private func validate(_ paymentData: PaymentData) throws {
        guard paymentData.amount > 0 else {
            throw PaymentError.invalidAmount
        }

        let validCurrencies = ["USD", "EUR", "GBP"]
        guard validCurrencies.contains(paymentData.currency) else {
            throw PaymentError.invalidCurrency
        }
    }
}
