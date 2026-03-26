//
//  VaultedPaymentMethodDisplayDataTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class VaultedPaymentMethodDisplayDataTests: XCTestCase {

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

    // MARK: - Card Display Data

    func test_cardDisplayData_withAllFields() {
        // Given
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

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertEqual(displayData.name, "John Appleseed")
        XCTAssertEqual(displayData.brandName, "Visa")
        XCTAssertNotNil(displayData.brandIcon)
        XCTAssertEqual(displayData.primaryValue, "•••• 4242")
        XCTAssertNotNil(displayData.secondaryValue)
        XCTAssertTrue(displayData.secondaryValue?.contains("12/26") ?? false)
        XCTAssertFalse(displayData.accessibilityLabel.isEmpty)
    }

    func test_cardDisplayData_withoutCardholderName() {
        // Given
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

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertNil(displayData.name)
        XCTAssertEqual(displayData.brandName, "Mastercard")
        XCTAssertEqual(displayData.primaryValue, "•••• 5678")
    }

    func test_cardDisplayData_withFourDigitYear() {
        // Given
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

        // When / Then
        XCTAssertTrue(vaultedMethod.displayData.secondaryValue?.contains("06/28") ?? false)
    }

    func test_cardDisplayData_withTwoDigitYear() {
        // Given
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

        // When / Then
        XCTAssertTrue(vaultedMethod.displayData.secondaryValue?.contains("06/28") ?? false)
    }

    func test_cardDisplayData_withoutExpiry() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .paymentCard,
            paymentInstrumentData: makePaymentInstrumentData(
                last4Digits: "9999",
                network: "Amex"
            )
        )

        // When / Then
        XCTAssertNil(vaultedMethod.displayData.secondaryValue)
    }

    func test_cardDisplayData_cardOffSessionType() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
            paymentInstrumentType: .cardOffSession,
            paymentInstrumentData: makePaymentInstrumentData(
                last4Digits: "4242",
                network: "Visa"
            )
        )

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertEqual(displayData.brandName, "Visa")
        XCTAssertEqual(displayData.primaryValue, "•••• 4242")
    }

    // MARK: - PayPal Display Data

    func test_payPalDisplayData_withEmailAndName() {
        // Given
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

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertEqual(displayData.name, "John Appleseed")
        XCTAssertEqual(displayData.brandName, "PayPal account")
        XCTAssertNotNil(displayData.primaryValue)
        XCTAssertTrue(displayData.primaryValue?.contains("jo") ?? false)
        XCTAssertTrue(displayData.primaryValue?.contains("@gmail.com") ?? false)
        XCTAssertNil(displayData.secondaryValue)
    }

    func test_payPalDisplayData_withOnlyFirstName() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            paymentInstrumentType: .payPalBillingAgreement,
            paymentInstrumentData: makePaymentInstrumentData(
                externalPayerInfo: ["firstName": "John"]
            )
        )

        // Then
        XCTAssertEqual(vaultedMethod.displayData.name, "John")
    }

    func test_payPalDisplayData_withOnlyLastName() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            paymentInstrumentType: .payPalBillingAgreement,
            paymentInstrumentData: makePaymentInstrumentData(
                externalPayerInfo: ["lastName": "Appleseed"]
            )
        )

        // Then
        XCTAssertEqual(vaultedMethod.displayData.name, "Appleseed")
    }

    func test_payPalDisplayData_withoutPayerInfo() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            paymentInstrumentType: .payPalBillingAgreement,
            paymentInstrumentData: makePaymentInstrumentData()
        )

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertNil(displayData.name)
        XCTAssertNil(displayData.primaryValue)
        XCTAssertEqual(displayData.brandName, "PayPal account")
    }

    // MARK: - Klarna Display Data

    func test_klarnaDisplayData() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.klarna.rawValue,
            paymentInstrumentType: .klarnaCustomerToken,
            paymentInstrumentData: makePaymentInstrumentData()
        )

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertNil(displayData.name)
        XCTAssertEqual(displayData.brandName, "Klarna")
        XCTAssertNotNil(displayData.brandIcon)
    }

    // MARK: - ACH Display Data

    func test_achDisplayData_withAllFields() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue,
            paymentInstrumentType: .stripeAch,
            paymentInstrumentData: makePaymentInstrumentData(
                cardholderName: "Jane Smith",
                bankName: "Chase",
                accountNumberLast4Digits: "9876"
            )
        )

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertEqual(displayData.name, "Jane Smith")
        XCTAssertTrue(displayData.brandName.contains("Chase"))
        XCTAssertTrue(displayData.brandName.contains("Bank account"))
        XCTAssertEqual(displayData.primaryValue, "•••• 9876")
    }

    func test_achDisplayData_withoutBankName() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.stripeAch.rawValue,
            paymentInstrumentType: .stripeAch,
            paymentInstrumentData: makePaymentInstrumentData(
                accountNumberLast4Digits: "1234"
            )
        )

        // Then
        XCTAssertTrue(vaultedMethod.displayData.brandName.contains("Bank"))
    }

    // MARK: - GoCardless Display Data

    func test_goCardlessDisplayData() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.goCardless.rawValue,
            paymentInstrumentType: .goCardlessMandate,
            paymentInstrumentData: makePaymentInstrumentData(
                bankName: "Barclays",
                accountNumberLast4Digits: "5678"
            )
        )

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertTrue(displayData.brandName.contains("Barclays"))
        XCTAssertTrue(displayData.brandName.contains("Direct Debit"))
        XCTAssertEqual(displayData.primaryValue, "•••• 5678")
    }

    // MARK: - Apple Pay / Google Pay Display Data

    func test_applePayDisplayData() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.applePay.rawValue,
            paymentInstrumentType: .applePay,
            paymentInstrumentData: makePaymentInstrumentData()
        )

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertNil(displayData.name)
        XCTAssertEqual(displayData.brandName, "Apple Pay")
        XCTAssertNil(displayData.primaryValue)
        XCTAssertNil(displayData.secondaryValue)
    }

    func test_googlePayDisplayData() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.googlePay.rawValue,
            paymentInstrumentType: .googlePay,
            paymentInstrumentData: makePaymentInstrumentData()
        )

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertNil(displayData.name)
        XCTAssertEqual(displayData.brandName, "Google Pay")
        XCTAssertNil(displayData.primaryValue)
        XCTAssertNil(displayData.secondaryValue)
    }

    // MARK: - Generic/Fallback Display Data

    func test_genericDisplayData_unknownType() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: "UNKNOWN_TYPE",
            paymentInstrumentType: .unknown,
            paymentInstrumentData: makePaymentInstrumentData()
        )

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertNil(displayData.name)
        XCTAssertEqual(displayData.brandName, "UNKNOWN_TYPE")
        XCTAssertNotNil(displayData.brandIcon)
    }

    // MARK: - Accessibility Label

    func test_accessibilityLabel_card_notEmpty() {
        // Given
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

        // When
        let displayData = vaultedMethod.displayData

        // Then
        XCTAssertFalse(displayData.accessibilityLabel.isEmpty)
        XCTAssertTrue(displayData.accessibilityLabel.contains("Visa"))
        XCTAssertTrue(displayData.accessibilityLabel.contains("4242"))
    }

    func test_accessibilityLabel_payPal_notEmpty() {
        // Given
        let vaultedMethod = makeVaultedPaymentMethod(
            paymentMethodType: PrimerPaymentMethodType.payPal.rawValue,
            paymentInstrumentType: .payPalBillingAgreement,
            paymentInstrumentData: makePaymentInstrumentData(
                externalPayerInfo: ["email": "test@example.com"]
            )
        )

        // Then
        XCTAssertTrue(vaultedMethod.displayData.accessibilityLabel.contains("PayPal"))
    }
}

// MARK: - Email Masking Tests

@available(iOS 15.0, *)
final class EmailMaskingTests: XCTestCase {

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

    func test_emailMasking_standardEmail() {
        XCTAssertEqual(getMaskedEmail("john.appleseed@gmail.com"), "jo••••@gmail.com")
    }

    func test_emailMasking_shortLocalPart_twoChars() {
        XCTAssertEqual(getMaskedEmail("jo@example.com"), "jo••••@example.com")
    }

    func test_emailMasking_shortLocalPart_oneChar() {
        XCTAssertEqual(getMaskedEmail("j@example.com"), "j••••@example.com")
    }

    func test_emailMasking_longLocalPart() {
        XCTAssertEqual(getMaskedEmail("verylongemail@domain.org"), "ve••••@domain.org")
    }

    func test_emailMasking_withSubdomain() {
        XCTAssertEqual(getMaskedEmail("user@mail.company.co.uk"), "us••••@mail.company.co.uk")
    }

    func test_emailMasking_withPlusSign() {
        XCTAssertEqual(getMaskedEmail("user+tag@gmail.com"), "us••••@gmail.com")
    }

    func test_emailMasking_withNumbers() {
        XCTAssertEqual(getMaskedEmail("user123@test.com"), "us••••@test.com")
    }
}
