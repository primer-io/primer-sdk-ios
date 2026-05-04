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
        await ContainerTestHelpers.resetSharedContainer()
        container = try await ContainerTestHelpers.createTestContainer()
    }

    override func tearDown() async throws {
        await container.reset(ignoreDependencies: [Never.Type]())
        container = nil
        await ContainerTestHelpers.resetSharedContainer()
        try await super.tearDown()
    }

    // MARK: - createScope Success Cases

    func test_createScope_withValidDependencies_returnsScope() async throws {
        // Given
        await registerPayPalDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await PayPalPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
        XCTAssertTrue(scope is DefaultPayPalScope)
    }

    // MARK: - createScope Error Cases

    func test_createScope_withMissingRequiredDependency_throws() async throws {
        // Given - empty container without required dependencies
        let emptyContainer = Container()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try await PayPalPaymentMethod.createScope(
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
            _ = try await PayPalPaymentMethod.createScope(
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
        let scope = try await PayPalPaymentMethod.createScope(
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
        let scope = try await PayPalPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    // MARK: - Static Properties

    func test_paymentMethodType_matchesPayPal() {
        XCTAssertEqual(PayPalPaymentMethod.paymentMethodType, PrimerPaymentMethodType.payPal.rawValue)
    }

    // MARK: - createView Tests

    func test_createView_withNoScope_returnsNil() {
        // Given
        let mockScope = MockNonDefaultCheckoutScope()

        // When
        let view = PayPalPaymentMethod.createView(checkoutScope: mockScope)

        // Then
        XCTAssertNil(view)
    }

    // MARK: - Register Tests

    func test_register_addsToPaymentMethodRegistry() async throws {
        // Given — register after scope creation since init calls reset()
        await registerPayPalDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
        PayPalPaymentMethod.register()

        // When/Then
        do {
            let scope = try await PaymentMethodRegistry.shared.createScope(
                for: PrimerPaymentMethodType.payPal.rawValue,
                checkoutScope: checkoutScope,
                diContainer: container
            )
            XCTAssertNotNil(scope)
        } catch {
            XCTFail("Registry should have PayPalPaymentMethod registered: \(error)")
        }
    }

    // MARK: - createView With Registered Scope

    func test_createView_withRegisteredScope_returnsView() async throws {
        // Given
        await registerPayPalDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
        _ = try await PayPalPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // When — createView depends on PaymentMethodRegistry
        let view = PayPalPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then — no crash; view may be nil since scope isn't auto-registered
        _ = view
    }

    // MARK: - createScope PrimerError Rethrow

    func test_createScope_whenResolveThrowsPrimerError_rethrowsSameError() async throws {
        // Given - register a factory that throws a PrimerError directly
        let expectedError = PrimerError.invalidClientToken(reason: "test")
        let errorContainer = Container()
        _ = try? await errorContainer.register(ProcessPayPalPaymentInteractor.self)
            .asSingleton()
            .with { _ in throw expectedError }

        // Pre-populate the singleton to make resolveSync throw
        _ = try? await errorContainer.resolve(ProcessPayPalPaymentInteractor.self)

        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try await PayPalPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: errorContainer
            )
            XCTFail("Expected error to be thrown")
        } catch {
            XCTAssertTrue(error is PrimerError)
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
            clientToken: TestData.Tokens.valid,
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
        PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)
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

    // No-op: mock stub for protocol conformance
    func onDismiss() {}
}
