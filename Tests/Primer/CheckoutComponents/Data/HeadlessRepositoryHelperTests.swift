//
//  HeadlessRepositoryHelperTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for HeadlessRepositoryImpl helper methods (pure functions)
@available(iOS 15.0, *)
final class HeadlessRepositoryHelperTests: XCTestCase {

    private var repository: HeadlessRepositoryImpl!

    override func setUp() {
        super.setUp()
        repository = HeadlessRepositoryImpl()
    }

    override func tearDown() {
        repository = nil
        super.tearDown()
    }
}

// MARK: - extractFromNetworksArray Tests

@available(iOS 15.0, *)
extension HeadlessRepositoryHelperTests {

    func testExtractFromNetworksArray_WithNestedSurchargeAmount_ReturnsSurcharges() {
        // Given
        let networksArray: [[String: Any]] = [
            [
                "type": "VISA",
                "surcharge": ["amount": 150, "currency": "GBP"]
            ],
            [
                "type": "MASTERCARD",
                "surcharge": ["amount": 200, "currency": "GBP"]
            ]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["VISA"], 150)
        XCTAssertEqual(result?["MASTERCARD"], 200)
    }

    func testExtractFromNetworksArray_WithDirectSurchargeInteger_ReturnsSurcharges() {
        // Given
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": 100],
            ["type": "AMEX", "surcharge": 250]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["VISA"], 100)
        XCTAssertEqual(result?["AMEX"], 250)
    }

    func testExtractFromNetworksArray_WithMixedFormats_ReturnsSurcharges() {
        // Given
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 150]],
            ["type": "MASTERCARD", "surcharge": 200]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["VISA"], 150)
        XCTAssertEqual(result?["MASTERCARD"], 200)
    }

    func testExtractFromNetworksArray_WithZeroSurcharge_ExcludesNetwork() {
        // Given
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": 150]],
            ["type": "MASTERCARD", "surcharge": ["amount": 0]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["VISA"], 150)
        XCTAssertNil(result?["MASTERCARD"])
    }

    func testExtractFromNetworksArray_WithNoSurcharges_ReturnsNil() {
        // Given
        let networksArray: [[String: Any]] = [
            ["type": "VISA"],
            ["type": "MASTERCARD"]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksArray_WithEmptyArray_ReturnsNil() {
        // Given
        let networksArray: [[String: Any]] = []

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksArray_WithMissingType_SkipsNetwork() {
        // Given
        let networksArray: [[String: Any]] = [
            ["surcharge": ["amount": 150]], // missing type
            ["type": "VISA", "surcharge": ["amount": 200]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?.count, 1)
        XCTAssertEqual(result?["VISA"], 200)
    }

    func testExtractFromNetworksArray_WithNegativeSurcharge_ExcludesNetwork() {
        // Given
        let networksArray: [[String: Any]] = [
            ["type": "VISA", "surcharge": ["amount": -100]],
            ["type": "MASTERCARD", "surcharge": ["amount": 150]]
        ]

        // When
        let result = repository.extractFromNetworksArray(networksArray)

        // Then
        XCTAssertNotNil(result)
        XCTAssertNil(result?["VISA"])
        XCTAssertEqual(result?["MASTERCARD"], 150)
    }
}

// MARK: - extractFromNetworksDict Tests

@available(iOS 15.0, *)
extension HeadlessRepositoryHelperTests {

    func testExtractFromNetworksDict_WithNestedSurchargeAmount_ReturnsSurcharges() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 150]],
            "MASTERCARD": ["surcharge": ["amount": 200]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["VISA"], 150)
        XCTAssertEqual(result?["MASTERCARD"], 200)
    }

    func testExtractFromNetworksDict_WithDirectSurchargeInteger_ReturnsSurcharges() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": 100],
            "AMEX": ["surcharge": 250]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["VISA"], 100)
        XCTAssertEqual(result?["AMEX"], 250)
    }

    func testExtractFromNetworksDict_WithZeroSurcharge_ExcludesNetwork() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 150]],
            "MASTERCARD": ["surcharge": ["amount": 0]]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["VISA"], 150)
        XCTAssertNil(result?["MASTERCARD"])
    }

    func testExtractFromNetworksDict_WithNoSurcharges_ReturnsNil() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": [:],
            "MASTERCARD": [:]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksDict_WithEmptyDict_ReturnsNil() {
        // Given
        let networksDict: [String: [String: Any]] = [:]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertNil(result)
    }

    func testExtractFromNetworksDict_WithMixedFormats_ReturnsSurcharges() {
        // Given
        let networksDict: [String: [String: Any]] = [
            "VISA": ["surcharge": ["amount": 150, "currency": "GBP"]],
            "MASTERCARD": ["surcharge": 200]
        ]

        // When
        let result = repository.extractFromNetworksDict(networksDict)

        // Then
        XCTAssertNotNil(result)
        XCTAssertEqual(result?["VISA"], 150)
        XCTAssertEqual(result?["MASTERCARD"], 200)
    }
}

// MARK: - isLikelyURL Tests

@available(iOS 15.0, *)
extension HeadlessRepositoryHelperTests {

    func testIsLikelyURL_WithHttpsPrefix_ReturnsTrue() {
        XCTAssertTrue(repository.isLikelyURL("https://example.com"))
        XCTAssertTrue(repository.isLikelyURL("https://www.primer.io/checkout"))
        XCTAssertTrue(repository.isLikelyURL("https://api.primer.io/v1/payments"))
    }

    func testIsLikelyURL_WithHttpPrefix_ReturnsTrue() {
        XCTAssertTrue(repository.isLikelyURL("http://example.com"))
        XCTAssertTrue(repository.isLikelyURL("http://localhost:3000"))
    }

    func testIsLikelyURL_WithUppercasePrefix_ReturnsTrue() {
        XCTAssertTrue(repository.isLikelyURL("HTTPS://EXAMPLE.COM"))
        XCTAssertTrue(repository.isLikelyURL("HTTP://EXAMPLE.COM"))
        XCTAssertTrue(repository.isLikelyURL("Https://Example.com"))
    }

    func testIsLikelyURL_WithoutHttpPrefix_ReturnsFalse() {
        XCTAssertFalse(repository.isLikelyURL("example.com"))
        XCTAssertFalse(repository.isLikelyURL("www.example.com"))
        XCTAssertFalse(repository.isLikelyURL("ftp://example.com"))
    }

    func testIsLikelyURL_WithEmptyString_ReturnsFalse() {
        XCTAssertFalse(repository.isLikelyURL(""))
    }

    func testIsLikelyURL_WithRandomString_ReturnsFalse() {
        XCTAssertFalse(repository.isLikelyURL("not a url"))
        XCTAssertFalse(repository.isLikelyURL("12345"))
        XCTAssertFalse(repository.isLikelyURL("payment_token_abc123"))
    }

    func testIsLikelyURL_WithDeepLink_ReturnsFalse() {
        XCTAssertFalse(repository.isLikelyURL("myapp://payment/callback"))
        XCTAssertFalse(repository.isLikelyURL("primer://checkout"))
    }

    func testIsLikelyURL_WithPartialPrefix_ReturnsFalse() {
        XCTAssertFalse(repository.isLikelyURL("httpexample.com"))
        XCTAssertFalse(repository.isLikelyURL("httpsexample.com"))
    }
}

// MARK: - createCardData Tests

@available(iOS 15.0, *)
extension HeadlessRepositoryHelperTests {

    func testCreateCardData_FormatsExpiryDateCorrectly() {
        // Given
        let cardNumber = "4242424242424242"
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

        // Then
        XCTAssertEqual(cardData.expiryDate, "12/25")
    }

    func testCreateCardData_SanitizesCardNumberWithSpaces() {
        // Given
        let cardNumber = "4242 4242 4242 4242"

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: "123",
            expiryMonth: "01",
            expiryYear: "26",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.cardNumber, "4242424242424242")
    }

    func testCreateCardData_SetsCardholderName() {
        // Given
        let cardholderName = "Jane Smith"

        // When
        let cardData = repository.createCardData(
            cardNumber: "5555555555554444",
            cvv: "456",
            expiryMonth: "06",
            expiryYear: "27",
            cardholderName: cardholderName,
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.cardholderName, cardholderName)
    }

    func testCreateCardData_WithEmptyCardholderName_SetsNil() {
        // Given
        let cardholderName = ""

        // When
        let cardData = repository.createCardData(
            cardNumber: "5555555555554444",
            cvv: "456",
            expiryMonth: "06",
            expiryYear: "27",
            cardholderName: cardholderName,
            selectedNetwork: nil
        )

        // Then
        XCTAssertNil(cardData.cardholderName)
    }

    func testCreateCardData_SetsCvv() {
        // When
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "789",
            expiryMonth: "03",
            expiryYear: "28",
            cardholderName: "Test User",
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.cvv, "789")
    }

    func testCreateCardData_WithFourDigitCvv_SetsCorrectly() {
        // Given - Amex uses 4-digit CVV
        let cvv = "1234"

        // When
        let cardData = repository.createCardData(
            cardNumber: "378282246310005",
            cvv: cvv,
            expiryMonth: "09",
            expiryYear: "29",
            cardholderName: "Amex User",
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.cvv, "1234")
    }

    func testCreateCardData_WithSelectedNetwork_SetsNetwork() {
        // Given
        let selectedNetwork = CardNetwork.visa

        // When
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test User",
            selectedNetwork: selectedNetwork
        )

        // Then
        XCTAssertEqual(cardData.cardNetwork, .visa)
    }

    func testCreateCardData_WithNilNetwork_DoesNotSetNetwork() {
        // When
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test User",
            selectedNetwork: nil
        )

        // Then
        XCTAssertNil(cardData.cardNetwork)
    }

    func testCreateCardData_WithMultipleSpacesInCardNumber_RemovesAll() {
        // Given
        let cardNumber = "4242  4242  4242  4242"

        // When
        let cardData = repository.createCardData(
            cardNumber: cardNumber,
            cvv: "123",
            expiryMonth: "01",
            expiryYear: "26",
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.cardNumber, "4242424242424242")
    }

    func testCreateCardData_WithSingleDigitMonth_FormatsCorrectly() {
        // Given
        let expiryMonth = "1"
        let expiryYear = "30"

        // When
        let cardData = repository.createCardData(
            cardNumber: "4242424242424242",
            cvv: "123",
            expiryMonth: expiryMonth,
            expiryYear: expiryYear,
            cardholderName: "Test",
            selectedNetwork: nil
        )

        // Then
        XCTAssertEqual(cardData.expiryDate, "1/30")
    }

    func testCreateCardData_WithMasterCardNetwork_SetsCorrectly() {
        // When
        let cardData = repository.createCardData(
            cardNumber: "5555555555554444",
            cvv: "123",
            expiryMonth: "12",
            expiryYear: "25",
            cardholderName: "Test User",
            selectedNetwork: .masterCard
        )

        // Then
        XCTAssertEqual(cardData.cardNetwork, .masterCard)
    }
}

// MARK: - getRequiredInputElements Tests

@available(iOS 15.0, *)
extension HeadlessRepositoryHelperTests {

    func testGetRequiredInputElements_ForPaymentCard_ReturnsAllCardFields() {
        // Given
        let paymentMethodType = PrimerPaymentMethodType.paymentCard.rawValue

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then
        XCTAssertEqual(elements.count, 4)
        XCTAssertTrue(elements.contains(.cardNumber))
        XCTAssertTrue(elements.contains(.cvv))
        XCTAssertTrue(elements.contains(.expiryDate))
        XCTAssertTrue(elements.contains(.cardholderName))
    }

    func testGetRequiredInputElements_ForPaymentCard_ReturnsCorrectOrder() {
        // Given
        let paymentMethodType = PrimerPaymentMethodType.paymentCard.rawValue

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then - verify the expected order
        XCTAssertEqual(elements[0], .cardNumber)
        XCTAssertEqual(elements[1], .cvv)
        XCTAssertEqual(elements[2], .expiryDate)
        XCTAssertEqual(elements[3], .cardholderName)
    }

    func testGetRequiredInputElements_ForPayPal_ReturnsEmptyArray() {
        // Given
        let paymentMethodType = PrimerPaymentMethodType.payPal.rawValue

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then
        XCTAssertTrue(elements.isEmpty)
    }

    func testGetRequiredInputElements_ForApplePay_ReturnsEmptyArray() {
        // Given
        let paymentMethodType = PrimerPaymentMethodType.applePay.rawValue

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then
        XCTAssertTrue(elements.isEmpty)
    }

    func testGetRequiredInputElements_ForUnknownType_ReturnsEmptyArray() {
        // Given
        let paymentMethodType = "UNKNOWN_PAYMENT_METHOD"

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then
        XCTAssertTrue(elements.isEmpty)
    }

    func testGetRequiredInputElements_ForEmptyString_ReturnsEmptyArray() {
        // Given
        let paymentMethodType = ""

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then
        XCTAssertTrue(elements.isEmpty)
    }

    func testGetRequiredInputElements_ForGooglePay_ReturnsEmptyArray() {
        // Given
        let paymentMethodType = PrimerPaymentMethodType.googlePay.rawValue

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then
        XCTAssertTrue(elements.isEmpty)
    }

    func testGetRequiredInputElements_ForKlarna_ReturnsEmptyArray() {
        // Given
        let paymentMethodType = PrimerPaymentMethodType.klarna.rawValue

        // When
        let elements = repository.getRequiredInputElements(for: paymentMethodType)

        // Then
        XCTAssertTrue(elements.isEmpty)
    }
}

// MARK: - extractURL Tests

@available(iOS 15.0, *)
extension HeadlessRepositoryHelperTests {

    func testExtractURL_WithHttpsString_ReturnsURL() {
        // Given
        let value: Any = "https://example.com/callback"

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertEqual(result, "https://example.com/callback")
    }

    func testExtractURL_WithHttpString_ReturnsURL() {
        // Given
        let value: Any = "http://localhost:3000/webhook"

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertEqual(result, "http://localhost:3000/webhook")
    }

    func testExtractURL_WithURLObject_ReturnsAbsoluteString() {
        // Given
        let url = URL(string: "https://primer.io/checkout")!
        let value: Any = url

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertEqual(result, "https://primer.io/checkout")
    }

    func testExtractURL_WithNonURLString_ReturnsNil() {
        // Given
        let value: Any = "not-a-url"

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithEmptyString_ReturnsNil() {
        // Given
        let value: Any = ""

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithInteger_ReturnsNil() {
        // Given
        let value: Any = 12345

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithDictionary_ReturnsNil() {
        // Given
        let value: Any = ["key": "value"]

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithArray_ReturnsNil() {
        // Given
        let value: Any = ["item1", "item2"]

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithDeepLink_ReturnsNil() {
        // Given - deep links don't have http/https prefix
        let value: Any = "myapp://callback"

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithBool_ReturnsNil() {
        // Given
        let value: Any = true

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithNil_ReturnsNil() {
        // Given
        let value: Any? = nil

        // When
        let result: String? = {
            guard let v = value else { return nil }
            return repository.extractURL(from: v)
        }()

        // Then
        XCTAssertNil(result)
    }

    func testExtractURL_WithComplexURL_ReturnsURL() {
        // Given
        let value: Any = "https://api.primer.io/v1/payments?token=abc123&redirect=true"

        // When
        let result = repository.extractURL(from: value)

        // Then
        XCTAssertEqual(result, "https://api.primer.io/v1/payments?token=abc123&redirect=true")
    }
}
