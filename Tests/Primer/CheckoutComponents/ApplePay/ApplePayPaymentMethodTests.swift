//
//  ApplePayPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import XCTest
@testable import PrimerSDK

@available(iOS 15.0, *)
final class ApplePayPaymentMethodTests: XCTestCase {

    @MainActor
    override func setUp() {
        super.setUp()
        // Reset registry before each test for proper isolation
        PaymentMethodRegistry.shared.reset()
    }

    // MARK: - Static Property Tests

    func test_paymentMethodType_returnsApplePay() {
        // Then
        XCTAssertEqual(ApplePayPaymentMethod.paymentMethodType, "APPLE_PAY")
    }

    // MARK: - Registration Tests

    @MainActor
    func test_register_doesNotThrow() {
        // When/Then - Just verify registration doesn't crash
        ApplePayPaymentMethod.register()
        // If we get here, registration succeeded
    }

    // MARK: - createScope Tests

    @MainActor
    func test_createScope_withValidCheckoutScope_returnsScope() throws {
        // Given
        let checkoutScope = createCheckoutScope()
        let container = DIContainer.createContainer()

        // When
        let scope = try ApplePayPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
        XCTAssertTrue(scope is DefaultApplePayScope)
    }

    @MainActor
    func test_createScope_withNoPaymentMethods_setsDirectContext() throws {
        // Given - no payment methods means single payment method scenario
        let checkoutScope = createCheckoutScope()
        let container = DIContainer.createContainer()

        // When
        let scope = try ApplePayPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then - with 0 payment methods, count <= 1, so direct context
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    @MainActor
    func test_createScope_withSinglePaymentMethod_setsDirectContext() throws {
        // Given
        let checkoutScope = createCheckoutScope(paymentMethodCount: 1)
        let container = DIContainer.createContainer()

        // When
        let scope = try ApplePayPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    @MainActor
    func test_createScope_withMultiplePaymentMethods_setsFromPaymentSelectionContext() throws {
        // Given
        let checkoutScope = createCheckoutScope(paymentMethodCount: 3)
        let container = DIContainer.createContainer()

        // When
        let scope = try ApplePayPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    @MainActor
    func test_createScope_withTwoPaymentMethods_setsFromPaymentSelectionContext() throws {
        // Given
        let checkoutScope = createCheckoutScope(paymentMethodCount: 2)
        let container = DIContainer.createContainer()

        // When
        let scope = try ApplePayPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    @MainActor
    func test_createScope_withInvalidCheckoutScope_throwsError() {
        // Given
        let invalidScope = MockInvalidCheckoutScope()
        let container = DIContainer.createContainer()

        // When/Then
        XCTAssertThrowsError(
            try ApplePayPaymentMethod.createScope(
                checkoutScope: invalidScope,
                diContainer: container
            )
        ) { error in
            guard let primerError = error as? PrimerError else {
                XCTFail("Expected PrimerError")
                return
            }
            if case .invalidArchitecture = primerError {
                // Expected error type
            } else {
                XCTFail("Expected invalidArchitecture error")
            }
        }
    }

    // MARK: - createView Tests

    @MainActor
    func test_createView_whenScopeNotRegistered_returnsNil() {
        // Given - Use mock scope that returns nil from getPaymentMethodScope
        let checkoutScope = MockInvalidCheckoutScope()

        // When
        let view = ApplePayPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then
        XCTAssertNil(view)
    }

    // NOTE: The following 2 tests are excluded from this PR because they rely on scope caching
    // mechanisms that require other PRs to merge first. They will be added back when PR dependencies merge.
    // - test_createView_whenScopeAvailable_returnsView
    // - test_createView_whenCustomScreenSet_returnsCustomScreen

    // MARK: - Helpers

    @MainActor
    private func createCheckoutScope(paymentMethodCount: Int = 0) -> DefaultCheckoutScope {
        let scope = DefaultCheckoutScope(
            clientToken: "mock_token",
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        // Add mock payment methods to simulate count
        for i in 0 ..< paymentMethodCount {
            let mockMethod = InternalPaymentMethod(
                id: "method_\(i)",
                type: i == 0 ? "APPLE_PAY" : "PAYMENT_CARD",
                name: "Method \(i)"
            )
            scope.availablePaymentMethods.append(mockMethod)
        }

        return scope
    }
}

// MARK: - Mock Invalid Checkout Scope

@available(iOS 15.0, *)
private final class MockInvalidCheckoutScope: PrimerCheckoutScope {

    var state: AsyncStream<PrimerCheckoutState> {
        AsyncStream { continuation in
            continuation.finish()
        }
    }

    var container: ContainerComponent?
    var splashScreen: Component?
    var loading: Component?
    var errorScreen: ErrorComponent?
    var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
        fatalError("Not implemented")
    }
    var paymentHandling: PrimerPaymentHandling { .auto }

    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? { nil }
    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T? { nil }
    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for paymentMethodType: String) -> T? { nil }
    func onDismiss() {}
}
