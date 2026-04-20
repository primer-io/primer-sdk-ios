//
//  NetsRegistrationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class NetsRegistrationTests: XCTestCase {

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

    func test_nets_rawValue() {
        XCTAssertEqual(PrimerPaymentMethodType.nets.rawValue, "NETS")
    }

    func test_nets_provider() {
        XCTAssertEqual(PrimerPaymentMethodType.nets.provider, "NETS")
    }

    func test_nets_decodable() throws {
        let data = Data("\"NETS\"".utf8)
        let decoded = try JSONDecoder().decode(PrimerPaymentMethodType.self, from: data)
        XCTAssertEqual(decoded, .nets)
    }

    func test_nets_encodable() throws {
        let encoded = try JSONEncoder().encode(PrimerPaymentMethodType.nets)
        let string = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(string, "\"NETS\"")
    }

    func test_nets_includedInAllCases() {
        XCTAssertTrue(PrimerPaymentMethodType.allCases.contains(.nets))
    }

    // MARK: - WebRedirect Registration Tests

    func test_nets_registeredAsWebRedirect() {
        // Given
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.nets.rawValue])

        // Then
        let registered = PaymentMethodRegistry.shared.registeredTypes
        XCTAssertTrue(registered.contains(PrimerPaymentMethodType.nets.rawValue))
    }

    func test_nets_notRegistered_whenNotIncluded() {
        // Given
        WebRedirectPaymentMethod.register(types: ["ADYEN_TWINT"])

        // Then
        let registered = PaymentMethodRegistry.shared.registeredTypes
        XCTAssertFalse(registered.contains(PrimerPaymentMethodType.nets.rawValue))
    }

    func test_nets_createScope_returnsDefaultWebRedirectScope() async throws {
        // Given
        await registerWebRedirectDependencies()
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.nets.rawValue])
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: PrimerPaymentMethodType.nets.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertTrue(scope is DefaultWebRedirectScope)
    }

    func test_nets_createScope_setsCorrectPaymentMethodType() async throws {
        // Given
        await registerWebRedirectDependencies()
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.nets.rawValue])
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: PrimerPaymentMethodType.nets.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        let webRedirectScope = try XCTUnwrap(scope as? DefaultWebRedirectScope)
        XCTAssertEqual(webRedirectScope.paymentMethodType, PrimerPaymentMethodType.nets.rawValue)
    }

    func test_nets_createScope_withMissingDependencies_throws() async throws {
        // Given
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.nets.rawValue])
        let emptyContainer = Container()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try await PaymentMethodRegistry.shared.createScope(
                for: PrimerPaymentMethodType.nets.rawValue,
                checkoutScope: checkoutScope,
                diContainer: emptyContainer
            )
            XCTFail("Expected error when required dependency is missing")
        } catch {
            XCTAssertTrue(error is ContainerError || error is PrimerError)
        }
    }

    func test_nets_registeredAlongsideOtherWebRedirectTypes() {
        // Given
        let types = [
            "ADYEN_TWINT",
            PrimerPaymentMethodType.nets.rawValue,
            PrimerPaymentMethodType.payNLKaartdirect.rawValue
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
            .with { _ in StubNetsWebRedirectInteractor() }

        _ = try? await container.register(PaymentMethodMapper.self)
            .asSingleton()
            .with { _ in StubNetsPaymentMethodMapper() }

        _ = try? await container.register(WebRedirectRepository.self)
            .asSingleton()
            .with { _ in MockWebRedirectRepository() }
    }
}

// MARK: - Stubs

@available(iOS 15.0, *)
private final class StubNetsWebRedirectInteractor: ProcessWebRedirectPaymentInteractor {
    func execute(paymentMethodType: String) async throws -> PaymentResult {
        PaymentResult(paymentId: "nets_payment_123", status: .success)
    }
}

@available(iOS 15.0, *)
private final class StubNetsPaymentMethodMapper: PaymentMethodMapper {
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
