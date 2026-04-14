//
//  BancontactPayconiqRegistrationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class BancontactPayconiqRegistrationTests: XCTestCase {

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

    func test_adyenBancontactPayconiq_rawValue() {
        XCTAssertEqual(PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue, "ADYEN_BANCONTACT_PAYCONIQ")
    }

    func test_adyenBancontactPayconiq_provider() {
        XCTAssertEqual(PrimerPaymentMethodType.adyenBancontactPayconiq.provider, "ADYEN")
    }

    func test_adyenBancontactPayconiq_decodable() throws {
        let data = Data("\"ADYEN_BANCONTACT_PAYCONIQ\"".utf8)
        let decoded = try JSONDecoder().decode(PrimerPaymentMethodType.self, from: data)
        XCTAssertEqual(decoded, .adyenBancontactPayconiq)
    }

    func test_adyenBancontactPayconiq_encodable() throws {
        let encoded = try JSONEncoder().encode(PrimerPaymentMethodType.adyenBancontactPayconiq)
        let string = String(data: encoded, encoding: .utf8)
        XCTAssertEqual(string, "\"ADYEN_BANCONTACT_PAYCONIQ\"")
    }

    func test_adyenBancontactPayconiq_includedInAllCases() {
        XCTAssertTrue(PrimerPaymentMethodType.allCases.contains(.adyenBancontactPayconiq))
    }

    // MARK: - WebRedirect Registration Tests

    func test_bancontactPayconiq_registeredAsWebRedirect() {
        // Given
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue])

        // Then
        let registered = PaymentMethodRegistry.shared.registeredTypes
        XCTAssertTrue(registered.contains(PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue))
    }

    func test_bancontactPayconiq_notRegistered_whenNotIncluded() {
        // Given
        WebRedirectPaymentMethod.register(types: ["ADYEN_TWINT"])

        // Then
        let registered = PaymentMethodRegistry.shared.registeredTypes
        XCTAssertFalse(registered.contains(PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue))
    }

    func test_bancontactPayconiq_createScope_returnsDefaultWebRedirectScope() async throws {
        // Given
        await registerWebRedirectDependencies()
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue])
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        XCTAssertTrue(scope is DefaultWebRedirectScope)
    }

    func test_bancontactPayconiq_createScope_setsCorrectPaymentMethodType() async throws {
        // Given
        await registerWebRedirectDependencies()
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue])
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When
        let scope = try await PaymentMethodRegistry.shared.createScope(
            for: PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue,
            checkoutScope: checkoutScope,
            diContainer: container
        )

        // Then
        let webRedirectScope = try XCTUnwrap(scope as? DefaultWebRedirectScope)
        XCTAssertEqual(webRedirectScope.paymentMethodType, PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue)
    }

    func test_bancontactPayconiq_createScope_withMissingDependencies_throws() async throws {
        // Given
        WebRedirectPaymentMethod.register(types: [PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue])
        let emptyContainer = Container()
        let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

        // When/Then
        do {
            _ = try await PaymentMethodRegistry.shared.createScope(
                for: PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue,
                checkoutScope: checkoutScope,
                diContainer: emptyContainer
            )
            XCTFail("Expected error when required dependency is missing")
        } catch {
            XCTAssertTrue(error is ContainerError || error is PrimerError)
        }
    }

    func test_bancontactPayconiq_registeredAlongsideOtherWebRedirectTypes() {
        // Given
        let types = [
            "ADYEN_TWINT",
            PrimerPaymentMethodType.adyenBancontactPayconiq.rawValue,
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
            .with { _ in StubBancontactPayconiqWebRedirectInteractor() }

        _ = try? await container.register(PaymentMethodMapper.self)
            .asSingleton()
            .with { _ in StubBancontactPayconiqPaymentMethodMapper() }

        _ = try? await container.register(WebRedirectRepository.self)
            .asSingleton()
            .with { _ in MockWebRedirectRepository() }
    }
}

// MARK: - Stubs

@available(iOS 15.0, *)
private final class StubBancontactPayconiqWebRedirectInteractor: ProcessWebRedirectPaymentInteractor {
    func execute(paymentMethodType: String) async throws -> PaymentResult {
        PaymentResult(paymentId: "bancontact_payconiq_payment_123", status: .success)
    }
}

@available(iOS 15.0, *)
private final class StubBancontactPayconiqPaymentMethodMapper: PaymentMethodMapper {
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
