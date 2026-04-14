//
//  SwishRegistrationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class SwishRegistrationTests: XCTestCase {

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

    // MARK: - PrimerPaymentMethodType Tests

    func test_adyenSwish_rawValue() {
        XCTAssertEqual(PrimerPaymentMethodType.adyenSwish.rawValue, "ADYEN_SWISH")
    }

    func test_adyenSwish_provider() {
        XCTAssertEqual(PrimerPaymentMethodType.adyenSwish.provider, "ADYEN")
    }

    func test_adyenSwish_decodable() throws {
        let data = Data("\"ADYEN_SWISH\"".utf8)
        let decoded = try JSONDecoder().decode(PrimerPaymentMethodType.self, from: data)
        XCTAssertEqual(decoded, .adyenSwish)
    }

    func test_adyenSwish_encodable() throws {
        let encoded = try JSONEncoder().encode(PrimerPaymentMethodType.adyenSwish)
        let string = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(string, "\"ADYEN_SWISH\"")
    }

    func test_adyenSwish_includedInAllCases() {
        XCTAssertTrue(PrimerPaymentMethodType.allCases.contains(.adyenSwish))
    }

    // MARK: - WebRedirect Registration Tests

    func test_swish_registeredAsWebRedirect() {
        // Given
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.adyenSwish.rawValue])

        // Then
        let registered = PaymentMethodRegistry.shared.registeredTypes
        XCTAssertTrue(registered.contains(PrimerPaymentMethodType.adyenSwish.rawValue))
    }

    func test_swish_notRegistered_whenNotIncluded() {
        // Given
        WebRedirectPaymentMethod.register(types: ["ADYEN_TWINT"])

        // Then
        let registered = PaymentMethodRegistry.shared.registeredTypes
        XCTAssertFalse(registered.contains(PrimerPaymentMethodType.adyenSwish.rawValue))
    }

    func test_swish_createScope_returnsDefaultWebRedirectScope() async throws {
        // Given
        await registerWebRedirectDependencies()
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.adyenSwish.rawValue])
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: PrimerPaymentMethodType.adyenSwish.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertTrue(scope is DefaultWebRedirectScope)
    }

    func test_swish_createScope_setsCorrectPaymentMethodType() async throws {
        // Given
        await registerWebRedirectDependencies()
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.adyenSwish.rawValue])
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: PrimerPaymentMethodType.adyenSwish.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        let webRedirectScope = try XCTUnwrap(scope as? DefaultWebRedirectScope)
        XCTAssertEqual(webRedirectScope.paymentMethodType, PrimerPaymentMethodType.adyenSwish.rawValue)
    }

    func test_swish_createScope_withMissingDependencies_throws() async throws {
        // Given
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.adyenSwish.rawValue])
        let emptyContainer = Container()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try await PaymentMethodRegistry.shared.createScope(
                for: PrimerPaymentMethodType.adyenSwish.rawValue,
                checkoutScope: checkoutScope,
                diContainer: emptyContainer
            )
            XCTFail("Expected error when required dependency is missing")
        } catch {
            XCTAssertTrue(error is ContainerError || error is PrimerError)
        }
    }

    func test_swish_registeredAlongsideOtherWebRedirectTypes() {
        // Given
        let types = [
            "ADYEN_TWINT",
            PrimerPaymentMethodType.adyenSwish.rawValue,
            "ADYEN_SOFORT"
        ]

        // When
        WebRedirectPaymentMethod.register(types: types)

        // Then
        let registered = PaymentMethodRegistry.shared.registeredTypes
        for type in types {
            XCTAssertTrue(registered.contains(type), "Expected \(type) to be registered")
        }
    }

    // MARK: - Helper Methods

    private func registerWebRedirectDependencies() async {
        _ = try? await container.register(ProcessWebRedirectPaymentInteractor.self)
            .asSingleton()
            .with { _ in StubSwishWebRedirectInteractor() }

        _ = try? await container.register(PaymentMethodMapper.self)
            .asSingleton()
            .with { _ in StubSwishPaymentMethodMapper() }

        _ = try? await container.register(WebRedirectRepository.self)
            .asSingleton()
            .with { _ in MockWebRedirectRepository() }
    }
}

// MARK: - Stubs

@available(iOS 15.0, *)
private final class StubSwishWebRedirectInteractor: ProcessWebRedirectPaymentInteractor {
    func execute(paymentMethodType: String) async throws -> PaymentResult {
        PaymentResult(paymentId: "swish_payment_123", status: .success)
    }
}

@available(iOS 15.0, *)
private final class StubSwishPaymentMethodMapper: PaymentMethodMapper {
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
