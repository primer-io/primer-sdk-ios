//
//  WebRedirectPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
final class WebRedirectPaymentMethodTests: XCTestCase {

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

    // MARK: - Static Properties

    func test_paymentMethodType_returnsWebRedirect() {
        XCTAssertEqual(WebRedirectPaymentMethod.paymentMethodType, "WEB_REDIRECT")
    }

    // MARK: - register(types:) Tests

    func test_register_withMultipleTypes_registersAll() {
        // Given
        let types = ["TWINT", "VIPPS", "IDEAL"]

        // When
        WebRedirectPaymentMethod.register(types: types)

        // Then
        let registered = PaymentMethodRegistry.shared.registeredTypes
        for type in types {
            XCTAssertTrue(registered.contains(type), "Expected \(type) to be registered")
        }
    }

    func test_register_withEmptyTypes_registersNothing() {
        // When
        WebRedirectPaymentMethod.register(types: [])

        // Then
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.isEmpty)
    }

    func test_register_withSingleType_registersSuccessfully() {
        // Given
        let type = "TWINT"

        // When
        WebRedirectPaymentMethod.register(types: [type])

        // Then
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.contains(type))
    }

    // MARK: - createScope (Protocol Conformance) Tests

    func test_createScope_protocolConformance_throwsInvalidArchitecture() async throws {
        // Given
        let checkoutScope = MockNonDefaultCheckoutScopeForWebRedirect()

        // When/Then
        do {
            _ = try await WebRedirectPaymentMethod.createScope(
                checkoutScope: checkoutScope,
                diContainer: container
            )
            XCTFail("Expected error from protocol conformance createScope")
        } catch let error as PrimerError {
            if case let .invalidArchitecture(description, _, _) = error {
                XCTAssertTrue(description.contains("payment method type parameter"))
            } else {
                XCTFail("Expected invalidArchitecture error, got \(error)")
            }
        } catch {
            XCTFail("Unexpected error type: \(error)")
        }
    }

    // MARK: - createView (Protocol Conformance) Tests

    func test_createView_protocolConformance_returnsNil() {
        // Given
        let checkoutScope = MockNonDefaultCheckoutScopeForWebRedirect()

        // When
        let view = WebRedirectPaymentMethod.createView(checkoutScope: checkoutScope)

        // Then
        XCTAssertNil(view)
    }

    // MARK: - createScope via Registry with Invalid Scope

    func test_registeredScope_withNonDefaultCheckoutScope_throws() async throws {
        // Given
        WebRedirectPaymentMethod.register(types: ["TWINT"])
        let invalidScope = MockNonDefaultCheckoutScopeForWebRedirect()

        // When/Then
        do {
            _ = try await PaymentMethodRegistry.shared.createScope(
                for: "TWINT",
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

    // MARK: - createScope via Registry with Missing Dependencies

    func test_registeredScope_withMissingDependency_throws() async throws {
        // Given — register after scope creation since init calls reset()
        let emptyContainer = Container()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
        WebRedirectPaymentMethod.register(types: ["TWINT"])

        // When/Then
        do {
            _ = try await PaymentMethodRegistry.shared.createScope(
                for: "TWINT",
                checkoutScope: checkoutScope,
                diContainer: emptyContainer
            )
            XCTFail("Expected error when required dependency is missing")
        } catch {
            // Expected — container doesn't have ProcessWebRedirectPaymentInteractor
            XCTAssertTrue(error is ContainerError || error is PrimerError)
        }
    }

    // MARK: - Presentation Context

    func test_registeredScope_withSinglePaymentMethod_usesDirectContext() async throws {
        // Given — register after scope creation since init calls reset()
        await registerWebRedirectDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
        WebRedirectPaymentMethod.register(types: ["TWINT"])

        // When
        let scope: (any PrimerPaymentMethodScope)? = try await PaymentMethodRegistry.shared.createScope(
            for: "TWINT",
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
        if let webRedirectScope = scope as? DefaultWebRedirectScope {
            XCTAssertEqual(webRedirectScope.presentationContext, .direct)
        }
    }

    func test_registeredScope_withMultiplePaymentMethods_usesPaymentSelectionContext() async throws {
        // Given — register after scope creation since init calls reset()
        await registerWebRedirectDependencies()
        let checkoutScope = createCheckoutScopeWithMultiplePaymentMethods()
        WebRedirectPaymentMethod.register(types: ["TWINT"])

        // When
        let scope: (any PrimerPaymentMethodScope)? = try await PaymentMethodRegistry.shared.createScope(
            for: "TWINT",
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
        if let webRedirectScope = scope as? DefaultWebRedirectScope {
            XCTAssertEqual(webRedirectScope.presentationContext, .fromPaymentSelection)
        }
    }

    // MARK: - getView via Registry

    func test_getView_withNoScopeRegistered_returnsNil() {
        // Given
        WebRedirectPaymentMethod.register(types: ["TWINT"])
        let checkoutScope = MockNonDefaultCheckoutScopeForWebRedirect()

        // When
        let view = PaymentMethodRegistry.shared.getView(for: "TWINT", checkoutScope: checkoutScope)

        // Then
        XCTAssertNil(view)
    }

    // MARK: - PaymentMethodRegistry register(paymentMethodType:) Extension

    func test_paymentMethodRegistry_registerExtension_registersTypeKey() {
        // Given
        let typeKey = "CUSTOM_WEB_REDIRECT"

        // When
        PaymentMethodRegistry.shared.register(
            paymentMethodType: typeKey,
            scopeCreator: { _, _, _ in
                fatalError("Not called")
            },
            viewCreator: { _, _ in nil }
        )

        // Then
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.contains(typeKey))
    }

    // MARK: - Helper Methods

    private func registerWebRedirectDependencies() async {
        _ = try? await container.register(ProcessWebRedirectPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubProcessWebRedirectPaymentInteractor() }

        _ = try? await container.register(PaymentMethodMapper.self)
            .asSingleton()
            .with { _ in StubPaymentMethodMapper() }

        _ = try? await container.register(WebRedirectRepository.self)
            .asSingleton()
            .with { _ in MockWebRedirectRepository() }
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
                id: "twint-1",
                type: "TWINT",
                name: "Twint"
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
private final class StubProcessWebRedirectPaymentInteractor: ProcessWebRedirectPaymentInteractor {
    func execute(paymentMethodType: String) async throws -> PaymentResult {
        PaymentResult(paymentId: TestData.PaymentIds.success, status: .success)
    }
}

@available(iOS 15.0, *)
private final class StubPaymentMethodMapper: PaymentMethodMapper {
    func mapToPublic(_ internalMethod: InternalPaymentMethod) -> CheckoutPaymentMethod {
        CheckoutPaymentMethod(
            id: internalMethod.id,
            type: internalMethod.type,
            name: internalMethod.name
        )
    }

    func mapToPublic(_ internalMethods: [InternalPaymentMethod]) -> [CheckoutPaymentMethod] {
        internalMethods.map { mapToPublic($0) }
    }
}

// MARK: - Mock Non-Default Checkout Scope

@available(iOS 15.0, *)
private final class MockNonDefaultCheckoutScopeForWebRedirect: PrimerCheckoutScope {
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
