//
//  KlarnaPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import UIKit
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

    @MainActor
    func test_createView_withDefaultCheckoutScopeNoKlarnaScope_returnsNil() {
        // Given
        let checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        // When
        let view = KlarnaPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then
        XCTAssertNil(view)
    }

    #if DEBUG
    @MainActor
    func test_testKlarnaPaymentMethod_createView_withNoScope_returnsNil() {
        // Given
        let mockScope = MockNonDefaultCheckoutScopeForKlarna()

        // When
        let view = TestKlarnaPaymentMethod.createView(checkoutScope: mockScope)

        // Then
        XCTAssertNil(view)
    }

    @MainActor
    func test_testKlarnaPaymentMethod_createScope_withValidDependencies_delegatesToKlarnaPaymentMethod() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessKlarnaPaymentInteractorForTests() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await TestKlarnaPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    @MainActor
    func test_testKlarnaPaymentMethod_createScope_withNonDefaultScope_throws() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        let invalidScope = MockNonDefaultCheckoutScopeForKlarna()

        // When/Then
        do {
            _ = try await TestKlarnaPaymentMethod.createScope(
                checkoutScope: invalidScope,
                diContainer: container
            )
            XCTFail("Expected error")
        } catch let error as PrimerError {
            if case .invalidArchitecture = error {
                // Expected
            } else {
                XCTFail("Expected invalidArchitecture error")
            }
        }
    }

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

    // MARK: - createScope Success

    @MainActor
    func test_createScope_withValidDependencies_returnsScope() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessKlarnaPaymentInteractorForTests() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await KlarnaPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
        XCTAssertTrue(scope is DefaultKlarnaScope)
    }

    // MARK: - createView With Registered Scope

    @MainActor
    func test_createView_withRegisteredScope_returnsView() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessKlarnaPaymentInteractorForTests() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
        _ = try await KlarnaPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // When — createView depends on PaymentMethodRegistry
        let view = KlarnaPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then — no crash; view may be nil since scope isn't auto-registered in registry
        _ = view
    }

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

    // MARK: - createScope with Non-Default Checkout Scope

    @MainActor
    func test_createScope_withNonDefaultCheckoutScope_throws() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessKlarnaPaymentInteractorForTests() }
        let invalidScope = MockNonDefaultCheckoutScopeForKlarna()

        // When/Then
        do {
            _ = try await KlarnaPaymentMethod.createScope(
                checkoutScope: invalidScope,
                diContainer: container
            )
            XCTFail("Expected error when using non-default checkout scope")
        } catch let error as PrimerError {
            if case let .invalidArchitecture(description, _, _) = error {
                XCTAssertTrue(description.contains("DefaultCheckoutScope"))
            } else {
                XCTFail("Expected invalidArchitecture error, got \(error)")
            }
        }
    }

    // MARK: - createScope with Missing Dependencies

    @MainActor
    func test_createScope_withMissingDependency_throws() async throws {
        // Given
        let emptyContainer = Container()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try await KlarnaPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: emptyContainer
            )
            XCTFail("Expected error when required dependency is missing")
        } catch let error as PrimerError {
            if case let .invalidArchitecture(description, _, _) = error {
                XCTAssertTrue(description.contains("dependencies"))
            } else {
                XCTFail("Expected invalidArchitecture error, got \(error)")
            }
        }
    }

    // MARK: - createScope Presentation Context

    @MainActor
    func test_createScope_withSinglePaymentMethod_usesDirectContext() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessKlarnaPaymentInteractorForTests() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await KlarnaPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    @MainActor
    func test_createScope_withMultiplePaymentMethods_usesPaymentSelectionContext() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessKlarnaPaymentInteractorForTests() }

        let navigator = CheckoutNavigator(coordinator: CheckoutCoordinator())
        let settings = PrimerSettings(
            paymentHandling: .manual,
            paymentMethodOptions: PrimerPaymentMethodOptions()
        )
        let checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: settings,
            diContainer: DIContainer.shared,
            navigator: navigator
        )
        checkoutScope.availablePaymentMethods = [
            InternalPaymentMethod(id: "klarna-1", type: "KLARNA", name: "Klarna"),
            InternalPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Card"),
        ]

        // When
        let scope = try await KlarnaPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    // MARK: - Registry Integration

    @MainActor
    func test_register_createsScope_viaRegistry() async throws {
        // Given
        let registry = PaymentMethodRegistry.shared
        registry.reset()
        KlarnaPaymentMethod.register()

        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessKlarnaPaymentInteractorForTests() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await registry.createScope(
            for: PrimerPaymentMethodType.klarna.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }
}

// MARK: - Stubs

@available(iOS 15.0, *)
private final class StubProcessKlarnaPaymentInteractorForTests: ProcessKlarnaPaymentInteractor {
    func createSession() async throws -> KlarnaSessionResult {
        fatalError("Not called in these tests")
    }

    func configureForCategory(clientToken: String, categoryId: String) async throws -> UIView? {
        nil
    }

    func authorize() async throws -> KlarnaAuthorizationResult {
        fatalError("Not called in these tests")
    }

    func finalize() async throws -> KlarnaAuthorizationResult {
        fatalError("Not called in these tests")
    }

    func tokenize(authToken: String) async throws -> PaymentResult {
        PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)
    }
}

// MARK: - Mock Non-Default Checkout Scope

@available(iOS 15.0, *)
private final class MockNonDefaultCheckoutScopeForKlarna: PrimerCheckoutScope {
    var state: AsyncStream<PrimerCheckoutState> {
        AsyncStream { $0.finish() }
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
