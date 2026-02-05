//
//  AchPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
final class AchPaymentMethodTests: XCTestCase {

    // MARK: - Payment Method Type Tests

    func test_paymentMethodType_isStripeAch() {
        XCTAssertEqual(AchPaymentMethod.paymentMethodType, PrimerPaymentMethodType.stripeAch.rawValue)
    }

    func test_paymentMethodType_matchesExpectedString() {
        XCTAssertEqual(AchPaymentMethod.paymentMethodType, "STRIPE_ACH")
    }

    // MARK: - Registration Tests

    @MainActor
    func test_register_addsToPaymentMethodRegistry() {
        // Given
        let registry = PaymentMethodRegistry.shared
        registry.reset()

        // When
        AchPaymentMethod.register()

        // Then
        XCTAssertTrue(registry.registeredTypes.contains(PrimerPaymentMethodType.stripeAch.rawValue))
    }

    @MainActor
    func test_register_canBeCalledMultipleTimes() {
        // Given
        let registry = PaymentMethodRegistry.shared
        registry.reset()

        // When
        AchPaymentMethod.register()
        AchPaymentMethod.register()
        AchPaymentMethod.register()

        // Then - Should not crash and type should still be registered
        XCTAssertTrue(registry.registeredTypes.contains(PrimerPaymentMethodType.stripeAch.rawValue))
    }

    #if DEBUG
    @MainActor
    func test_register_alsoRegistersTestAchPaymentMethod() {
        // Given
        let registry = PaymentMethodRegistry.shared
        registry.reset()

        // When
        AchPaymentMethod.register()

        // Then - In DEBUG, TestAchPaymentMethod should also be registered
        XCTAssertTrue(registry.registeredTypes.contains("PRIMER_TEST_STRIPE_ACH"))
    }

    func test_testAchPaymentMethod_hasCorrectType() {
        XCTAssertEqual(TestAchPaymentMethod.paymentMethodType, "PRIMER_TEST_STRIPE_ACH")
    }
    #endif

    // MARK: - createView Tests

    @MainActor
    func test_createView_withNoScope_returnsNil() {
        // Given
        let mockCheckoutScope = MockInvalidCheckoutScope()

        // When
        let view = AchPaymentMethod.createView(checkoutScope: mockCheckoutScope)

        // Then
        XCTAssertNil(view)
    }

    @MainActor
    func test_getPaymentMethodScope_returnsNilForInvalidScope() {
        // Given
        let mockCheckoutScope = MockInvalidCheckoutScope()

        // When
        let scope: DefaultAchScope? = mockCheckoutScope.getPaymentMethodScope(DefaultAchScope.self)

        // Then
        XCTAssertNil(scope)
    }
}

// MARK: - Mock Invalid Checkout Scope

@available(iOS 15.0, *)
@MainActor
private final class MockInvalidCheckoutScope: PrimerCheckoutScope {

    var container: ContainerComponent?
    var splashScreen: Component?
    var loading: Component?
    var errorScreen: ErrorComponent?

    var state: AsyncStream<PrimerCheckoutState> {
        AsyncStream { _ in }
    }

    var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
        fatalError("Not implemented for testing")
    }

    var paymentHandling: PrimerPaymentHandling {
        .auto
    }

    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? {
        nil
    }

    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T? {
        nil
    }

    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for paymentMethodType: String) -> T? {
        nil
    }

    func onDismiss() {}
}
