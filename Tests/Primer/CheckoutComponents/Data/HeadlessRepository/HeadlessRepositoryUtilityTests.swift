//
//  HeadlessRepositoryUtilityTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

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

// MARK: - Create Card Data Helper Tests

@available(iOS 15.0, *)
final class CreateCardDataHelperTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testCreateCardData_WithAllNetworks_SetsCorrectly() {
        // Test all major card networks
        let networks: [CardNetwork] = [.visa, .masterCard, .amex, .discover, .jcb, .diners]

        for network in networks {
            // When
            let cardData = repository.createCardData(
                cardNumber: "4242424242424242",
                cvv: "123",
                expiryMonth: "12",
                expiryYear: "27",
                cardholderName: "Test",
                selectedNetwork: network
            )

            // Then
            XCTAssertEqual(cardData.cardNetwork, network, "Failed for network: \(network)")
        }
    }

    func testCreateCardData_WithTabsInCardNumber_DoesNotStripTabs() {
        // Given - Tabs are not stripped, only spaces
        let cardData = repository.createCardData(
            cardNumber: "4242\t4242\t4242\t4242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then - Tabs are NOT stripped (only spaces are)
        XCTAssertEqual(cardData.cardNumber, "4242\t4242\t4242\t4242")
    }

    func testCreateCardData_WithLongCardholderName_PassesAsIs() {
        // Given
        let longName = String(repeating: "A", count: 200)

        // When
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: longName,
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.cardholderName, longName)
    }

    func testCreateCardData_WithSpecialCharactersInName_PassesAsIs() {
        // Given
        let specialName = "José García-Núñez"

        // When
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: specialName,
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.cardholderName, specialName)
    }

    func testCreateCardData_WithLeadingTrailingSpacesInCardNumber_StripsSpaces() {
        // Given
        let cardData = repository.createCardData(
            cardNumber: " 4242424242424242 ",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then - Leading/trailing spaces are stripped
        XCTAssertEqual(cardData.cardNumber, "4242424242424242")
    }
}

// MARK: - URL Helper Tests

@available(iOS 15.0, *)
final class URLHelperTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    // MARK: - isLikelyURL Tests

    func testIsLikelyURL_WithHttpsUrl_ReturnsTrue() {
        XCTAssertTrue(repository.isLikelyURL("https://example.com"))
        XCTAssertTrue(repository.isLikelyURL("https://example.com/path"))
        XCTAssertTrue(repository.isLikelyURL("https://subdomain.example.com"))
    }

    func testIsLikelyURL_WithHttpUrl_ReturnsTrue() {
        XCTAssertTrue(repository.isLikelyURL("http://example.com"))
        XCTAssertTrue(repository.isLikelyURL("http://localhost:8080"))
    }

    func testIsLikelyURL_WithMixedCaseProtocol_ReturnsTrue() {
        XCTAssertTrue(repository.isLikelyURL("HTTPS://example.com"))
        XCTAssertTrue(repository.isLikelyURL("HTTP://example.com"))
        XCTAssertTrue(repository.isLikelyURL("Https://example.com"))
    }

    func testIsLikelyURL_WithNonHttpProtocol_ReturnsFalse() {
        XCTAssertFalse(repository.isLikelyURL("ftp://example.com"))
        XCTAssertFalse(repository.isLikelyURL("myapp://deeplink"))
        XCTAssertFalse(repository.isLikelyURL("file:///path/to/file"))
    }

    func testIsLikelyURL_WithPlainString_ReturnsFalse() {
        XCTAssertFalse(repository.isLikelyURL("example.com"))
        XCTAssertFalse(repository.isLikelyURL("just some text"))
        XCTAssertFalse(repository.isLikelyURL(""))
    }

    func testIsLikelyURL_WithPartialProtocol_ReturnsFalse() {
        XCTAssertFalse(repository.isLikelyURL("htt://example.com"))
        XCTAssertFalse(repository.isLikelyURL("httpexample.com"))
    }

    // MARK: - extractURL Tests

    func testExtractURL_WithString_ReturnsUrl() {
        let result = repository.extractURL(from: "https://example.com/redirect")
        XCTAssertEqual(result, "https://example.com/redirect")
    }

    func testExtractURL_WithURL_ReturnsAbsoluteString() {
        let url = URL(string: "https://example.com/path")!
        let result = repository.extractURL(from: url)
        XCTAssertEqual(result, "https://example.com/path")
    }

    func testExtractURL_WithNonUrlString_ReturnsNil() {
        let result = repository.extractURL(from: "not a url")
        XCTAssertNil(result)
    }

    func testExtractURL_WithNumber_ReturnsNil() {
        let result = repository.extractURL(from: 12345)
        XCTAssertNil(result)
    }

    func testExtractURL_WithEmptyString_ReturnsNil() {
        let result = repository.extractURL(from: "")
        XCTAssertNil(result)
    }
}

// MARK: - Get Required Input Elements Tests

@available(iOS 15.0, *)
final class GetRequiredInputElementsTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testGetRequiredInputElements_ForPaymentCard_ReturnsCardInputs() {
        let result = repository.getRequiredInputElements(for: "PAYMENT_CARD")

        XCTAssertEqual(result.count, 4)
        XCTAssertTrue(result.contains(.cardNumber))
        XCTAssertTrue(result.contains(.cvv))
        XCTAssertTrue(result.contains(.expiryDate))
        XCTAssertTrue(result.contains(.cardholderName))
    }

    func testGetRequiredInputElements_ForPayPal_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "PAYPAL")
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForApplePay_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "APPLE_PAY")
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForGooglePay_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "GOOGLE_PAY")
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForKlarna_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "KLARNA")
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForUnknownType_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "UNKNOWN_PAYMENT_METHOD")
        XCTAssertTrue(result.isEmpty)
    }

    func testGetRequiredInputElements_ForEmptyType_ReturnsEmpty() {
        let result = repository.getRequiredInputElements(for: "")
        XCTAssertTrue(result.isEmpty)
    }
}

// MARK: - Create Card Data Expiry Format Tests

@available(iOS 15.0, *)
final class CreateCardDataExpiryFormatTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }

    func testCreateCardData_ExpiryFormat_StandardFormat() {
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        XCTAssertEqual(cardData.expiryDate, "12/27")
    }

    func testCreateCardData_ExpiryFormat_SingleDigitMonth() {
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "1",
            expiryYear: "28",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        XCTAssertEqual(cardData.expiryDate, "1/28")
    }

    func testCreateCardData_ExpiryFormat_FourDigitYear() {
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "06",
            expiryYear: "2029",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        XCTAssertEqual(cardData.expiryDate, "06/2029")
    }

    func testCreateCardData_EmptyCardholderName_SetsNil() {
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: "",
            selectedNetwork: nil
        )

        XCTAssertNil(cardData.cardholderName)
    }

    func testCreateCardData_NonEmptyCardholderName_SetsValue() {
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "27",
            cardholderName: "John Doe",
            selectedNetwork: nil
        )

        XCTAssertEqual(cardData.cardholderName, "John Doe")
    }
}
