//
//  PaymentMethodRegistryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
final class PaymentMethodRegistryTests: XCTestCase {

    private var container: Container!

    override func setUp() async throws {
        try await super.setUp()
        PaymentMethodRegistry.shared.reset()
        container = Container()
    }

    override func tearDown() async throws {
        PaymentMethodRegistry.shared.reset()
        container = nil
        try await super.tearDown()
    }

    // MARK: - Registration Tests

    func test_register_addsPaymentMethodToRegistry() {
        // Given
        XCTAssertFalse(PaymentMethodRegistry.shared.registeredTypes.contains("MOCK_PAYMENT"))

        // When
        MockPaymentMethod.register()

        // Then
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.contains("MOCK_PAYMENT"))
    }

    func test_register_multiplePaymentMethods_addsAllToRegistry() {
        // When
        MockPaymentMethod.register()
        MockPaymentMethod2.register()

        // Then
        XCTAssertEqual(PaymentMethodRegistry.shared.registeredTypes.count, 2)
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.contains("MOCK_PAYMENT"))
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.contains("MOCK_PAYMENT_2"))
    }

    func test_register_samePaymentMethodTwice_replacesPrevious() {
        // When
        MockPaymentMethod.register()
        MockPaymentMethod.register()

        // Then
        let count = PaymentMethodRegistry.shared.registeredTypes.filter { $0 == "MOCK_PAYMENT" }.count
        XCTAssertEqual(count, 1)
    }

    // MARK: - createScope (String Type) Tests

    func test_createScope_forRegisteredType_returnsScope() async throws {
        // Given — register after scope creation since init calls reset()
        let checkoutScope = await createMockCheckoutScope()
        MockPaymentMethod.register()

        // When
        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: "MOCK_PAYMENT",
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    func test_createScope_forUnregisteredType_returnsNil() async throws {
        // Given
        let checkoutScope = await createMockCheckoutScope()

        // When
        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: "UNREGISTERED_PAYMENT",
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNil(scope)
    }

    // MARK: - getView Tests

    func test_getView_forRegisteredType_returnsView() async {
        // Given — register after scope creation since init calls reset()
        let checkoutScope = await createMockCheckoutScope()
        MockPaymentMethod.register()

        // When
        let view = PaymentMethodRegistry.shared.getView(
            for: "MOCK_PAYMENT",
            checkoutScope: checkoutScope
        )

        // Then
        XCTAssertNotNil(view)
    }

    func test_getView_forUnregisteredType_returnsNil() async {
        // Given
        let checkoutScope = await createMockCheckoutScope()

        // When
        let view = PaymentMethodRegistry.shared.getView(
            for: "UNREGISTERED_PAYMENT",
            checkoutScope: checkoutScope
        )

        // Then
        XCTAssertNil(view)
    }

    // MARK: - Reset Tests

    func test_reset_clearsAllRegisteredPaymentMethods() {
        // Given
        MockPaymentMethod.register()
        MockPaymentMethod2.register()
        XCTAssertEqual(PaymentMethodRegistry.shared.registeredTypes.count, 2)

        // When
        PaymentMethodRegistry.shared.reset()

        // Then
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.isEmpty)
    }

    func test_reset_afterReset_createScopeReturnsNil() async throws {
        // Given
        MockPaymentMethod.register()
        PaymentMethodRegistry.shared.reset()
        let checkoutScope = await createMockCheckoutScope()

        // When
        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: "MOCK_PAYMENT",
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNil(scope)
    }

    // MARK: - Helpers

    private func createMockCheckoutScope() async -> DefaultCheckoutScope {
        await MainActor.run {
            DefaultCheckoutScope(
                clientToken: TestData.Tokens.valid,
                settings: PrimerSettings(),
                diContainer: DIContainer.shared,
                navigator: CheckoutNavigator()
            )
        }
    }
}

// MARK: - Mock Types

@available(iOS 15.0, *)
@MainActor
final class MockPaymentMethodScope: PrimerPaymentMethodScope {
    typealias State = MockPaymentMethodState

    var state: AsyncStream<MockPaymentMethodState> {
        AsyncStream { continuation in
            continuation.yield(MockPaymentMethodState())
            continuation.finish()
        }
    }

    // No-op: mock stub for protocol conformance
    func start() {}
    func submit() {}
    func cancel() {}
}

struct MockPaymentMethodState: Equatable {
    var isLoading = false
}

@available(iOS 15.0, *)
struct MockPaymentMethod: PaymentMethodProtocol {
    static var paymentMethodType: String { "MOCK_PAYMENT" }

    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) async throws -> any PrimerPaymentMethodScope {
        MockPaymentMethodScope()
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        AnyView(Text("Mock Payment View"))
    }

    @MainActor
    static func register() {
        PaymentMethodRegistry.shared.register(
            forKey: paymentMethodType,
            scopeCreator: { try await createScope(checkoutScope: $0, diContainer: $1) },
            viewCreator: { createView(checkoutScope: $0) }
        )
    }
}

// Second mock payment method for multi-registration tests
@available(iOS 15.0, *)
@MainActor
final class MockPaymentMethod2Scope: PrimerPaymentMethodScope {
    typealias State = MockPaymentMethodState

    var state: AsyncStream<MockPaymentMethodState> {
        AsyncStream { continuation in
            continuation.yield(MockPaymentMethodState())
            continuation.finish()
        }
    }

    // No-op: mock stub for protocol conformance
    func start() {}
    func submit() {}
    func cancel() {}
}

@available(iOS 15.0, *)
struct MockPaymentMethod2: PaymentMethodProtocol {
    static var paymentMethodType: String { "MOCK_PAYMENT_2" }

    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) async throws -> any PrimerPaymentMethodScope {
        MockPaymentMethod2Scope()
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        AnyView(Text("Mock Payment 2 View"))
    }

    @MainActor
    static func register() {
        PaymentMethodRegistry.shared.register(
            forKey: paymentMethodType,
            scopeCreator: { try await createScope(checkoutScope: $0, diContainer: $1) },
            viewCreator: { createView(checkoutScope: $0) }
        )
    }
}
