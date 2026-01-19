//
//  SensitiveDataMaskerTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

final class SensitiveDataMaskerTests: XCTestCase {

    var masker: SensitiveDataMasker!

    override func setUp() {
        super.setUp()
        masker = SensitiveDataMasker()
    }

    override func tearDown() {
        masker = nil
        super.tearDown()
    }

    // MARK: - Card Number Masking Tests

    func test_mask_masksStandardCardNumber() async {
        // Given: Text with standard card number format
        let text = "Payment failed for card 4111 1111 1111 1111"

        // When: Masking sensitive data
        let masked = await masker.mask(text: text)

        // Then: Card number should be masked
        XCTAssertFalse(masked.contains("4111 1111 1111 1111"))
        XCTAssertTrue(masked.contains("[REDACTED_CARD]"))
    }

    func test_mask_masksCardNumberWithHyphens() async {
        // Given: Card number with hyphens
        let text = "Card: 4111-1111-1111-1111"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask card with hyphens
        XCTAssertFalse(masked.contains("4111-1111-1111-1111"))
        XCTAssertTrue(masked.contains("[REDACTED_CARD]"))
    }

    func test_mask_masksCardNumberWithoutSpaces() async {
        // Given: Card number without spaces
        let text = "CardNumber: 4111111111111111"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask continuous card number
        XCTAssertFalse(masked.contains("4111111111111111"))
        XCTAssertTrue(masked.contains("[REDACTED_CARD]"))
    }

    func test_mask_masks15DigitAmexCard() async {
        // Given: 15-digit Amex card number
        let text = "Amex card 3782 822463 10005"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask Amex card
        XCTAssertFalse(masked.contains("3782 822463 10005"))
        XCTAssertTrue(masked.contains("[REDACTED_CARD]"))
    }

    func test_mask_masksMultipleCardNumbers() async {
        // Given: Text with multiple card numbers
        let text = "Cards: 4111 1111 1111 1111 and 5555 5555 5555 4444"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Both cards should be masked
        XCTAssertFalse(masked.contains("4111 1111 1111 1111"))
        XCTAssertFalse(masked.contains("5555 5555 5555 4444"))
        XCTAssertEqual(masked.components(separatedBy: "[REDACTED_CARD]").count - 1, 2)
    }

    func test_mask_preservesNonCardNumbers() async {
        // Given: Text with numbers that aren't card numbers
        let text = "Order 12345 total $100.50"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should preserve non-card numbers
        XCTAssertEqual(masked, text)
    }

    // MARK: - CVV/CVC Masking Tests

    func test_mask_masksCVVWith3Digits() async {
        // Given: Text with CVV
        let text = "CVV: 123"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask CVV
        XCTAssertFalse(masked.contains("CVV: 123"))
        XCTAssertTrue(masked.contains("CVV [REDACTED]"))
    }

    func test_mask_masksCVCWith4Digits() async {
        // Given: Text with 4-digit CVC (Amex)
        let text = "CVC: 1234"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask CVC
        XCTAssertFalse(masked.contains("CVC: 1234"))
        XCTAssertTrue(masked.contains("CVC [REDACTED]"))
    }

    func test_mask_masksCVVCaseInsensitive() async {
        // Given: Text with lowercase cvv
        let text = "cvv=456"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask regardless of case
        XCTAssertFalse(masked.contains("456"))
        XCTAssertTrue(masked.contains("[REDACTED]"))
    }

    func test_mask_masksCVVWithColonSeparator() async {
        // Given: CVV with colon separator
        let text = "CVV:789"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask CVV
        XCTAssertFalse(masked.contains("789"))
        XCTAssertTrue(masked.contains("[REDACTED]"))
    }

    // MARK: - Bearer Token Masking Tests

    // Note: Test strings are constructed dynamically to avoid GitGuardian false positives
    private func makeBearerAuthString(token: String, separator: String = " ") -> String {
        "Authorization: " + "Bearer" + separator + token
    }

    private func makeLowercaseBearerAuthString(token: String) -> String {
        "authorization: " + "bearer" + " " + token
    }

    func test_mask_masksBearerToken() async {
        // Given: Text with Bearer token (dynamically constructed to avoid GitGuardian)
        let testToken = "fake_test_token_for_unit_testing_only"
        let text = makeBearerAuthString(token: testToken)

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Token should be masked
        XCTAssertFalse(masked.contains(testToken))
        XCTAssertTrue(masked.contains("[REDACTED_TOKEN]"))
    }

    func test_mask_masksBearerTokenCaseInsensitive() async {
        // Given: Text with lowercase bearer (dynamically constructed)
        let testToken = "abc123def456"
        let text = makeLowercaseBearerAuthString(token: testToken)

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask regardless of case
        XCTAssertFalse(masked.contains(testToken))
        XCTAssertTrue(masked.contains("[REDACTED_TOKEN]"))
    }

    func test_mask_masksBearerTokenWithNoSpace() async {
        // Given: Bearer token without space (dynamically constructed)
        let testToken = "token_abc_123"
        let text = "Authorization:" + "Bearer" + " " + testToken

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask token
        XCTAssertFalse(masked.contains(testToken))
        XCTAssertTrue(masked.contains("[REDACTED_TOKEN]"))
    }

    // MARK: - API Key Masking Tests

    func test_mask_masksAPIKey() async {
        // Given: Text with API key (fake test key)
        let text = "API_KEY: fake_api_key_for_testing"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: API key should be masked
        XCTAssertFalse(masked.contains("fake_api_key_for_testing"))
        XCTAssertTrue(masked.contains("[REDACTED]"))
    }

    func test_mask_masksAPIKeyWithHyphen() async {
        // Given: API-KEY format (fake test key)
        let text = "API-KEY=fake_test_key_1234567890"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask API key
        XCTAssertFalse(masked.contains("fake_test_key_1234567890"))
        XCTAssertTrue(masked.contains("[REDACTED]"))
    }

    func test_mask_masksGenericKeyField() async {
        // Given: Generic "key" field (fake test key)
        let text = "key: fake_key_value_for_test"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask key value
        XCTAssertFalse(masked.contains("fake_key_value_for_test"))
        XCTAssertTrue(masked.contains("[REDACTED]"))
    }

    func test_mask_masksTokenField() async {
        // Given: Generic "token" field (fake test token)
        let text = "token=fake_token_value_for_test"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask token
        XCTAssertFalse(masked.contains("fake_token_value_for_test"))
        XCTAssertTrue(masked.contains("[REDACTED]"))
    }

    // MARK: - Email Masking Tests

    func test_mask_masksStandardEmail() async {
        // Given: Text with email
        let text = "User email: john.doe@example.com"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Email should be masked
        XCTAssertFalse(masked.contains("john.doe@example.com"))
        XCTAssertTrue(masked.contains("[REDACTED_EMAIL]"))
    }

    func test_mask_masksEmailWithPlus() async {
        // Given: Email with plus addressing
        let text = "Email: user+tag@example.com"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask email with plus
        XCTAssertFalse(masked.contains("user+tag@example.com"))
        XCTAssertTrue(masked.contains("[REDACTED_EMAIL]"))
    }

    func test_mask_masksEmailWithHyphen() async {
        // Given: Email with hyphen
        let text = "Contact: first-last@company-name.co.uk"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask email with hyphens
        XCTAssertFalse(masked.contains("first-last@company-name.co.uk"))
        XCTAssertTrue(masked.contains("[REDACTED_EMAIL]"))
    }

    func test_mask_masksMultipleEmails() async {
        // Given: Text with multiple emails
        let text = "From: alice@example.com To: bob@test.org"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Both emails should be masked
        XCTAssertFalse(masked.contains("alice@example.com"))
        XCTAssertFalse(masked.contains("bob@test.org"))
        XCTAssertEqual(masked.components(separatedBy: "[REDACTED_EMAIL]").count - 1, 2)
    }

    // MARK: - Phone Number Masking Tests

    func test_mask_masksUSPhoneNumber() async {
        // Given: Text with US phone number
        let text = "Phone: (555) 123-4567"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Phone number should be masked
        XCTAssertTrue(masked.contains("[REDACTED_PHONE]"))
    }

    func test_mask_masksInternationalPhoneNumber() async {
        // Given: International phone number with country code
        let text = "Call: +1 555 123 4567"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask international number
        XCTAssertTrue(masked.contains("[REDACTED_PHONE]"))
    }

    func test_mask_masksPhoneNumberWithHyphens() async {
        // Given: Phone number with hyphens
        let text = "Tel: 555-123-4567"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask phone with hyphens
        XCTAssertTrue(masked.contains("[REDACTED_PHONE]"))
    }

    func test_mask_masksPhoneNumberWithoutFormatting() async {
        // Given: Phone number without formatting
        let text = "Contact: 5551234567"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should mask unformatted phone
        XCTAssertTrue(masked.contains("[REDACTED_PHONE]"))
    }

    // MARK: - Combined Masking Tests

    func test_mask_masksMultipleSensitiveDataTypes() async {
        // Given: Text with multiple sensitive data types
        // Note: Bearer string constructed dynamically to avoid GitGuardian false positive
        let bearerLine = "Authorization: " + "Bearer" + " " + "abc123def456"
        let text = """
        Payment failed:
        Card: 4111 1111 1111 1111
        CVV: 123
        Email: user@example.com
        Phone: (555) 123-4567
        \(bearerLine)
        """

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: All sensitive data should be masked
        XCTAssertTrue(masked.contains("[REDACTED_CARD]"))
        XCTAssertTrue(masked.contains("CVV [REDACTED]"))
        XCTAssertTrue(masked.contains("[REDACTED_EMAIL]"))
        XCTAssertTrue(masked.contains("[REDACTED_PHONE]"))
        XCTAssertTrue(masked.contains("[REDACTED_TOKEN]"))
    }

    func test_mask_preservesNonSensitiveText() async {
        // Given: Text with no sensitive data
        let text = "Payment successful for Order #12345"

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Text should remain unchanged
        XCTAssertEqual(masked, text)
    }

    func test_mask_handlesEmptyString() async {
        // Given: Empty string
        let text = ""

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should return empty string
        XCTAssertEqual(masked, "")
    }

    func test_mask_handlesStringWithOnlyWhitespace() async {
        // Given: String with only whitespace
        let text = "   \n\t  "

        // When: Masking
        let masked = await masker.mask(text: text)

        // Then: Should preserve whitespace
        XCTAssertEqual(masked, text)
    }
}
