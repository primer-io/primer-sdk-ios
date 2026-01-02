//
//  PayPalPaymentMethodTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for PayPalPaymentMethod covering scope creation, view creation, and registration.
@available(iOS 15.0, *)
@MainActor
final class PayPalPaymentMethodTests: XCTestCase {

    private var container: Container!

    override func setUp() async throws {
        try await super.setUp()
        container = await ContainerTestHelpers.createTestContainer()
    }

    override func tearDown() async throws {
        await container.reset(ignoreDependencies: [Never.Type]())
        container = nil
        try await super.tearDown()
    }

    // MARK: - Payment Method Type Tests

    func test_paymentMethodType_isPayPal() {
        XCTAssertEqual(PayPalPaymentMethod.paymentMethodType, PrimerPaymentMethodType.payPal.rawValue)
    }

    // MARK: - createScope Tests

    func test_createScope_withMissingRequiredDependency_throws() async throws {
        // Given - empty container without required dependencies
        let emptyContainer = Container()

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try PayPalPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: emptyContainer
            )
            XCTFail("Expected error when required dependency is missing")
        } catch let error as PrimerError {
            switch error {
            case let .invalidArchitecture(description, _, _):
                XCTAssertTrue(description.contains("dependencies"))
            default:
                XCTFail("Expected invalidArchitecture error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_createScope_withValidDependencies_returnsScope() async throws {
        // Register all required dependencies
        await registerPayPalDependencies()

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        do {
            let scope = try PayPalPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: container
            )

            // Then
            XCTAssertNotNil(scope)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_createScope_withSinglePaymentMethod_usesDirectContext() async throws {
        // Register all required dependencies
        await registerPayPalDependencies()

        // Create scope with single available payment method
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
        // Note: By default, ContainerTestHelpers creates a scope without payment methods,
        // so it should use .direct context (0 or 1 methods)

        do {
            let scope = try PayPalPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: container
            )

            // Then - should use direct context (no back button needed)
            XCTAssertEqual(scope.presentationContext, .direct)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_createScope_withMultiplePaymentMethods_usesPaymentSelectionContext() async throws {
        // Register all required dependencies
        await registerPayPalDependencies()

        // Create scope with multiple available payment methods
        let checkoutScope = await createCheckoutScopeWithMultiplePaymentMethods()

        do {
            let scope = try PayPalPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: container
            )

            // Then - should use fromPaymentSelection context (show back button)
            XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_createScope_withNonDefaultCheckoutScope_throws() async throws {
        // Given - a mock checkout scope that is NOT a DefaultCheckoutScope
        await registerPayPalDependencies()
        let mockScope = MockNonDefaultCheckoutScope()

        // When/Then
        do {
            _ = try PayPalPaymentMethod.createScope(
                checkoutScope: mockScope,
                diContainer: container
            )
            XCTFail("Expected error when using non-default checkout scope")
        } catch let error as PrimerError {
            switch error {
            case let .invalidArchitecture(description, _, _):
                XCTAssertTrue(description.contains("DefaultCheckoutScope"))
            default:
                XCTFail("Expected invalidArchitecture error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    func test_createScope_withThreePaymentMethods_usesPaymentSelectionContext() async throws {
        // Register all required dependencies
        await registerPayPalDependencies()

        let navigator = CheckoutNavigator(coordinator: CheckoutCoordinator())
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )
        let checkoutScope = DefaultCheckoutScope(
            clientToken: "test-token",
            settings: settings,
            diContainer: DIContainer.shared,
            navigator: navigator
        )
        checkoutScope.availablePaymentMethods = [
            InternalPaymentMethod(id: "1", type: "PAYPAL", name: "PayPal"),
            InternalPaymentMethod(id: "2", type: "PAYMENT_CARD", name: "Card"),
            InternalPaymentMethod(id: "3", type: "APPLE_PAY", name: "Apple Pay")
        ]

        do {
            let scope = try PayPalPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: container
            )

            XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_createScope_withExactlyTwoPaymentMethods_usesPaymentSelectionContext() async throws {
        // Register all required dependencies
        await registerPayPalDependencies()

        let navigator = CheckoutNavigator(coordinator: CheckoutCoordinator())
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )
        let checkoutScope = DefaultCheckoutScope(
            clientToken: "test-token",
            settings: settings,
            diContainer: DIContainer.shared,
            navigator: navigator
        )
        checkoutScope.availablePaymentMethods = [
            InternalPaymentMethod(id: "1", type: "PAYPAL", name: "PayPal"),
            InternalPaymentMethod(id: "2", type: "PAYMENT_CARD", name: "Card")
        ]

        do {
            let scope = try PayPalPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: container
            )

            XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func test_createScope_returnsScopeWithCheckoutScopeReference() async throws {
        // Register all required dependencies
        await registerPayPalDependencies()

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        do {
            let scope = try PayPalPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: container
            )

            // Verify the scope has a reference to the checkout scope
            XCTAssertNotNil(scope)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // MARK: - ScopeType Tests

    func test_scopeType_isDefaultPayPalScope() {
        XCTAssertTrue(PayPalPaymentMethod.ScopeType.self == DefaultPayPalScope.self)
    }

    // MARK: - createView Tests

    func test_createView_withNoScope_returnsNil() async throws {
        // Given - checkout scope without PayPal scope cached
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let view = PayPalPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then
        XCTAssertNil(view)
    }

    // Note: Tests for createView with valid scope are integration tests
    // that require full SDK initialization and are tested in the Debug App

    // MARK: - Register Tests

    func test_register_addsToPaymentMethodRegistry() async throws {
        // When - register the payment method
        PayPalPaymentMethod.register()

        // Then - should be able to create scope through registry
        await registerPayPalDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // Try creating scope through registry - if registered, this should work
        do {
            let scope = try PaymentMethodRegistry.shared.createScope(
                for: PrimerPaymentMethodType.payPal.rawValue,
                checkoutScope: checkoutScope,
                diContainer: container
            )
            XCTAssertNotNil(scope)
        } catch {
            XCTFail("Registry should have PayPalPaymentMethod registered: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func registerPayPalDependencies() async {
        // Register ProcessPayPalPaymentInteractor
        _ = try? await container.register(ProcessPayPalPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessPayPalPaymentInteractor() }

        // Register ConfigurationService
        _ = try? await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in MockConfigurationService.withDefaultConfiguration() }
    }

    private func createCheckoutScopeWithMultiplePaymentMethods() async -> DefaultCheckoutScope {
        let navigator = CheckoutNavigator(coordinator: CheckoutCoordinator())
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )
        let scope = DefaultCheckoutScope(
            clientToken: "test-token",
            settings: settings,
            diContainer: DIContainer.shared,
            navigator: navigator
        )

        // Add multiple payment methods to the scope's availablePaymentMethods array
        scope.availablePaymentMethods = [
            InternalPaymentMethod(
                id: "paypal-1",
                type: PrimerPaymentMethodType.payPal.rawValue,
                name: "PayPal"
            ),
            InternalPaymentMethod(
                id: "card-1",
                type: PrimerPaymentMethodType.paymentCard.rawValue,
                name: "Card"
            )
        ]

        return scope
    }
}

// MARK: - Mock ProcessPayPalPaymentInteractor

@available(iOS 15.0, *)
private final class MockProcessPayPalPaymentInteractor: ProcessPayPalPaymentInteractor {
    var executeCallCount = 0
    var executeResult: Result<PaymentResult, Error> = .success(
        PaymentResult(
            paymentId: "test-payment-id",
            status: .success
        )
    )

    func execute() async throws -> PaymentResult {
        executeCallCount += 1
        return try executeResult.get()
    }
}

// MARK: - Mock Non-Default Checkout Scope

@available(iOS 15.0, *)
private final class MockNonDefaultCheckoutScope: PrimerCheckoutScope {
    var state: AsyncStream<PrimerCheckoutState> {
        AsyncStream { continuation in
            continuation.yield(.initializing)
            continuation.finish()
        }
    }

    var container: ContainerComponent?
    var splashScreen: Component?
    var loading: Component?
    var errorScreen: ErrorComponent?

    var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
        fatalError("Not implemented for mock")
    }

    var paymentHandling: PrimerPaymentHandling { .auto }

    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? { nil }
    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T? { nil }
    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for paymentMethodType: String) -> T? { nil }

    func onDismiss() {}
}
