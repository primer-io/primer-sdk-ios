//
//  CardPaymentMethodTests.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import XCTest
import SwiftUI
@testable import PrimerSDK

/// Tests for CardPaymentMethod covering scope creation, view creation, and registration.
@available(iOS 15.0, *)
@MainActor
final class CardPaymentMethodTests: XCTestCase {

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

    func test_paymentMethodType_isPaymentCard() {
        XCTAssertEqual(CardPaymentMethod.paymentMethodType, PrimerPaymentMethodType.paymentCard.rawValue)
    }

    // MARK: - createScope Tests

    func test_createScope_withMissingRequiredDependency_throws() async throws {
        // Given - empty container without required dependencies
        let emptyContainer = Container()

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try CardPaymentMethod.createScope(
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
        await registerCardPaymentDependencies()

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        do {
            let scope = try CardPaymentMethod.createScope(
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
        await registerCardPaymentDependencies()

        // Create scope with single available payment method
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
        // Note: By default, ContainerTestHelpers creates a scope without payment methods,
        // so it should use .direct context (0 or 1 methods)

        do {
            let scope = try CardPaymentMethod.createScope(
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
        await registerCardPaymentDependencies()

        // Create scope with multiple available payment methods
        let checkoutScope = await createCheckoutScopeWithMultiplePaymentMethods()

        do {
            let scope = try CardPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: container
            )

            // Then - should use fromPaymentSelection context (show back button)
            XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    // Note: createView tests are integration tests that require full SDK initialization
    // and are tested in the Debug App. The behavior of createView depends on:
    // - DIContainer.currentSync being available
    // - PaymentMethodRegistry having the payment method registered
    // - Required dependencies being resolvable

    // MARK: - Invalid Checkout Scope Tests

    func test_createScope_withInvalidCheckoutScopeType_throwsInvalidArchitecture() async throws {
        // Given - a mock checkout scope that is NOT DefaultCheckoutScope
        let invalidCheckoutScope = MockInvalidCheckoutScopeForCardTests()
        await registerCardPaymentDependencies()

        // When/Then
        do {
            _ = try CardPaymentMethod.createScope(
                checkoutScope: invalidCheckoutScope,
                diContainer: container
            )
            XCTFail("Expected error when checkout scope is not DefaultCheckoutScope")
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

    // MARK: - Missing Required Dependency Tests

    func test_createScope_withMissingProcessCardPaymentInteractor_throwsError() async throws {
        // Given - container with ConfigurationService but missing ProcessCardPaymentInteractor
        _ = try? await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in MockConfigurationService.withDefaultConfiguration() }

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try CardPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: container
            )
            XCTFail("Expected error when ProcessCardPaymentInteractor is missing")
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

    func test_createScope_withMissingConfigurationService_throwsError() async throws {
        // Given - fresh empty container with ProcessCardPaymentInteractor but missing ConfigurationService
        let emptyContainer = Container()
        _ = try? await emptyContainer.register(ProcessCardPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessCardPaymentInteractor() }

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try CardPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: emptyContainer
            )
            XCTFail("Expected error when ConfigurationService is missing")
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

    // MARK: - Optional Dependency Tests

    func test_createScope_withoutOptionalValidateInputInteractor_succeeds() async throws {
        // Given - container with required deps but without ValidateInputInteractor
        _ = try? await container.register(ProcessCardPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessCardPaymentInteractor() }
        _ = try? await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in MockConfigurationService.withDefaultConfiguration() }

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then - should succeed even without optional dependency
        XCTAssertNotNil(scope)
    }

    func test_createScope_withoutOptionalCardNetworkDetectionInteractor_succeeds() async throws {
        // Given - container without CardNetworkDetectionInteractor
        _ = try? await container.register(ProcessCardPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessCardPaymentInteractor() }
        _ = try? await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in MockConfigurationService.withDefaultConfiguration() }

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then - should succeed even without optional dependency
        XCTAssertNotNil(scope)
    }

    func test_createScope_withAllOptionalDependencies_succeeds() async throws {
        // Given - container with all required and optional dependencies
        await registerCardPaymentDependencies()

        // Also register analytics interactor
        _ = try? await container.register(CheckoutComponentsAnalyticsInteractorProtocol.self)
            .asSingleton()
            .with { _ in MockAnalyticsInteractor() }

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    // MARK: - Presentation Context Edge Cases

    func test_createScope_withZeroPaymentMethods_usesDirectContext() async throws {
        // Given - checkout scope with zero payment methods
        await registerCardPaymentDependencies()

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
        checkoutScope.availablePaymentMethods = [] // Explicitly empty

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then - should use direct context
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    func test_createScope_withExactlyOnePaymentMethod_usesDirectContext() async throws {
        // Given - checkout scope with exactly one payment method
        await registerCardPaymentDependencies()

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
            InternalPaymentMethod(
                id: "card-only",
                type: PrimerPaymentMethodType.paymentCard.rawValue,
                name: "Card"
            )
        ]

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then - should use direct context
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    func test_createScope_withExactlyTwoPaymentMethods_usesPaymentSelectionContext() async throws {
        // Given - checkout scope with exactly two payment methods
        await registerCardPaymentDependencies()

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
            InternalPaymentMethod(
                id: "card-1",
                type: PrimerPaymentMethodType.paymentCard.rawValue,
                name: "Card"
            ),
            InternalPaymentMethod(
                id: "paypal-1",
                type: PrimerPaymentMethodType.payPal.rawValue,
                name: "PayPal"
            )
        ]

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then - should use fromPaymentSelection context
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    // MARK: - Register Tests

    func test_register_addsToPaymentMethodRegistry() async throws {
        // When - register the payment method
        CardPaymentMethod.register()

        // Then - should be able to create scope through registry
        await registerCardPaymentDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // Try creating scope through registry - if registered, this should work
        do {
            let scope = try PaymentMethodRegistry.shared.createScope(
                for: PrimerPaymentMethodType.paymentCard.rawValue,
                checkoutScope: checkoutScope,
                diContainer: container
            )
            XCTAssertNotNil(scope)
        } catch {
            XCTFail("Registry should have CardPaymentMethod registered: \(error)")
        }
    }

    // MARK: - createView Tests

    func test_createView_withoutCardFormScope_returnsNil() async throws {
        // Given - checkout scope without card form scope registered
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When - try to create view without scope
        let view = CardPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then - should return nil
        XCTAssertNil(view)
    }

    func test_createView_withMockInvalidScope_returnsNil() async throws {
        // Given - an invalid checkout scope type
        let invalidCheckoutScope = MockInvalidCheckoutScopeForCardTests()

        // When - try to create view
        let view = CardPaymentMethod.createView(checkoutScope: invalidCheckoutScope)

        // Then - should return nil (getPaymentMethodScope returns nil)
        XCTAssertNil(view)
    }

    // MARK: - Scope Type Tests

    func test_scopeType_isDefaultCardFormScope() {
        // The typealias ScopeType should be DefaultCardFormScope
        XCTAssertTrue(CardPaymentMethod.ScopeType.self == DefaultCardFormScope.self)
    }

    // MARK: - Presentation Context Edge Cases

    func test_createScope_withThreePaymentMethods_usesPaymentSelectionContext() async throws {
        // Given - checkout scope with three payment methods
        await registerCardPaymentDependencies()

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
            InternalPaymentMethod(
                id: "card-1",
                type: PrimerPaymentMethodType.paymentCard.rawValue,
                name: "Card"
            ),
            InternalPaymentMethod(
                id: "paypal-1",
                type: PrimerPaymentMethodType.payPal.rawValue,
                name: "PayPal"
            ),
            InternalPaymentMethod(
                id: "apple-pay-1",
                type: PrimerPaymentMethodType.applePay.rawValue,
                name: "Apple Pay"
            )
        ]

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then - should use fromPaymentSelection context
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    func test_createScope_withManyPaymentMethods_usesPaymentSelectionContext() async throws {
        // Given - checkout scope with many payment methods
        await registerCardPaymentDependencies()

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

        // Add 10 payment methods
        checkoutScope.availablePaymentMethods = (0..<10).map { index in
            InternalPaymentMethod(
                id: "method-\(index)",
                type: "TYPE_\(index)",
                name: "Method \(index)"
            )
        }

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then - should use fromPaymentSelection context
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    // MARK: - Dependency Injection Tests

    func test_createScope_withAnalyticsInteractor_includesAnalytics() async throws {
        // Given - container with analytics interactor registered
        await registerCardPaymentDependencies()
        _ = try? await container.register(CheckoutComponentsAnalyticsInteractorProtocol.self)
            .asSingleton()
            .with { _ in MockAnalyticsInteractor() }

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then - scope should be created successfully with analytics
        XCTAssertNotNil(scope)
    }

    // MARK: - Registry Integration Tests

    func test_register_canBeCalledMultipleTimes() async throws {
        // Given - payment method already registered
        CardPaymentMethod.register()

        // When - register again
        CardPaymentMethod.register()

        // Then - should not throw, should still work
        await registerCardPaymentDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        do {
            let scope = try PaymentMethodRegistry.shared.createScope(
                for: PrimerPaymentMethodType.paymentCard.rawValue,
                checkoutScope: checkoutScope,
                diContainer: container
            )
            XCTAssertNotNil(scope)
        } catch {
            XCTFail("Registry should still work after multiple registrations: \(error)")
        }
    }

    // MARK: - Helper Methods

    private func registerCardPaymentDependencies() async {
        // Register ProcessCardPaymentInteractor
        _ = try? await container.register(ProcessCardPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessCardPaymentInteractor() }

        // Register ValidateInputInteractor (optional)
        _ = try? await container.register(ValidateInputInteractor.self)
            .asSingleton()
            .with { _ in MockValidateInputInteractor() }

        // Register CardNetworkDetectionInteractor (optional)
        _ = try? await container.register(CardNetworkDetectionInteractor.self)
            .asSingleton()
            .with { _ in MockCardNetworkDetectionInteractor() }

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
                id: "card-1",
                type: PrimerPaymentMethodType.paymentCard.rawValue,
                name: "Card"
            ),
            InternalPaymentMethod(
                id: "apple-pay-1",
                type: PrimerPaymentMethodType.applePay.rawValue,
                name: "Apple Pay"
            )
        ]

        return scope
    }
}

// MARK: - Mock Invalid Checkout Scope

@available(iOS 15.0, *)
private final class MockInvalidCheckoutScopeForCardTests: PrimerCheckoutScope {
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
