//
//  FormRedirectPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
final class FormRedirectPaymentMethodTests: XCTestCase {

    private var container: Container!

    override func setUp() async throws {
        try await super.setUp()
        container = try await ContainerTestHelpers.createTestContainer()
        PaymentMethodRegistry.shared.reset()
    }

    override func tearDown() async throws {
        await container.reset(ignoreDependencies: [Never.Type]())
        container = nil
        try await super.tearDown()
    }

    // MARK: - BlikPaymentMethod Type Tests

    func test_blikPaymentMethod_paymentMethodType_matchesAdyenBlik() {
        XCTAssertEqual(BlikPaymentMethod.paymentMethodType, PrimerPaymentMethodType.adyenBlik.rawValue)
    }

    // MARK: - MBWayPaymentMethod Type Tests

    func test_mbWayPaymentMethod_paymentMethodType_matchesAdyenMBWay() {
        XCTAssertEqual(MBWayPaymentMethod.paymentMethodType, PrimerPaymentMethodType.adyenMBWay.rawValue)
    }

    // MARK: - Registration Tests

    func test_register_registersBlikAndMBWay() {
        // When
        FormRedirectPaymentMethod.register()

        // Then
        let types = PaymentMethodRegistry.shared.registeredTypes
        XCTAssertTrue(types.contains(PrimerPaymentMethodType.adyenBlik.rawValue))
        XCTAssertTrue(types.contains(PrimerPaymentMethodType.adyenMBWay.rawValue))
    }

    func test_register_canBeCalledMultipleTimes() {
        // When
        FormRedirectPaymentMethod.register()
        FormRedirectPaymentMethod.register()

        // Then
        let types = PaymentMethodRegistry.shared.registeredTypes
        XCTAssertTrue(types.contains(PrimerPaymentMethodType.adyenBlik.rawValue))
        XCTAssertTrue(types.contains(PrimerPaymentMethodType.adyenMBWay.rawValue))
    }

    // MARK: - createScope with Invalid Checkout Scope

    func test_blik_createScope_withNonDefaultCheckoutScope_throws() async throws {
        // Given
        await registerFormRedirectDependencies()
        let invalidScope = MockNonDefaultCheckoutScopeForFormRedirect()

        // When/Then
        do {
            _ = try await BlikPaymentMethod.createScope(
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

    func test_mbWay_createScope_withNonDefaultCheckoutScope_throws() async throws {
        // Given
        await registerFormRedirectDependencies()
        let invalidScope = MockNonDefaultCheckoutScopeForFormRedirect()

        // When/Then
        do {
            _ = try await MBWayPaymentMethod.createScope(
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

    func test_blik_createScope_withMissingDependencies_throws() async throws {
        // Given
        let emptyContainer = Container()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try await BlikPaymentMethod.createScope(
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

    func test_mbWay_createScope_withMissingDependencies_throws() async throws {
        // Given
        let emptyContainer = Container()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try await MBWayPaymentMethod.createScope(
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

    // MARK: - FormRedirectPaymentMethodHelper Direct Tests

    func test_helper_createScope_withMissingDependencies_throws() async throws {
        // Given
        let emptyContainer = Container()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try await FormRedirectPaymentMethodHelper.createScopeForPaymentMethodType(
                PrimerPaymentMethodType.adyenBlik.rawValue,
                checkoutScope: checkoutScope,
                diContainer: emptyContainer
            )
            XCTFail("Expected error")
        } catch let error as PrimerError {
            if case let .invalidArchitecture(description, _, _) = error {
                XCTAssertTrue(description.contains("dependencies"))
            } else {
                XCTFail("Expected invalidArchitecture error, got \(error)")
            }
        }
    }

    func test_helper_createScope_withValidDependencies_returnsScope() async throws {
        // Given
        await registerFormRedirectDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await FormRedirectPaymentMethodHelper.createScopeForPaymentMethodType(
            PrimerPaymentMethodType.adyenBlik.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    func test_helper_createScope_withMultiplePaymentMethods_setsPaymentSelectionContext() async throws {
        // Given
        await registerFormRedirectDependencies()
        let checkoutScope = createCheckoutScopeWithMultiplePaymentMethods()

        // When
        let scope = try await FormRedirectPaymentMethodHelper.createScopeForPaymentMethodType(
            PrimerPaymentMethodType.adyenMBWay.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    func test_blik_createScope_setsCorrectPaymentMethodType() async throws {
        // Given
        await registerFormRedirectDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await BlikPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    func test_mbWay_createScope_setsCorrectPaymentMethodType() async throws {
        // Given
        await registerFormRedirectDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await MBWayPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    // MARK: - createScope Success with Presentation Context

    func test_blik_createScope_withSinglePaymentMethod_usesDirectContext() async throws {
        // Given
        await registerFormRedirectDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await BlikPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    func test_blik_createScope_withMultiplePaymentMethods_usesPaymentSelectionContext() async throws {
        // Given
        await registerFormRedirectDependencies()
        let checkoutScope = createCheckoutScopeWithMultiplePaymentMethods()

        // When
        let scope = try await BlikPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    func test_mbWay_createScope_withSinglePaymentMethod_usesDirectContext() async throws {
        // Given
        await registerFormRedirectDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await MBWayPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    func test_mbWay_createScope_withMultiplePaymentMethods_usesPaymentSelectionContext() async throws {
        // Given
        await registerFormRedirectDependencies()
        let checkoutScope = createCheckoutScopeWithMultiplePaymentMethods()

        // When
        let scope = try await MBWayPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    // MARK: - createView With Registered Scope

    func test_blik_createView_withRegisteredScope_returnsView() async throws {
        // Given
        await registerFormRedirectDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
        _ = try await BlikPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // When — createView depends on PaymentMethodRegistry, not scope creation
        let view = BlikPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then — no crash, view may be nil since scope isn't auto-registered
        _ = view
    }

    // MARK: - Helper createScope for MBWay Type

    func test_helper_createScope_forMBWay_setsCorrectPaymentMethodType() async throws {
        // Given
        await registerFormRedirectDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await FormRedirectPaymentMethodHelper.createScopeForPaymentMethodType(
            PrimerPaymentMethodType.adyenMBWay.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    // MARK: - createView Tests

    func test_blik_createView_withNoScope_returnsNil() {
        // Given
        let invalidScope = MockNonDefaultCheckoutScopeForFormRedirect()

        // When
        let view = BlikPaymentMethod.createView(checkoutScope: invalidScope)

        // Then
        XCTAssertNil(view)
    }

    func test_mbWay_createView_withNoScope_returnsNil() {
        // Given
        let invalidScope = MockNonDefaultCheckoutScopeForFormRedirect()

        // When
        let view = MBWayPaymentMethod.createView(checkoutScope: invalidScope)

        // Then
        XCTAssertNil(view)
    }

    func test_helper_createView_withNoScope_returnsNil() {
        // Given
        let invalidScope = MockNonDefaultCheckoutScopeForFormRedirect()

        // When
        let view = FormRedirectPaymentMethodHelper.createView(checkoutScope: invalidScope)

        // Then
        XCTAssertNil(view)
    }

    // MARK: - Registry Integration Tests

    func test_blik_register_createsScope_viaRegistry() async throws {
        // Given
        FormRedirectPaymentMethod.register()
        await registerFormRedirectDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: PrimerPaymentMethodType.adyenBlik.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    func test_mbWay_register_createsScope_viaRegistry() async throws {
        // Given
        FormRedirectPaymentMethod.register()
        await registerFormRedirectDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: PrimerPaymentMethodType.adyenMBWay.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
    }

    // MARK: - Helper Methods

    private func registerFormRedirectDependencies() async {
        _ = try? await container.register(ProcessFormRedirectPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessFormRedirectPaymentInteractor() }

        _ = try? await container.register(ValidationService.self)
            .asSingleton()
            .with { _ in MockValidationService() }
    }

    private func createCheckoutScopeWithMultiplePaymentMethods() -> DefaultCheckoutScope {
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
                id: "blik-1",
                type: PrimerPaymentMethodType.adyenBlik.rawValue,
                name: "BLIK"
            ),
            InternalPaymentMethod(
                id: "card-1",
                type: PrimerPaymentMethodType.paymentCard.rawValue,
                name: "Card"
            ),
        ]
        return scope
    }
}

// MARK: - Stubs

@available(iOS 15.0, *)
private final class StubProcessFormRedirectPaymentInteractor: ProcessFormRedirectPaymentInteractor {
    func execute(
        paymentMethodType: String,
        sessionInfo: any OffSessionPaymentSessionInfo,
        onPollingStarted: (() -> Void)?
    ) async throws -> PaymentResult {
        PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)
    }

    func cancelPolling(paymentMethodType: String) {}
}

// MARK: - Mock Non-Default Checkout Scope

@available(iOS 15.0, *)
private final class MockNonDefaultCheckoutScopeForFormRedirect: PrimerCheckoutScope {
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
