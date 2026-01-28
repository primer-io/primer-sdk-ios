//
//  KlarnaPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class KlarnaPaymentMethodTests: XCTestCase {

    // MARK: - Payment Method Type Tests

    func test_paymentMethodType_returnsKlarnaType() {
        XCTAssertEqual(KlarnaPaymentMethod.paymentMethodType, PrimerPaymentMethodType.klarna.rawValue)
    }

    // MARK: - Registration Tests

    @MainActor
    func test_register_registersKlarnaPaymentMethod() {
        // Given
        let registry = PaymentMethodRegistry.shared

        // When
        KlarnaPaymentMethod.register()

        // Then
        XCTAssertTrue(registry.registeredTypes.contains(PrimerPaymentMethodType.klarna.rawValue))
    }

    #if DEBUG
    @MainActor
    func test_register_registersTestKlarnaPaymentMethod() {
        // Given
        let registry = PaymentMethodRegistry.shared

        // When
        KlarnaPaymentMethod.register()

        // Then
        XCTAssertTrue(registry.registeredTypes.contains("PRIMER_TEST_KLARNA"))
    }

    func test_testKlarnaPaymentMethod_paymentMethodType() {
        XCTAssertEqual(TestKlarnaPaymentMethod.paymentMethodType, "PRIMER_TEST_KLARNA")
    }
    #endif

    // MARK: - createView Tests

    @MainActor
    func test_createView_withNonKlarnaScope_returnsNil() {
        // Given
        let checkoutScope = DefaultCheckoutScope(
            clientToken: KlarnaTestData.Constants.mockToken,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        // When - no Klarna scope is registered in the checkout scope
        let view = KlarnaPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then
        XCTAssertNil(view)
    }
}
