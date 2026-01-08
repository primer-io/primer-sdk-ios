//
//  PaymentMethodMapperTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

/// Tests for PaymentMethodMapperImpl.
@available(iOS 15.0, *)
final class PaymentMethodMapperTests: XCTestCase {

    // MARK: - Test Helpers

    private func createMapper(currency: Currency? = Currency(code: "USD", decimalDigits: 2)) -> PaymentMethodMapperImpl {
        let configService = MockConfigurationService.withDefaultConfiguration()
        configService.currency = currency
        return PaymentMethodMapperImpl(configurationService: configService)
    }

    private func createInternalPaymentMethod(
        id: String = "test-id",
        type: String = "PAYMENT_CARD",
        name: String = "Credit Card",
        surcharge: Int? = nil,
        hasUnknownSurcharge: Bool = false
    ) -> InternalPaymentMethod {
        InternalPaymentMethod(
            id: id,
            type: type,
            name: name,
            isEnabled: true,
            surcharge: surcharge,
            hasUnknownSurcharge: hasUnknownSurcharge
        )
    }

    // MARK: - Basic Mapping Tests

    func test_mapToPublic_mapsIdCorrectly() {
        // Given
        let mapper = createMapper()
        let internalMethod = createInternalPaymentMethod(id: "unique-id-123")

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertEqual(result.id, "unique-id-123")
    }

    func test_mapToPublic_mapsTypeCorrectly() {
        // Given
        let mapper = createMapper()
        let internalMethod = createInternalPaymentMethod(type: "PAYPAL")

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertEqual(result.type, "PAYPAL")
    }

    func test_mapToPublic_mapsNameCorrectly() {
        // Given
        let mapper = createMapper()
        let internalMethod = createInternalPaymentMethod(name: "Apple Pay")

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertEqual(result.name, "Apple Pay")
    }

    // MARK: - Surcharge Formatting Tests

    func test_mapToPublic_noSurcharge_returnsNoAdditionalFee() {
        // Given
        let mapper = createMapper()
        let internalMethod = createInternalPaymentMethod(surcharge: nil, hasUnknownSurcharge: false)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertEqual(result.formattedSurcharge, CheckoutComponentsStrings.noAdditionalFee)
    }

    func test_mapToPublic_zeroSurcharge_returnsNoAdditionalFee() {
        // Given
        let mapper = createMapper()
        let internalMethod = createInternalPaymentMethod(surcharge: 0, hasUnknownSurcharge: false)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertEqual(result.formattedSurcharge, CheckoutComponentsStrings.noAdditionalFee)
    }

    func test_mapToPublic_hasUnknownSurcharge_returnsAdditionalFeeMayApply() {
        // Given
        let mapper = createMapper()
        let internalMethod = createInternalPaymentMethod(surcharge: 100, hasUnknownSurcharge: true)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertEqual(result.formattedSurcharge, CheckoutComponentsStrings.additionalFeeMayApply)
    }

    func test_mapToPublic_withSurcharge_formatsWithPlusPrefix() {
        // Given
        let mapper = createMapper(currency: Currency(code: "USD", decimalDigits: 2))
        let internalMethod = createInternalPaymentMethod(surcharge: 150, hasUnknownSurcharge: false)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertNotNil(result.formattedSurcharge)
        XCTAssertTrue(result.formattedSurcharge?.hasPrefix("+") == true)
    }

    func test_mapToPublic_noCurrency_returnsNoAdditionalFee() {
        // Given
        let mapper = createMapper(currency: nil)
        let internalMethod = createInternalPaymentMethod(surcharge: 100, hasUnknownSurcharge: false)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertEqual(result.formattedSurcharge, CheckoutComponentsStrings.noAdditionalFee)
    }

    func test_mapToPublic_unknownSurcharge_takesPrecedenceOverActualSurcharge() {
        // Given - Both surcharge and hasUnknownSurcharge set
        let mapper = createMapper()
        let internalMethod = createInternalPaymentMethod(surcharge: 500, hasUnknownSurcharge: true)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then - Unknown surcharge message takes precedence
        XCTAssertEqual(result.formattedSurcharge, CheckoutComponentsStrings.additionalFeeMayApply)
    }

    // MARK: - Raw Surcharge Value Tests

    func test_mapToPublic_preservesRawSurchargeValue() {
        // Given
        let mapper = createMapper()
        let internalMethod = createInternalPaymentMethod(surcharge: 250)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertEqual(result.surcharge, 250)
    }

    func test_mapToPublic_preservesHasUnknownSurchargeFlag() {
        // Given
        let mapper = createMapper()
        let internalMethod = createInternalPaymentMethod(hasUnknownSurcharge: true)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertTrue(result.hasUnknownSurcharge)
    }

    // MARK: - Array Mapping Tests

    func test_mapToPublicArray_mapsAllElements() {
        // Given
        let mapper = createMapper()
        let methods = [
            createInternalPaymentMethod(id: "1", type: "PAYMENT_CARD"),
            createInternalPaymentMethod(id: "2", type: "PAYPAL"),
            createInternalPaymentMethod(id: "3", type: "APPLE_PAY")
        ]

        // When
        let results = mapper.mapToPublic(methods)

        // Then
        XCTAssertEqual(results.count, 3)
        XCTAssertEqual(results[0].id, "1")
        XCTAssertEqual(results[1].id, "2")
        XCTAssertEqual(results[2].id, "3")
    }

    func test_mapToPublicArray_emptyArray_returnsEmptyArray() {
        // Given
        let mapper = createMapper()
        let methods: [InternalPaymentMethod] = []

        // When
        let results = mapper.mapToPublic(methods)

        // Then
        XCTAssertTrue(results.isEmpty)
    }

    func test_mapToPublicArray_preservesOrder() {
        // Given
        let mapper = createMapper()
        let methods = [
            createInternalPaymentMethod(name: "First"),
            createInternalPaymentMethod(name: "Second"),
            createInternalPaymentMethod(name: "Third")
        ]

        // When
        let results = mapper.mapToPublic(methods)

        // Then
        XCTAssertEqual(results[0].name, "First")
        XCTAssertEqual(results[1].name, "Second")
        XCTAssertEqual(results[2].name, "Third")
    }
}
