//
//  PayPalPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

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

    // MARK: - createScope Error Cases

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

    // MARK: - Presentation Context

    func test_createScope_withSinglePaymentMethod_usesDirectContext() async throws {
        // Given
        await registerPayPalDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try PayPalPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    func test_createScope_withMultiplePaymentMethods_usesPaymentSelectionContext() async throws {
        // Given
        await registerPayPalDependencies()
        let checkoutScope = await createCheckoutScopeWithMultiplePaymentMethods()

        // When
        let scope = try PayPalPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    // MARK: - Register Tests

    func test_register_addsToPaymentMethodRegistry() async throws {
        // When
        PayPalPaymentMethod.register()

        // Then
        await registerPayPalDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

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
        _ = try? await container.register(ProcessPayPalPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessPayPalPaymentInteractor() }

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
    func execute() async throws -> PaymentResult {
        PaymentResult(paymentId: "test-payment-id", status: .success)
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
    var loadingScreen: Component?
    var errorScreen: ErrorComponent?
    var onBeforePaymentCreate: BeforePaymentCreateHandler?

    var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
        fatalError("Not implemented for mock")
    }

    var paymentHandling: PrimerPaymentHandling { .auto }

    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? { nil }
    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T? { nil }
    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for paymentMethodType: String) -> T? { nil }

    func onDismiss() {}
}
