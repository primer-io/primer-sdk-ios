//
//  PaymentMethodMapperTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class PaymentMethodMapperTests: XCTestCase {

    // MARK: - Test Helpers

    private func createMapper(currency: Currency? = Currency(code: TestData.Currencies.usd, decimalDigits: TestData.Currencies.defaultDecimalDigits)) -> PaymentMethodMapperImpl {
        let configService = MockConfigurationService.withDefaultConfiguration()
        configService.currency = currency
        return PaymentMethodMapperImpl(configurationService: configService)
    }

    private func createInternalPaymentMethod(
        id: String = TestData.PaymentMethod.testId,
        type: String = TestData.PaymentMethod.paymentCard,
        name: String = TestData.PaymentMethod.creditCard,
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
        let internalMethod = createInternalPaymentMethod(surcharge: TestData.Surcharges.amount100, hasUnknownSurcharge: true)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertEqual(result.formattedSurcharge, CheckoutComponentsStrings.additionalFeeMayApply)
    }

    func test_mapToPublic_withSurcharge_formatsWithPlusPrefix() {
        // Given
        let mapper = createMapper(currency: Currency(code: TestData.Currencies.usd, decimalDigits: TestData.Currencies.defaultDecimalDigits))
        let internalMethod = createInternalPaymentMethod(surcharge: TestData.Surcharges.amount150, hasUnknownSurcharge: false)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertNotNil(result.formattedSurcharge)
        XCTAssertTrue(result.formattedSurcharge?.hasPrefix("+") == true)
    }

    func test_mapToPublic_noCurrency_returnsNoAdditionalFee() {
        // Given
        let mapper = createMapper(currency: nil)
        let internalMethod = createInternalPaymentMethod(surcharge: TestData.Surcharges.amount100, hasUnknownSurcharge: false)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then
        XCTAssertEqual(result.formattedSurcharge, CheckoutComponentsStrings.noAdditionalFee)
    }

    func test_mapToPublic_unknownSurcharge_takesPrecedenceOverActualSurcharge() {
        // Given - Both surcharge and hasUnknownSurcharge set
        let mapper = createMapper()
        let internalMethod = createInternalPaymentMethod(surcharge: TestData.Surcharges.amount500, hasUnknownSurcharge: true)

        // When
        let result = mapper.mapToPublic(internalMethod)

        // Then - Unknown surcharge message takes precedence
        XCTAssertEqual(result.formattedSurcharge, CheckoutComponentsStrings.additionalFeeMayApply)
    }

    // MARK: - Array Mapping Tests

    func test_mapToPublicArray_preservesOrder() {
        // Given
        let mapper = createMapper()
        let methods = [
            createInternalPaymentMethod(name: TestData.PaymentMethod.firstName),
            createInternalPaymentMethod(name: TestData.PaymentMethod.secondName),
            createInternalPaymentMethod(name: TestData.PaymentMethod.thirdName)
        ]

        // When
        let results = mapper.mapToPublic(methods)

        // Then
        XCTAssertEqual(results[0].name, TestData.PaymentMethod.firstName)
        XCTAssertEqual(results[1].name, TestData.PaymentMethod.secondName)
        XCTAssertEqual(results[2].name, TestData.PaymentMethod.thirdName)
    }
}
