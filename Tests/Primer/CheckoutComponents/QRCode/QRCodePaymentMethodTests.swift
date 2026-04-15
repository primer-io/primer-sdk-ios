//
//  QRCodePaymentMethodTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest

@available(iOS 15.0, *)
@MainActor
final class QRCodePaymentMethodTests: XCTestCase {

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

    // MARK: - registerAll Tests

    func test_registerAll_withMultipleTypes_registersAll() {
        // Given
        let types: [PrimerPaymentMethodType] = [.xfersPayNow, .rapydPromptPay, .omisePromptPay]

        // When
        QRCodePaymentMethod.registerAll(types)

        // Then
        let registered = PaymentMethodRegistry.shared.registeredTypes
        for type in types {
            XCTAssertTrue(registered.contains(type.rawValue), "Expected \(type.rawValue) to be registered")
        }
    }

    func test_registerAll_withEmptyArray_registersNothing() {
        // When
        QRCodePaymentMethod.registerAll([])

        // Then
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.isEmpty)
    }

    func test_registerAll_withSingleType_registersSuccessfully() {
        // When
        QRCodePaymentMethod.registerAll([.xfersPayNow])

        // Then
        XCTAssertTrue(PaymentMethodRegistry.shared.registeredTypes.contains(PrimerPaymentMethodType.xfersPayNow.rawValue))
    }

    // MARK: - createScope via Registry with Invalid Scope

    func test_createScope_withNonDefaultCheckoutScope_throws() async throws {
        // Given
        QRCodePaymentMethod.registerAll([.xfersPayNow])
        let invalidScope = MockNonDefaultCheckoutScopeForQRCode()

        // When/Then
        do {
            _ = try await PaymentMethodRegistry.shared.createScope(
                for: PrimerPaymentMethodType.xfersPayNow.rawValue,
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

    func test_createScope_withMissingDependency_throws() async throws {
        // Given
        QRCodePaymentMethod.registerAll([.xfersPayNow])
        let emptyContainer = Container()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try await PaymentMethodRegistry.shared.createScope(
                for: PrimerPaymentMethodType.xfersPayNow.rawValue,
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

    // MARK: - createScope Success with Presentation Context

    func test_createScope_withSinglePaymentMethod_usesDirectContext() async throws {
        // Given
        await registerQRCodeDependencies()
        QRCodePaymentMethod.registerAll([.xfersPayNow])
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope: (any PrimerPaymentMethodScope)? = try await PaymentMethodRegistry.shared.createScope(
            for: PrimerPaymentMethodType.xfersPayNow.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
        if let qrScope = scope as? DefaultQRCodeScope {
            XCTAssertEqual(qrScope.presentationContext, .direct)
        }
    }

    func test_createScope_withMultiplePaymentMethods_usesPaymentSelectionContext() async throws {
        // Given
        await registerQRCodeDependencies()
        QRCodePaymentMethod.registerAll([.xfersPayNow])
        let checkoutScope = createCheckoutScopeWithMultiplePaymentMethods()

        // When
        let scope: (any PrimerPaymentMethodScope)? = try await PaymentMethodRegistry.shared.createScope(
            for: PrimerPaymentMethodType.xfersPayNow.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertNotNil(scope)
        if let qrScope = scope as? DefaultQRCodeScope {
            XCTAssertEqual(qrScope.presentationContext, .fromPaymentSelection)
        }
    }

    // MARK: - createView Tests

    func test_createView_withNoScope_returnsNil() {
        // Given
        let invalidScope = MockNonDefaultCheckoutScopeForQRCode()

        // When
        let view = QRCodePaymentMethod.createView(checkoutScope: invalidScope)

        // Then
        XCTAssertNil(view)
    }

    // MARK: - Multiple Types Registration

    func test_registerAll_eachTypeCreatesIndependentScope() async throws {
        // Given
        await registerQRCodeDependencies()
        let types: [PrimerPaymentMethodType] = [.xfersPayNow, .rapydPromptPay]
        QRCodePaymentMethod.registerAll(types)
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then — both should resolve independently
        for type in types {
            let scope: (any PrimerPaymentMethodScope)? = try await PaymentMethodRegistry.shared.createScope(
                for: type.rawValue,
                checkoutScope: checkoutScope,
                diContainer: container
            )
            XCTAssertNotNil(scope, "Expected scope for \(type.rawValue)")
        }
    }

    // MARK: - Helper Methods

    private func registerQRCodeDependencies() async {
        _ = try? await container.register(QRCodeRepository.self)
            .asSingleton()
            .with { _ in StubQRCodeRepository() }

        try? await container.registerFactory(
            QRCodePaymentInteractorFactory.self
        ) { resolver in
            QRCodePaymentInteractorFactory(
                repository: try await resolver.resolve(QRCodeRepository.self)
            )
        }
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
                id: "qr-1",
                type: PrimerPaymentMethodType.xfersPayNow.rawValue,
                name: "PayNow"
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
private final class StubQRCodeRepository: QRCodeRepository {
    func startPayment(paymentMethodType: String) async throws -> QRCodePaymentData {
        QRCodePaymentData(
            qrCodeImageData: Data(),
            statusUrl: URL(string: "https://example.com/status")!,
            paymentId: TestData.PaymentIds.success
        )
    }

    func pollForCompletion(statusUrl: URL) async throws -> String {
        "resume-token"
    }

    func resumePayment(paymentId: String, resumeToken: String, paymentMethodType: String) async throws -> PaymentResult {
        PaymentResult(paymentId: paymentId, status: .success)
    }

    func cancelPolling(paymentMethodType: String) {}
}

// MARK: - Mock Non-Default Checkout Scope

@available(iOS 15.0, *)
private final class MockNonDefaultCheckoutScopeForQRCode: PrimerCheckoutScope {
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
