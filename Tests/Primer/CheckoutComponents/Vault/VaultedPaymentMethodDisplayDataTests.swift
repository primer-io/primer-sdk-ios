//
//  VaultedPaymentMethodDisplayDataTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class VaultedPaymentMethodDisplayDataTests: XCTestCase {

    // MARK: - Test Helpers

    private func makePaymentInstrumentData(
        last4Digits: String? = nil,
        expirationMonth: String? = nil,
        expirationYear: String? = nil,
        cardholderName: String? = nil,
        network: String? = nil,
        bankName: String? = nil,
        accountNumberLast4Digits: String? = nil,
        externalPayerInfo: [String: Any]? = nil,
        sessionData: [String: Any]? = nil
    ) -> Response.Body.Tokenization.PaymentInstrumentData {
        var json: [String: Any] = [:]

        if let last4Digits { json["last4Digits"] = last4Digits }
        if let expirationMonth { json["expirationMonth"] = expirationMonth }
        if let expirationYear { json["expirationYear"] = expirationYear }
        if let cardholderName { json["cardholderName"] = cardholderName }
        if let network { json["network"] = network }
        if let bankName { json["bankName"] = bankName }
        if let accountNumberLast4Digits { json["accountNumberLastFourDigits"] = accountNumberLast4Digits }
        if let externalPayerInfo { json["externalPayerInfo"] = externalPayerInfo }
        if let sessionData { json["sessionData"] = sessionData }

        let data = try! JSONSerialization.data(withJSONObject: json) // swiftlint:disable:this force_try
        return try! JSONDecoder().decode(Response.Body.Tokenization.PaymentInstrumentData.self, from: data) // swiftlint:disable:this force_try
    }

    private func makeVaultedPaymentMethod(
        paymentMethodType: String,
        paymentInstrumentType: PaymentInstrumentType,
        paymentInstrumentData: Response.Body.Tokenization.PaymentInstrumentData
    ) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
        PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: UUID().uuidString,
            paymentMethodType: paymentMethodType,
            paymentInstrumentType: paymentInstrumentType,
            paymentInstrumentData: paymentInstrumentData,
            analyticsId: "test-analytics-id"
        )
    }

    // MARK: - Card Display Data Tests

    func testCardDisplayData_WithAllFields() {
        // Given: A card with all fields populated
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: makePaymentInstrumentData(
                last4Digits: "4242",
                expirationMonth: "12",
                expirationYear: "2026",
                cardholderName: "John Appleseed",
                network: "Visa"
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: All fields should be populated correctly
        XCTAssertEqual(displayData.name, "John Appleseed")
        XCTAssertEqual(displayData.brandName, "Visa")
        XCTAssertNotNil(displayData.brandIcon)
        XCTAssertEqual(displayData.primaryValue, "•••• 4242")
        XCTAssertNotNil(displayData.secondaryValue)
        XCTAssertTrue(displayData.secondaryValue?.contains("12/26") ?? false)
        XCTAssertFalse(displayData.accessibilityLabel.isEmpty)
    }

    func testCardDisplayData_WithoutCardholderName() {
        // Given: A card without cardholder name
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: makePaymentInstrumentData(
                last4Digits: "5678",
                expirationMonth: "03",
                expirationYear: "2025",
                network: "Mastercard"
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Name should be nil, other fields populated
        XCTAssertNil(displayData.name)
        XCTAssertEqual(displayData.brandName, "Mastercard")
        XCTAssertEqual(displayData.primaryValue, "•••• 5678")
    }

    func testCardDisplayData_WithFourDigitYear() {
        // Given: A card with 4-digit expiration year
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: makePaymentInstrumentData(
                last4Digits: "1234",
                expirationMonth: "06",
                expirationYear: "2028",
                network: "Visa"
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Year should be formatted to 2 digits
        XCTAssertTrue(displayData.secondaryValue?.contains("06/28") ?? false)
    }

    func testCardDisplayData_WithTwoDigitYear() {
        // Given: A card with 2-digit expiration year
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: makePaymentInstrumentData(
                last4Digits: "1234",
                expirationMonth: "06",
                expirationYear: "28",
                network: "Visa"
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Year should remain as-is
        XCTAssertTrue(displayData.secondaryValue?.contains("06/28") ?? false)
    }

    func testCardDisplayData_WithoutExpiry() {
        // Given: A card without expiry
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: makePaymentInstrumentData(
                last4Digits: "9999",
                network: "Amex"
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Secondary value should be nil
        XCTAssertNil(displayData.secondaryValue)
    }

    func testCardDisplayData_CardOffSessionType() {
        // Given: A card with cardOffSession instrument type
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .cardOffSession,
            paymentInstrumentData: makePaymentInstrumentData(
                last4Digits: "4242",
                network: "Visa"
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Should be handled as card
        XCTAssertEqual(displayData.brandName, "Visa")
        XCTAssertEqual(displayData.primaryValue, "•••• 4242")
    }

    // MARK: - PayPal Display Data Tests

    func testPayPalDisplayData_WithEmailAndName() {
        // Given: PayPal with email and name
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            paymentInstrumentType: .payPalBillingAgreement,
            paymentInstrumentData: makePaymentInstrumentData(
                externalPayerInfo: [
                    "email": "john.appleseed@gmail.com",
                    "firstName": "John",
                    "lastName": "Appleseed"
                ]
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Name and masked email should be present
        XCTAssertEqual(displayData.name, "John Appleseed")
        XCTAssertEqual(displayData.brandName, "PayPal account")
        XCTAssertNotNil(displayData.primaryValue)
        XCTAssertTrue(displayData.primaryValue?.contains("jo") ?? false)
        XCTAssertTrue(displayData.primaryValue?.contains("@gmail.com") ?? false)
        XCTAssertNil(displayData.secondaryValue)
    }

    func testPayPalDisplayData_WithOnlyFirstName() {
        // Given: PayPal with only first name
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            paymentInstrumentType: .payPalBillingAgreement,
            paymentInstrumentData: makePaymentInstrumentData(
                externalPayerInfo: [
                    "firstName": "John"
                ]
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Name should be just first name
        XCTAssertEqual(displayData.name, "John")
    }

    func testPayPalDisplayData_WithOnlyLastName() {
        // Given: PayPal with only last name
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            paymentInstrumentType: .payPalBillingAgreement,
            paymentInstrumentData: makePaymentInstrumentData(
                externalPayerInfo: [
                    "lastName": "Appleseed"
                ]
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Name should be just last name
        XCTAssertEqual(displayData.name, "Appleseed")
    }

    func testPayPalDisplayData_WithoutPayerInfo() {
        // Given: PayPal without payer info
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            paymentInstrumentType: .payPalBillingAgreement,
            paymentInstrumentData: makePaymentInstrumentData()
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Name and primary value should be nil
        XCTAssertNil(displayData.name)
        XCTAssertNil(displayData.primaryValue)
        XCTAssertEqual(displayData.brandName, "PayPal account")
    }

    // MARK: - Klarna Display Data Tests

    func testKlarnaDisplayData() {
        // Given: Klarna payment method
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.klarna.rawValue,
            paymentInstrumentType: .klarnaCustomerToken,
            paymentInstrumentData: makePaymentInstrumentData()
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Should show Klarna brand
        XCTAssertNil(displayData.name)
        XCTAssertEqual(displayData.brandName, "Klarna")
        XCTAssertNotNil(displayData.brandIcon)
    }

    // MARK: - ACH Display Data Tests

    func testACHDisplayData_WithAllFields() {
        // Given: ACH with all fields
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue,
            paymentInstrumentType: .stripeAch,
            paymentInstrumentData: makePaymentInstrumentData(
                cardholderName: "Jane Smith",
                bankName: "Chase",
                accountNumberLast4Digits: "9876"
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: All fields should be populated
        XCTAssertEqual(displayData.name, "Jane Smith")
        XCTAssertTrue(displayData.brandName.contains("Chase"))
        XCTAssertTrue(displayData.brandName.contains("Bank account"))
        XCTAssertEqual(displayData.primaryValue, "•••• 9876")
    }

    func testACHDisplayData_WithoutBankName() {
        // Given: ACH without bank name
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue,
            paymentInstrumentType: .stripeAch,
            paymentInstrumentData: makePaymentInstrumentData(
                accountNumberLast4Digits: "1234"
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Should use default bank name
        XCTAssertTrue(displayData.brandName.contains("Bank"))
    }

    // MARK: - GoCardless Display Data Tests

    func testGoCardlessDisplayData() {
        // Given: GoCardless mandate
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.goCardless.rawValue,
            paymentInstrumentType: .goCardlessMandate,
            paymentInstrumentData: makePaymentInstrumentData(
                bankName: "Barclays",
                accountNumberLast4Digits: "5678"
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Should show Direct Debit
        XCTAssertTrue(displayData.brandName.contains("Barclays"))
        XCTAssertTrue(displayData.brandName.contains("Direct Debit"))
        XCTAssertEqual(displayData.primaryValue, "•••• 5678")
    }

    // MARK: - Apple Pay Display Data Tests

    func testApplePayDisplayData() {
        // Given: Apple Pay
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
            paymentInstrumentType: .applePay,
            paymentInstrumentData: makePaymentInstrumentData()
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Should show Apple Pay
        XCTAssertNil(displayData.name)
        XCTAssertEqual(displayData.brandName, "Apple Pay")
        XCTAssertNil(displayData.primaryValue)
        XCTAssertNil(displayData.secondaryValue)
    }

    // MARK: - Google Pay Display Data Tests

    func testGooglePayDisplayData() {
        // Given: Google Pay
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.googlePay.rawValue,
            paymentInstrumentType: .googlePay,
            paymentInstrumentData: makePaymentInstrumentData()
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Should show Google Pay
        XCTAssertNil(displayData.name)
        XCTAssertEqual(displayData.brandName, "Google Pay")
        XCTAssertNil(displayData.primaryValue)
        XCTAssertNil(displayData.secondaryValue)
    }

    // MARK: - Generic/Fallback Display Data Tests

    func testGenericDisplayData_UnknownType() {
        // Given: Unknown payment method type
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: "UNKNOWN_TYPE",
            paymentInstrumentType: .unknown,
            paymentInstrumentData: makePaymentInstrumentData()
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Should use payment method type as brand name
        XCTAssertNil(displayData.name)
        XCTAssertEqual(displayData.brandName, "UNKNOWN_TYPE")
        XCTAssertNotNil(displayData.brandIcon) // Should have fallback icon
    }

    // MARK: - Accessibility Label Tests

    func testAccessibilityLabel_Card_NotEmpty() {
        // Given: A card
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: makePaymentInstrumentData(
                last4Digits: "4242",
                expirationMonth: "12",
                expirationYear: "2026",
                network: "Visa"
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Accessibility label should not be empty
        XCTAssertFalse(displayData.accessibilityLabel.isEmpty)
        XCTAssertTrue(displayData.accessibilityLabel.contains("Visa"))
        XCTAssertTrue(displayData.accessibilityLabel.contains("4242"))
    }

    func testAccessibilityLabel_PayPal_NotEmpty() {
        // Given: PayPal
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            paymentInstrumentType: .payPalBillingAgreement,
            paymentInstrumentData: makePaymentInstrumentData(
                externalPayerInfo: ["email": "test@example.com"]
            )
        )

        // When: Getting display data
        let displayData = vaultedMethod.displayData

        // Then: Accessibility label should contain PayPal
        XCTAssertTrue(displayData.accessibilityLabel.contains("PayPal"))
    }
}

// MARK: - Email Masking Tests

@available(iOS 15.0, *)
final class EmailMaskingTests: XCTestCase {

    // Helper to access the private maskEmail function via display data
    private func getMaskedEmail(_ email: String) -> String? {
        let data = try! JSONSerialization.data(withJSONObject: [ // swiftlint:disable:this force_try
            "externalPayerInfo": ["email": email]
        ])
        let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
            Response.Body.Tokenization.PaymentInstrumentData.self,
            from: data
        )

        let vaultedMethod = PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
            id: "test",
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            paymentInstrumentType: .payPalBillingAgreement,
            paymentInstrumentData: instrumentData,
            analyticsId: "test"
        )

        return vaultedMethod.displayData.primaryValue
    }

    func testEmailMasking_StandardEmail() {
        // Given: A standard email
        let masked = getMaskedEmail("john.appleseed@gmail.com")

        // Then: Should mask with first 2 characters visible
        XCTAssertEqual(masked, "jo••••@gmail.com")
    }

    func testEmailMasking_ShortLocalPart_TwoChars() {
        // Given: Email with 2-character local part
        let masked = getMaskedEmail("jo@example.com")

        // Then: Should show both characters plus mask
        XCTAssertEqual(masked, "jo••••@example.com")
    }

    func testEmailMasking_ShortLocalPart_OneChar() {
        // Given: Email with 1-character local part
        let masked = getMaskedEmail("j@example.com")

        // Then: Should show character plus mask
        XCTAssertEqual(masked, "j••••@example.com")
    }

    func testEmailMasking_LongLocalPart() {
        // Given: Email with long local part
        let masked = getMaskedEmail("verylongemail@domain.org")

        // Then: Should only show first 2 characters
        XCTAssertEqual(masked, "ve••••@domain.org")
    }

    func testEmailMasking_WithSubdomain() {
        // Given: Email with subdomain
        let masked = getMaskedEmail("user@mail.company.co.uk")

        // Then: Should preserve full domain
        XCTAssertEqual(masked, "us••••@mail.company.co.uk")
    }

    func testEmailMasking_WithPlusSign() {
        // Given: Email with plus addressing
        let masked = getMaskedEmail("user+tag@gmail.com")

        // Then: Should mask normally
        XCTAssertEqual(masked, "us••••@gmail.com")
    }

    func testEmailMasking_WithNumbers() {
        // Given: Email with numbers
        let masked = getMaskedEmail("user123@test.com")

        // Then: Should mask normally
        XCTAssertEqual(masked, "us••••@test.com")
    }
}
