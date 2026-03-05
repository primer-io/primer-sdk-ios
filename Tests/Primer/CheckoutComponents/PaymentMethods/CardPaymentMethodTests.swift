//
//  CardPaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

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

    // MARK: - createScope Error Cases

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

    // MARK: - createScope Success Cases

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

        // Then
        XCTAssertNotNil(scope)
    }

    // MARK: - Presentation Context

    func test_createScope_withSinglePaymentMethod_usesDirectContext() async throws {
        // Given
        await registerCardPaymentDependencies()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    func test_createScope_withExactlyOnePaymentMethod_usesDirectContext() async throws {
        // Given
        await registerCardPaymentDependencies()

        let checkoutScope = createCheckoutScopeWithPaymentMethods([
            InternalPaymentMethod(
                id: "card-only",
                type: PrimerPaymentMethodType.paymentCard.rawValue,
                name: "Card"
            )
        ])

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .direct)
    }

    func test_createScope_withExactlyTwoPaymentMethods_usesPaymentSelectionContext() async throws {
        // Given
        await registerCardPaymentDependencies()

        let checkoutScope = createCheckoutScopeWithPaymentMethods([
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
        ])

        // When
        let scope = try CardPaymentMethod.createScope(
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertEqual(scope.presentationContext, .fromPaymentSelection)
    }

    // MARK: - createView Tests

    func test_createView_withMockInvalidScope_returnsNil() async throws {
        // Given - an invalid checkout scope type
        let invalidCheckoutScope = MockInvalidCheckoutScopeForCardTests()

        // When
        let view = CardPaymentMethod.createView(checkoutScope: invalidCheckoutScope)

        // Then
        XCTAssertNil(view)
    }

    // MARK: - Register Tests

    func test_register_addsToPaymentMethodRegistry() async throws {
        // When
        CardPaymentMethod.register()

        // Then
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
            XCTFail("Registry should have CardPaymentMethod registered: \(error)")
        }
    }

    func test_register_canBeCalledMultipleTimes() async throws {
        // Given
        CardPaymentMethod.register()

        // When
        CardPaymentMethod.register()

        // Then
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
        _ = try? await container.register(ProcessCardPaymentInteractor.self)
            .asSingleton()
            .with { _ in MockProcessCardPaymentInteractor() }

        _ = try? await container.register(ValidateInputInteractor.self)
            .asSingleton()
            .with { _ in MockValidateInputInteractor() }

        _ = try? await container.register(CardNetworkDetectionInteractor.self)
            .asSingleton()
            .with { _ in MockCardNetworkDetectionInteractor() }

        _ = try? await container.register(ConfigurationService.self)
            .asSingleton()
            .with { _ in MockConfigurationService.withDefaultConfiguration() }
    }

    private func createCheckoutScopeWithPaymentMethods(_ methods: [InternalPaymentMethod]) -> DefaultCheckoutScope {
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
        scope.availablePaymentMethods = methods
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
    var loadingScreen: Component?
    var errorScreen: ErrorComponent?
    var onBeforePaymentCreate: BeforePaymentCreateHandler?
    var paymentMethodSelection: PrimerPaymentMethodSelectionScope {
        fatalError("Not implemented")
    }
    var paymentHandling: PrimerPaymentHandling { .auto }

    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(_ scopeType: T.Type) -> T? { nil }
    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for methodType: PrimerPaymentMethodType) -> T? { nil }
    func getPaymentMethodScope<T: PrimerPaymentMethodScope>(for paymentMethodType: String) -> T? { nil }
    func onDismiss() {}
}

// MARK: - Minimal DI Stubs (only used for container registration)

@available(iOS 15.0, *)
private final class MockProcessCardPaymentInteractor: ProcessCardPaymentInteractor {
    func execute(cardData: CardPaymentData) async throws -> PaymentResult {
        PaymentResult(paymentId: "test-payment-id", status: .success)
    }
}

@available(iOS 15.0, *)
private final class MockValidateInputInteractor: ValidateInputInteractor {
    func validate(value: String, type: PrimerInputElementType) async -> ValidationResult {
        ValidationResult(isValid: true, errorCode: nil, errorMessage: nil)
    }

    func validateMultiple(fields: [PrimerInputElementType: String]) async -> [PrimerInputElementType: ValidationResult] {
        [:]
    }
}

@available(iOS 15.0, *)
private final class MockCardNetworkDetectionInteractor: CardNetworkDetectionInteractor {
    var networkDetectionStream: AsyncStream<[CardNetwork]> {
        AsyncStream { $0.finish() }
    }

    var binDataStream: AsyncStream<PrimerBinData> {
        AsyncStream { $0.finish() }
    }

    func detectNetworks(for cardNumber: String) async {}
    func selectNetwork(_ network: CardNetwork) async {}
}
