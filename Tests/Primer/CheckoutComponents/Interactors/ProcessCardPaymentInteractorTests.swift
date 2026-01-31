//
//  ProcessCardPaymentInteractorTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

/// Tests for ProcessCardPaymentInteractorImpl that handles card payment processing.
@available(iOS 15.0, *)
final class ProcessCardPaymentInteractorTests: XCTestCase {

    private var sut: ProcessCardPaymentInteractorImpl!
    private var mockRepository: MockHeadlessRepository!

    override func setUp() {
        super.setUp()
        mockRepository = MockHeadlessRepository()
        sut = ProcessCardPaymentInteractorImpl(repository: mockRepository)
    }

    override func tearDown() {
        sut = nil
        mockRepository = nil
        super.tearDown()
    }

    // MARK: - Success Tests

    func test_execute_withValidCardData_returnsPaymentResult() async throws {
        // Given
        let cardData = createTestCardData()
        mockRepository.paymentResultToReturn = PaymentResult(
            paymentId: "test-payment-123",
            status: .success
        )

        // When
        let result = try await sut.execute(cardData: cardData)

        // Then
        XCTAssertEqual(result.paymentId, "test-payment-123")
        XCTAssertEqual(result.status, .success)
    }

    func test_execute_callsRepositoryWithCorrectData() async throws {
        // Given
        let cardData = createTestCardData()
        mockRepository.paymentResultToReturn = PaymentResult(
            paymentId: "test-payment",
            status: .success
        )

        // When
        _ = try await sut.execute(cardData: cardData)

        // Then
        XCTAssertEqual(mockRepository.processCardPaymentCallCount, 1)
        XCTAssertEqual(mockRepository.lastCardNumber, cardData.cardNumber)
        XCTAssertEqual(mockRepository.lastCVV, cardData.cvv)
        XCTAssertEqual(mockRepository.lastExpiryMonth, cardData.expiryMonth)
        XCTAssertEqual(mockRepository.lastExpiryYear, cardData.expiryYear)
        XCTAssertEqual(mockRepository.lastCardholderName, cardData.cardholderName)
    }

    func test_execute_withSelectedNetwork_passesNetworkToRepository() async throws {
        // Given
        let cardData = CardPaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: TestData.CVV.valid3Digit,
            expiryMonth: "12",
            expiryYear: "2030",
            cardholderName: TestData.CardholderNames.valid,
            selectedNetwork: .visa,
            billingAddress: nil
        )
        mockRepository.paymentResultToReturn = PaymentResult(
            paymentId: "test-payment",
            status: .success
        )

        // When
        _ = try await sut.execute(cardData: cardData)

        // Then
        XCTAssertEqual(mockRepository.lastSelectedNetwork, .visa)
    }

    // MARK: - Billing Address Tests

    func test_execute_withBillingAddress_setsBillingAddressFirst() async throws {
        // Given
        let billingAddress = BillingAddress(
            firstName: "John",
            lastName: "Doe",
            addressLine1: "123 Main St",
            addressLine2: nil,
            city: "New York",
            state: "NY",
            postalCode: "10001",
            countryCode: "US",
            phoneNumber: nil
        )
        let cardData = CardPaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: TestData.CVV.valid3Digit,
            expiryMonth: "12",
            expiryYear: "2030",
            cardholderName: TestData.CardholderNames.valid,
            selectedNetwork: nil,
            billingAddress: billingAddress
        )
        mockRepository.paymentResultToReturn = PaymentResult(
            paymentId: "test-payment",
            status: .success
        )

        // When
        _ = try await sut.execute(cardData: cardData)

        // Then
        XCTAssertEqual(mockRepository.setBillingAddressCallCount, 1)
        XCTAssertEqual(mockRepository.lastBillingAddress?.firstName, "John")
        XCTAssertEqual(mockRepository.lastBillingAddress?.lastName, "Doe")
        XCTAssertEqual(mockRepository.lastBillingAddress?.postalCode, "10001")
    }

    func test_execute_withoutBillingAddress_doesNotSetBillingAddress() async throws {
        // Given
        let cardData = createTestCardData() // No billing address
        mockRepository.paymentResultToReturn = PaymentResult(
            paymentId: "test-payment",
            status: .success
        )

        // When
        _ = try await sut.execute(cardData: cardData)

        // Then
        XCTAssertEqual(mockRepository.setBillingAddressCallCount, 0)
    }

    // MARK: - Error Tests

    func test_execute_whenPaymentFails_throwsError() async {
        // Given
        let cardData = createTestCardData()
        mockRepository.processCardPaymentError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.execute(cardData: cardData)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
        }
    }

    func test_execute_whenBillingAddressFails_throwsError() async {
        // Given
        let billingAddress = BillingAddress(
            firstName: "John",
            lastName: "Doe",
            addressLine1: "123 Main St",
            addressLine2: nil,
            city: "New York",
            state: "NY",
            postalCode: "10001",
            countryCode: "US",
            phoneNumber: nil
        )
        let cardData = CardPaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: TestData.CVV.valid3Digit,
            expiryMonth: "12",
            expiryYear: "2030",
            cardholderName: TestData.CardholderNames.valid,
            selectedNetwork: nil,
            billingAddress: billingAddress
        )
        mockRepository.setBillingAddressError = TestError.networkFailure

        // When/Then
        do {
            _ = try await sut.execute(cardData: cardData)
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is TestError)
        }

        // Verify billing address was attempted but payment was not
        XCTAssertEqual(mockRepository.setBillingAddressCallCount, 1)
        XCTAssertEqual(mockRepository.processCardPaymentCallCount, 0)
    }

    // MARK: - Helpers

    private func createTestCardData() -> CardPaymentData {
        CardPaymentData(
            cardNumber: TestData.CardNumbers.validVisa,
            cvv: TestData.CVV.valid3Digit,
            expiryMonth: "12",
            expiryYear: "2030",
            cardholderName: TestData.CardholderNames.valid,
            selectedNetwork: nil,
            billingAddress: nil
        )
    }
}
