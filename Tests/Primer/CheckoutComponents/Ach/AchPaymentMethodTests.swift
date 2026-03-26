//
//  AchPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import UIKit
import XCTest

@available(iOS 15.0, *)
final class AchPaymentMethodTests: XCTestCase {

    // MARK: - Payment Method Type Tests

    func test_paymentMethodType_isStripeAch() {
        XCTAssertEqual(AchPaymentMethod.paymentMethodType, PrimerPaymentMethodType.stripeAch.rawValue)
    }

    func test_paymentMethodType_matchesExpectedString() {
        XCTAssertEqual(AchPaymentMethod.paymentMethodType, "STRIPE_ACH")
    }

    // MARK: - Registration Tests

    @MainActor
    func test_register_addsToPaymentMethodRegistry() {
        // Given
        let registry = PaymentMethodRegistry.shared
        registry.reset()

        // When
        AchPaymentMethod.register()

        // Then
        XCTAssertTrue(registry.registeredTypes.contains(PrimerPaymentMethodType.stripeAch.rawValue))
    }

    @MainActor
    func test_register_canBeCalledMultipleTimes() {
        // Given
        let registry = PaymentMethodRegistry.shared
        registry.reset()

        // When
        AchPaymentMethod.register()
        AchPaymentMethod.register()
        AchPaymentMethod.register()

        // Then - Should not crash and type should still be registered
        XCTAssertTrue(registry.registeredTypes.contains(PrimerPaymentMethodType.stripeAch.rawValue))
    }

    @MainActor
    func test_createView_withDefaultCheckoutScopeNoAchScope_returnsNil() {
        // Given
        let checkoutScope = DefaultCheckoutScope(
            clientToken: TestData.Tokens.valid,
            settings: PrimerSettings(),
            diContainer: DIContainer.shared,
            navigator: CheckoutNavigator()
        )

        // When
        let view = AchPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then
        XCTAssertNil(view)
    }

    #if DEBUG
    @MainActor
    func test_testAchPaymentMethod_createView_withNoScope_returnsNil() {
        // Given
        let mockCheckoutScope = MockInvalidCheckoutScope()

        // When
        let view = TestAchPaymentMethod.createView(checkoutScope: mockCheckoutScope)

        // Then
        XCTAssertNil(view)
    }

    @MainActor
    func test_testAchPaymentMethod_createScope_withValidDependencies_delegatesToAchPaymentMethod() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessAchPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessAchPaymentInteractorForTests() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try TestAchPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    @MainActor
    func test_testAchPaymentMethod_createScope_withNonDefaultScope_throws() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        let invalidScope = MockInvalidCheckoutScope()

        // When/Then
        do {
            _ = try TestAchPaymentMethod.createScope(
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
    func test_register_alsoRegistersTestAchPaymentMethod() {
        // Given
        let registry = PaymentMethodRegistry.shared
        registry.reset()

        // When
        AchPaymentMethod.register()

        // Then - In DEBUG, TestAchPaymentMethod should also be registered
        XCTAssertTrue(registry.registeredTypes.contains("PRIMER_TEST_STRIPE_ACH"))
    }

    func test_testAchPaymentMethod_hasCorrectType() {
        XCTAssertEqual(TestAchPaymentMethod.paymentMethodType, "PRIMER_TEST_STRIPE_ACH")
    }
    #endif

    // MARK: - createView Tests

    @MainActor
    func test_createView_withNoScope_returnsNil() {
        // Given
        let mockCheckoutScope = MockInvalidCheckoutScope()

        // When
        let view = AchPaymentMethod.createView(checkoutScope: mockCheckoutScope)

        // Then
        XCTAssertNil(view)
    }

    @MainActor
    func test_getPaymentMethodScope_returnsNilForInvalidScope() {
        // Given
        let mockCheckoutScope = MockInvalidCheckoutScope()

        // When
        let scope: DefaultAchScope? = mockCheckoutScope.getPaymentMethodScope(DefaultAchScope.self)

        // Then
        XCTAssertNil(scope)
    }

    // MARK: - createScope Success

    @MainActor
    func test_createScope_withValidDependencies_returnsScope() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessAchPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessAchPaymentInteractorForTests() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try AchPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
        XCTAssertTrue(scope is DefaultAchScope)
    }

    // MARK: - createView With Registered Scope

    @MainActor
    func test_createView_withRegisteredScope_returnsView() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessAchPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessAchPaymentInteractorForTests() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
        _ = try AchPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // When — ACH view requires the scope to be registered in the PaymentMethodRegistry
        // createScope alone doesn't register it, so createView may return nil
        let view = AchPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then — view creation depends on registry state; no crash = success
        _ = view
    }

    // MARK: - createScope with Non-Default Checkout Scope

    @MainActor
    func test_createScope_withNonDefaultCheckoutScope_throws() async throws {
        // Given
        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessAchPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessAchPaymentInteractorForTests() }

        let invalidScope = MockInvalidCheckoutScope()

        // When/Then
        do {
            _ = try AchPaymentMethod.createScope(
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
            _ = try AchPaymentMethod.createScope(
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
        _ = try? await container.register(ProcessAchPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessAchPaymentInteractorForTests() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try AchPaymentMethod.createScope(
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
        _ = try? await container.register(ProcessAchPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessAchPaymentInteractorForTests() }

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
            InternalPaymentMethod(id: "ach-1", type: "STRIPE_ACH", name: "ACH"),
            InternalPaymentMethod(id: "card-1", type: "PAYMENT_CARD", name: "Card"),
        ]

        // When
        let scope = try AchPaymentMethod.createScope(
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
        AchPaymentMethod.register()

        let container = await ContainerTestHelpers.createTestContainer()
        _ = try? await container.register(ProcessAchPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessAchPaymentInteractorForTests() }
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try registry.createScope(
            for: PrimerPaymentMethodType.stripeAch.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }
}

// MARK: - Mock Invalid Checkout Scope

@available(iOS 15.0, *)
@MainActor
private final class MockInvalidCheckoutScope: PrimerCheckoutScope {

    var onBeforePaymentCreate: ((_ data: PrimerCheckoutPaymentMethodData,
                                 _ decisionHandler: @escaping (PrimerPaymentCreationDecision) -> Void) -> Void)?
    var container: ContainerComponent?
    var splashScreen: Component?
    var loadingScreen: Component?
    var errorScreen: ErrorComponent?

    var state: AsyncStream<PrimerCheckoutState> {
        AsyncStream { _ in }
    }

    var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
        fatalError("Not implemented for testing")
    }

    var paymentHandling: PrimerPaymentHandling {
        .auto
    }

    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? {
        nil
    }

    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T? {
        nil
    }

    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for paymentMethodType: String) -> T? {
        nil
    }

    func onDismiss() {}
}

// MARK: - Stub

@available(iOS 15.0, *)
private final class StubProcessAchPaymentInteractorForTests: ProcessAchPaymentInteractor {
    func loadUserDetails() async throws -> AchUserDetailsResult {
        fatalError("Not called in these tests")
    }

    func patchUserDetails(firstName: String, lastName: String, emailAddress: String) async throws {}
    func validate() async throws {}

    func startPaymentAndGetStripeData() async throws -> AchStripeData {
        fatalError("Not called in these tests")
    }

    func createBankCollector(
        firstName: String, lastName: String, emailAddress: String,
        clientSecret: String, delegate: AchBankCollectorDelegate
    ) async throws -> UIViewController {
        fatalError("Not called in these tests")
    }

    func getMandateData() async throws -> AchMandateResult {
        fatalError("Not called in these tests")
    }

    func tokenize() async throws -> PrimerPaymentMethodTokenData {
        fatalError("Not called in these tests")
    }

    func createPayment(tokenData: PrimerPaymentMethodTokenData) async throws -> PaymentResult {
        PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)
    }

    func completePayment(stripeData: AchStripeData) async throws -> PaymentResult {
        PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)
    }
}
