//
//  AdyenKlarnaPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
final class AdyenKlarnaPaymentMethodTests: XCTestCase {

    // MARK: - Payment Method Type

    func test_paymentMethodType_returnsAdyenKlarnaType() {
        XCTAssertEqual(AdyenKlarnaPaymentMethod.paymentMethodType, PrimerPaymentMethodType.adyenKlarna.rawValue)
    }

    func test_paymentMethodType_rawValue() {
        XCTAssertEqual(AdyenKlarnaPaymentMethod.paymentMethodType, "ADYEN_KLARNA")
    }

    // MARK: - Registration

    @MainActor
    func test_register_registersAdyenKlarnaPaymentMethod() {
        // Given
        let registry = PaymentMethodRegistry.shared

        // When
        AdyenKlarnaPaymentMethod.register()

        // Then
        XCTAssertTrue(registry.registeredTypes.contains(PrimerPaymentMethodType.adyenKlarna.rawValue))
    }

    // MARK: - createView

    @MainActor
    func test_createView_withNoScope_returnsNil() {
        // Given
        let checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        // When
        let view = AdyenKlarnaPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then
        XCTAssertNil(view)
    }

    @MainActor
    func test_createView_withNonDefaultCheckoutScope_returnsNil() {
        // Given
        let mockScope = MockNonDefaultCheckoutScopeForAdyenKlarna()

        // When
        let view = AdyenKlarnaPaymentMethod.createView(checkoutScope: mockScope)

        // Then
        XCTAssertNil(view)
    }

    // MARK: - createScope Success

    @MainActor
    func test_createScope_withValidDependencies_returnsScope() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessAdyenKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessAdyenKlarnaPaymentInteractor() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await AdyenKlarnaPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
        XCTAssertTrue(scope is DefaultAdyenKlarnaScope)
    }

    // MARK: - createScope with Non-Default Checkout Scope

    @MainActor
    func test_createScope_withNonDefaultCheckoutScope_throws() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessAdyenKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessAdyenKlarnaPaymentInteractor() }
        let invalidScope = MockNonDefaultCheckoutScopeForAdyenKlarna()

        // When/Then
        do {
            _ = try await AdyenKlarnaPaymentMethod.createScope(
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
            _ = try await AdyenKlarnaPaymentMethod.createScope(
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
        let container = try await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessAdyenKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessAdyenKlarnaPaymentInteractor() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await AdyenKlarnaPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    @MainActor
    func test_createScope_withMultiplePaymentMethods_usesPaymentSelectionContext() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessAdyenKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessAdyenKlarnaPaymentInteractor() }

        let navigator = CheckoutNavigator(coordinator: CheckoutCoordinator())
        let checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(paymentHandling: .manual),
            diContainer: DIContainer.shared,
            navigator: navigator
        )
        checkoutScope.availablePaymentMethods = [
            InternalPaymentMethod(id: "klarna-1", type: "ADYEN_KLARNA", name: "Adyen Klarna"),
            InternalPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Card"),
        ]

        // When
        let scope = try await AdyenKlarnaPaymentMethod.createScope(
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
        AdyenKlarnaPaymentMethod.register()

        let container = try await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessAdyenKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessAdyenKlarnaPaymentInteractor() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await registry.createScope(
            for: PrimerPaymentMethodType.adyenKlarna.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    // MARK: - createView with Registered Scope

    @MainActor
    func test_createView_withRegisteredScope_doesNotCrash() async throws {
        // Given
        let container = try await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessAdyenKlarnaPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessAdyenKlarnaPaymentInteractor() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
        _ = try await AdyenKlarnaPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // When
        let view = AdyenKlarnaPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then — no crash; view may be nil since scope isn't auto-registered in registry
        _ = view
    }
}

// MARK: - Mock Non-Default Checkout Scope

@available(iOS 15.0, *)
private final class MockNonDefaultCheckoutScopeForAdyenKlarna: PrimerCheckoutScope {
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
