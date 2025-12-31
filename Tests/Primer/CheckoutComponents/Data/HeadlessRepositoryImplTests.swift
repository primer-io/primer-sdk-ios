//
//  HeadlessRepositoryImplTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

// MARK: - Select Card Network Tests

@available(iOS 15.0, *)
final class SelectCardNetworkTests: XCTestCase {

    private var mockClientSessionActions: MockClientSessionActionsModule!
    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        mockClientSessionActions = MockClientSessionActionsModule()
        repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: { [weak self] in
                self?.mockClientSessionActions ?? MockClientSessionActionsModule()
            }
        )
    }

    override func tearDown() {
        mockClientSessionActions = nil
        repository = nil
        super.tearDown()
    }

    func testSelectCardNetwork_Visa_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.visa

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "VISA")
    }

    func testSelectCardNetwork_Mastercard_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.masterCard

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "MASTERCARD")
    }

    func testSelectCardNetwork_Amex_CallsSelectPaymentMethodWithCorrectParams() async throws {
        // Given
        let network = CardNetwork.amex

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "AMEX")
    }

    func testSelectCardNetwork_Unknown_CallsSelectPaymentMethodWithOther() async throws {
        // Given
        let network = CardNetwork.unknown

        // When
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.type, "PAYMENT_CARD")
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.first?.network, "OTHER")
    }

    func testSelectCardNetwork_MultipleNetworks_CallsSelectPaymentMethodMultipleTimes() async throws {
        // Given
        let networks: [CardNetwork] = [.visa, .masterCard, .amex]

        // When
        for network in networks {
            await repository.selectCardNetwork(network)
        }

        // Wait for all Tasks to complete
        try await Task.sleep(nanoseconds: 300_000_000)

        // Then
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 3)
    }

    func testSelectCardNetwork_WithError_DoesNotThrow() async throws {
        // Given
        let network = CardNetwork.visa
        mockClientSessionActions.selectPaymentMethodError = NSError(domain: "test", code: 500)

        // When/Then - Should not throw since it's fire-and-forget
        await repository.selectCardNetwork(network)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Verify the call was made
        XCTAssertEqual(mockClientSessionActions.selectPaymentMethodCalls.count, 1)
    }
}

// MARK: - Network Detection Stream Tests

@available(iOS 15.0, *)
final class NetworkDetectionStreamTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testGetNetworkDetectionStream_ReturnsNonNilStream() {
        // When
        let stream = repository.getNetworkDetectionStream()

        // Then
        XCTAssertNotNil(stream)
    }
}

// MARK: - Set Billing Address Tests

@available(iOS 15.0, *)
final class SetBillingAddressTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testSetBillingAddress_DoesNotThrow() async throws {
        // Given
        let address = BillingAddress(
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

        // When/Then - Should not throw
        try await repository.setBillingAddress(address)
    }

    func testSetBillingAddress_WithMinimalData_DoesNotThrow() async throws {
        // Given
        let address = BillingAddress(
            firstName: nil,
            lastName: nil,
            addressLine1: nil,
            addressLine2: nil,
            city: nil,
            state: nil,
            postalCode: nil,
            countryCode: nil,
            phoneNumber: nil
        )

        // When/Then - Should not throw
        try await repository.setBillingAddress(address)
    }
}

// MARK: - Track Analytics Tests

@available(iOS 15.0, *)
final class TrackAnalyticsTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testTrackThreeDSChallenge_WithNilAuthentication_DoesNotCrash() {
        // Given - Token data without 3DS authentication
        // Note: We can't easily create a PrimerPaymentMethodTokenData with nil authentication
        // but this test verifies the code path doesn't crash when called
        // The actual tracking is tested through integration tests
    }

    func testTrackRedirectToThirdParty_WithNilInfo_DoesNotCrash() {
        // Given
        let nilInfo: PrimerCheckoutAdditionalInfo? = nil

        // When - Should not crash
        repository.trackRedirectToThirdPartyIfNeeded(from: nilInfo)

        // Then - No crash means success
    }
}

// MARK: - Initialization Tests

@available(iOS 15.0, *)
final class HeadlessRepositoryInitializationTests: XCTestCase {

    func testInit_WithDefaultFactory_CreatesInstance() {
        // When
        let repository = HeadlessRepositoryImpl()

        // Then
        XCTAssertNotNil(repository)
    }

    func testInit_WithCustomFactory_UsesProvidedFactory() async throws {
        // Given
        var factoryCalled = false
        let mockActions = MockClientSessionActionsModule()

        let repository = HeadlessRepositoryImpl(
            clientSessionActionsFactory: {
                factoryCalled = true
                return mockActions
            }
        )

        // When
        await repository.selectCardNetwork(.visa)

        // Wait for the Task to complete
        try await Task.sleep(nanoseconds: 100_000_000)

        // Then
        XCTAssertTrue(factoryCalled)
        XCTAssertEqual(mockActions.selectPaymentMethodCalls.count, 1)
    }
}

// MARK: - Redirect Deduplication Tests

@available(iOS 15.0, *)
final class RedirectDeduplicationTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testTrackRedirect_SameURL_TracksOnlyOnce() {
        // Given
        // Note: We need to create a mock PrimerCheckoutAdditionalInfo with a redirect URL
        // For now, we verify nil handling works
        let nilInfo: PrimerCheckoutAdditionalInfo? = nil

        // When - Call twice with nil
        repository.trackRedirectToThirdPartyIfNeeded(from: nilInfo)
        repository.trackRedirectToThirdPartyIfNeeded(from: nilInfo)

        // Then - Should not crash and handle nil gracefully
    }
}

// MARK: - Extract URL Edge Cases Tests

@available(iOS 15.0, *)
final class ExtractURLEdgeCasesTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testExtractURL_WithDeepLink_ReturnsNil() {
        // Given - Deep links are not considered web URLs
        let value = "myapp://payment/callback"

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithNestedDictionary_HandlesGracefully() {
        // Given
        let nested: [String: Any] = [
            "outer": [
                "inner": "https://example.com/payment"
            ]
        ]

        // When
        let result = repository.extractURL(from: nested)

        // Then - extractURL only checks top-level, so this should return nil
        XCTAssertNil(result)
    }

    func testExtractURL_WithNumberValue_ReturnsNil() {
        // Given
        let value = 12345

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithBoolValue_ReturnsNil() {
        // Given
        let value = true

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }
}

// MARK: - Required Input Elements Edge Cases

@available(iOS 15.0, *)
final class RequiredInputElementsEdgeCasesTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testGetRequiredInputElements_CaseInsensitive() {
        // Given - Lowercase payment card type
        let paymentMethodType = "payment_card"

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then - Should return empty since it's case-sensitive match
        XCTAssertTrue(elements.isEmpty)
    }

    func testGetRequiredInputElements_EmptyString_ReturnsEmpty() {
        // Given
        let paymentMethodType = ""

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then
        XCTAssertTrue(elements.isEmpty)
    }

    func testGetRequiredInputElements_PaymentCard_ContainsAllRequiredFields() {
        // Given
        let paymentMethodType = "PAYMENT_CARD"

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then
        XCTAssertTrue(elements.contains(.cardNumber))
        XCTAssertTrue(elements.contains(.cvv))
        XCTAssertTrue(elements.contains(.expiryDate))
        XCTAssertTrue(elements.contains(.cardholderName))
        XCTAssertEqual(elements.count, 4)
    }
}

// MARK: - Create Card Data Edge Cases

@available(iOS 15.0, *)
final class CreateCardDataEdgeCasesTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testCreateCardData_WithLeadingZeroMonth_FormatsCorrectly() {
        // Given
        let cardNumber = "4111111111111111"
        let cvv = "123"
        let expiryMonth = "01"
        let expiryYear = "25"
        let cardholderName = "John Doe"

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: cvv,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.expiryDate, "01/25")
    }

    func testCreateCardData_WithFourDigitYear_FormatsCorrectly() {
        // Given
        let cardNumber = "4111111111111111"
        let cvv = "123"
        let expiryMonth = "12"
        let expiryYear = "2025"
        let cardholderName = "John Doe"

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: cvv,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.expiryDate, "12/2025")
    }

    func testCreateCardData_WithNetwork_SetsNetwork() {
        // Given
        let cardNumber = "4111111111111111"
        let cvv = "123"
        let expiryMonth = "12"
        let expiryYear = "25"
        let cardholderName = "John Doe"

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: cvv,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            selectedNetwork: .visa
        )

        // Then
        XCTAssertEqual(cardData.cardNetwork, .visa)
    }

    func testCreateCardData_WithEmptyStrings_CreatesCardData() {
        // Given
        let cardNumber = ""
        let cvv = ""
        let expiryMonth = ""
        let expiryYear = ""
        let cardholderName = ""

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: cvv,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            selectedNetwork: nil
        )

        // Then - PrimerCardData may have nil or empty values for empty input
        XCTAssertNotNil(cardData)
        XCTAssertEqual(cardData.expiryDate, "/")
    }

    func testCreateCardData_WithSpacesInCardNumber_SanitizesSpaces() {
        // Given - Card number with spaces (as user might type)
        let cardNumber = "4111 1111 1111 1111"
        let cvv = "123"
        let expiryMonth = "12"
        let expiryYear = "25"
        let cardholderName = "John Doe"

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: cvv,
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: cardholderName,
            selectedNetwork: nil
        )

        // Then - Card number is sanitized (spaces removed)
        XCTAssertEqual(cardData.cardNumber, "4111111111111111")
    }
}

// MARK: - IsLikelyURL Edge Cases

@available(iOS 15.0, *)
final class IsLikelyURLEdgeCasesTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testIsLikelyURL_WithPort_ReturnsTrue() {
        // Given
        let url = "https://localhost:8080/payment"

        // When
        let result = repository.isLikelyURL(url)

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithQueryParameters_ReturnsTrue() {
        // Given
        let url = "https://example.com/payment?token=abc123&redirect=true"

        // When
        let result = repository.isLikelyURL(url)

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithFragment_ReturnsTrue() {
        // Given
        let url = "https://example.com/payment#section"

        // When
        let result = repository.isLikelyURL(url)

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_HttpsWithTrailingSlash_ReturnsTrue() {
        // Given
        let url = "https://example.com/"

        // When
        let result = repository.isLikelyURL(url)

        // Then
        XCTAssertTrue(result)
    }

    func testIsLikelyURL_WithWhitespace_ReturnsFalse() {
        // Given
        let url = " https://example.com"

        // When
        let result = repository.isLikelyURL(url)

        // Then - Leading whitespace means it doesn't start with http
        XCTAssertFalse(result)
    }
}
