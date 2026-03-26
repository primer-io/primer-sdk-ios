//
//  PrimerPaymentMethodScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
final class PrimerPaymentMethodScopeTests: XCTestCase {

    // MARK: - Default Implementation Tests

    func test_defaultPresentationContext_isFromPaymentSelection() {
        // Given
        let sut = StubPaymentMethodScope()

        // Then
        XCTAssertEqual(sut.presentationContext, .fromPaymentSelection)
    }

    func test_defaultDismissalMechanism_isEmpty() {
        // Given
        let sut = StubPaymentMethodScope()

        // Then
        XCTAssertTrue(sut.dismissalMechanism.isEmpty)
    }

    func test_onBack_callsCancel() {
        // Given
        let sut = StubPaymentMethodScope()

        // When
        sut.onBack()

        // Then
        XCTAssertEqual(sut.cancelCallCount, 1)
    }

    func test_onDismiss_callsCancel() {
        // Given
        let sut = StubPaymentMethodScope()

        // When
        sut.onDismiss()

        // Then
        XCTAssertEqual(sut.cancelCallCount, 1)
    }

    func test_onBack_thenOnDismiss_callsCancelTwice() {
        // Given
        let sut = StubPaymentMethodScope()

        // When
        sut.onBack()
        sut.onDismiss()

        // Then
        XCTAssertEqual(sut.cancelCallCount, 2)
    }

    // MARK: - PaymentMethodRegistry Tests

    func test_registry_reset_clearsAllRegistrations() {
        // Given
        let registry = PaymentMethodRegistry.shared
        registry.register(
            forKey: "TEST_METHOD",
            scopeCreator: { _, _ in fatalError("Not called") },
            viewCreator: { _ in nil }
        )
        XCTAssertTrue(registry.registeredTypes.contains("TEST_METHOD"))

        // When
        registry.reset()

        // Then
        XCTAssertTrue(registry.registeredTypes.isEmpty)
    }

    func test_registry_createScope_withUnregisteredType_returnsNil() throws {
        // Given
        let registry = PaymentMethodRegistry.shared
        registry.reset()
        let checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        // When
        let scope: (any PrimerPaymentMethodScope)? = try registry.createScope(
            for: "NONEXISTENT",
            checkoutScope: checkoutScope,
            diContainer: DIContainer.createContainer()
        )

        // Then
        XCTAssertNil(scope)
    }

    func test_registry_getView_withUnregisteredType_returnsNil() {
        // Given
        let registry = PaymentMethodRegistry.shared
        registry.reset()
        let checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        // When
        let view = registry.getView(for: "NONEXISTENT", checkoutScope: checkoutScope)

        // Then
        XCTAssertNil(view)
    }

    func test_registry_registeredTypes_reflectsCurrentState() {
        // Given
        let registry = PaymentMethodRegistry.shared
        registry.reset()

        // When
        registry.register(
            forKey: "TYPE_A",
            scopeCreator: { _, _ in fatalError("Not called") },
            viewCreator: { _ in nil }
        )
        registry.register(
            forKey: "TYPE_B",
            scopeCreator: { _, _ in fatalError("Not called") },
            viewCreator: { _ in nil }
        )

        // Then
        XCTAssertEqual(registry.registeredTypes.sorted(), ["TYPE_A", "TYPE_B"])
    }
}

// MARK: - Mock Payment Method Scope

@available(iOS 15.0, *)
@MainActor
private final class StubPaymentMethodScope: PrimerPaymentMethodScope {
    typealias State = MockScopeState

    private(set) var cancelCallCount = 0
    private(set) var startCallCount = 0
    private(set) var submitCallCount = 0

    var state: AsyncStream<MockScopeState> {
        AsyncStream { $0.finish() }
    }

    func start() {
        startCallCount += 1
    }

    func submit() {
        submitCallCount += 1
    }

    func cancel() {
        cancelCallCount += 1
    }
}

@available(iOS 15.0, *)
struct MockScopeState: Equatable {
    var value: String = ""
}
