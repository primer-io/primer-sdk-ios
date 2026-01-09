//
//  PaymentMethodRegistryTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
import XCTest
@testable import PrimerSDK

/// Tests for PaymentMethodRegistry covering registration, scope creation, and reset.
@available(iOS 15.0, *)
@MainActor
final class PaymentMethodRegistryTests: XCTestCase {

    private var container: Container!

    override func setUp() async throws {
        try await super.setUp()
        // Reset registry before each test
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
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)

        // Then
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.contains("MOCK_PAYMENT"))
    }

    func test_register_multiplePaymentMethods_addsAllToRegistry() {
        // When
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)
        PaymentMethodRegistry.shared.register(MockPaymentMethod2.self)

        // Then
        XCTAssertEqual(PaymentMethodRegistry.shared.registeredTypes.count, 2)
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.contains("MOCK_PAYMENT"))
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.contains("MOCK_PAYMENT_2"))
    }

    func test_register_samePaymentMethodTwice_replacesPrevious() {
        // When
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)

        // Then - should only be registered once
        let count = PaymentMethodRegistry.shared.registeredTypes.filter { $0 == "MOCK_PAYMENT" }.count
        XCTAssertEqual(count, 1)
    }

    // MARK: - registeredTypes Tests

    func test_registeredTypes_whenEmpty_returnsEmptyArray() {
        // Given - registry is reset in setUp
        // Then
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.isEmpty)
    }

    func test_registeredTypes_returnsAllRegisteredTypes() {
        // Given
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)
        PaymentMethodRegistry.shared.register(MockPaymentMethod2.self)

        // When
        let types = PaymentMethodRegistry.shared.registeredTypes

        // Then
        XCTAssertEqual(Set(types), Set(["MOCK_PAYMENT", "MOCK_PAYMENT_2"]))
    }

    // MARK: - createScope (String Type) Tests

    func test_createScope_forRegisteredType_returnsScope() async throws {
        // Given
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)
        let checkoutScope = await createMockCheckoutScope()

        // When
        let scope = try PaymentMethodRegistry.shared.createScope(
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
        let scope = try PaymentMethodRegistry.shared.createScope(
            for: "UNREGISTERED_PAYMENT",
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNil(scope)
    }

    // MARK: - createScope (Generic) Tests

    func test_createScopeGeneric_forRegisteredType_returnsScopeOfCorrectType() async throws {
        // Given
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)
        let checkoutScope = await createMockCheckoutScope()

        // When
        let scope: MockPaymentMethodScope? = try PaymentMethodRegistry.shared.createScope(
            for: "MOCK_PAYMENT",
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    func test_createScopeGeneric_forUnregisteredType_returnsNil() async throws {
        // Given
        let checkoutScope = await createMockCheckoutScope()

        // When
        let scope: MockPaymentMethodScope? = try PaymentMethodRegistry.shared.createScope(
            for: "UNREGISTERED",
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNil(scope)
    }

    // MARK: - createScope (Metatype) Tests

    func test_createScopeMetatype_forRegisteredType_returnsScope() async throws {
        // Given
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)
        let checkoutScope = await createMockCheckoutScope()

        // When
        let scope = try PaymentMethodRegistry.shared.createScope(
            MockPaymentMethodScope.self,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    func test_createScopeMetatype_forUnregisteredType_returnsNil() async throws {
        // Given - registry is reset, MockPaymentMethod not registered
        let checkoutScope = await createMockCheckoutScope()

        // When
        let scope = try PaymentMethodRegistry.shared.createScope(
            MockPaymentMethodScope.self,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNil(scope)
    }

    // MARK: - createScope (Enum) Tests

    func test_createScopeEnum_forRegisteredType_registryContainsType() {
        // Given
        // Register CardPaymentMethod which maps to PrimerPaymentMethodType.paymentCard
        CardPaymentMethod.register()

        // Then - verify the registry contains the type
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.contains(PrimerPaymentMethodType.paymentCard.rawValue))
    }

    // MARK: - getView Tests

    func test_getView_forRegisteredType_returnsView() async {
        // Given
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)
        let checkoutScope = await createMockCheckoutScope()

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
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)
        PaymentMethodRegistry.shared.register(MockPaymentMethod2.self)
        XCTAssertEqual(PaymentMethodRegistry.shared.registeredTypes.count, 2)

        // When
        PaymentMethodRegistry.shared.reset()

        // Then
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.isEmpty)
    }

    func test_reset_afterReset_createScopeReturnsNil() async throws {
        // Given
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)
        PaymentMethodRegistry.shared.reset()
        let checkoutScope = await createMockCheckoutScope()

        // When
        let scope = try PaymentMethodRegistry.shared.createScope(
            for: "MOCK_PAYMENT",
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNil(scope)
    }

    func test_reset_afterReset_getViewReturnsNil() async {
        // Given
        PaymentMethodRegistry.shared.register(MockPaymentMethod.self)
        PaymentMethodRegistry.shared.reset()
        let checkoutScope = await createMockCheckoutScope()

        // When
        let view = PaymentMethodRegistry.shared.getView(
            for: "MOCK_PAYMENT",
            checkoutScope: checkoutScope
        )

        // Then
        XCTAssertNil(view)
    }

    // MARK: - Helpers

    private func createMockCheckoutScope() async -> DefaultCheckoutScope {
        await MainActor.run {
            DefaultCheckoutScope(
                clientToken: "mock_token",
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

    func start() {}
    func submit() {}
    func cancel() {}
}

struct MockPaymentMethodState: Equatable {
    var isLoading = false
}

@available(iOS 15.0, *)
struct MockPaymentMethod: PaymentMethodProtocol {
    typealias ScopeType = MockPaymentMethodScope

    static var paymentMethodType: String { "MOCK_PAYMENT" }

    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) throws -> MockPaymentMethodScope {
        MockPaymentMethodScope()
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        AnyView(Text("Mock Payment View"))
    }

    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (MockPaymentMethodScope) -> V) -> AnyView {
        AnyView(EmptyView())
    }

    @MainActor
    func defaultContent() -> AnyView {
        AnyView(Text("Default Mock Content"))
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

    func start() {}
    func submit() {}
    func cancel() {}
}

@available(iOS 15.0, *)
struct MockPaymentMethod2: PaymentMethodProtocol {
    typealias ScopeType = MockPaymentMethod2Scope

    static var paymentMethodType: String { "MOCK_PAYMENT_2" }

    @MainActor
    static func createScope(
        checkoutScope: PrimerCheckoutScope,
        diContainer: any ContainerProtocol
    ) throws -> MockPaymentMethod2Scope {
        MockPaymentMethod2Scope()
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
        AnyView(Text("Mock Payment 2 View"))
    }

    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (MockPaymentMethod2Scope) -> V) -> AnyView {
        AnyView(EmptyView())
    }

    @MainActor
    func defaultContent() -> AnyView {
        AnyView(Text("Default Mock 2 Content"))
    }
}
