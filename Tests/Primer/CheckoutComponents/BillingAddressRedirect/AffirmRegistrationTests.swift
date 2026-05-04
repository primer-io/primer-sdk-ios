//
//  AffirmRegistrationTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class AffirmRegistrationTests: XCTestCase {

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

  func test_adyenAffirm_rawValue() {
    XCTAssertEqual(PrimerPaymentMethodType.adyenAffirm.rawValue, "ADYEN_AFFIRM")
  }

  func test_adyenAffirm_provider() {
    XCTAssertEqual(PrimerPaymentMethodType.adyenAffirm.provider, "ADYEN")
  }

  func test_adyenAffirm_decodable() throws {
    let data = Data("\"ADYEN_AFFIRM\"".utf8)
    let decoded = try JSONDecoder().decode(PrimerPaymentMethodType.self, from: data)
    XCTAssertEqual(decoded, .adyenAffirm)
  }

  func test_adyenAffirm_encodable() throws {
    let encoded = try JSONEncoder().encode(PrimerPaymentMethodType.adyenAffirm)
    let string = String(data: encoded, encoding: .utf8)
    XCTAssertEqual(string, "\"ADYEN_AFFIRM\"")
  }

  func test_adyenAffirm_includedInAllCases() {
    XCTAssertTrue(PrimerPaymentMethodType.allCases.contains(.adyenAffirm))
  }

  // MARK: - Registration Tests

  func test_affirm_registeredAsBillingAddressRedirect() {
    // Given
    BillingAddressRedirectPaymentMethod.register()

    // Then
    let registered = PaymentMethodRegistry.shared.registeredTypes
    XCTAssertTrue(registered.contains(PrimerPaymentMethodType.adyenAffirm.rawValue))
  }

  func test_affirm_createScope_returnsDefaultBillingAddressRedirectScope() async throws {
    // Given
    await registerDependencies()
    BillingAddressRedirectPaymentMethod.register()
    let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

    // When
    let scope = try await PaymentMethodRegistry.shared.createScope(
      for: PrimerPaymentMethodType.adyenAffirm.rawValue,
      checkoutScope: checkoutScope,
      diContainer: container
    )

    // Then
    XCTAssertTrue(scope is DefaultBillingAddressRedirectScope)
  }

  func test_affirm_createScope_setsCorrectPaymentMethodType() async throws {
    // Given
    await registerDependencies()
    BillingAddressRedirectPaymentMethod.register()
    let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

    // When
    let scope = try await PaymentMethodRegistry.shared.createScope(
      for: PrimerPaymentMethodType.adyenAffirm.rawValue,
      checkoutScope: checkoutScope,
      diContainer: container
    )

    // Then
    let billingScope = try XCTUnwrap(scope as? DefaultBillingAddressRedirectScope)
    XCTAssertEqual(billingScope.paymentMethodType, PrimerPaymentMethodType.adyenAffirm.rawValue)
  }

  func test_affirm_createScope_withMissingDependencies_throws() async throws {
    // Given
    BillingAddressRedirectPaymentMethod.register()
    let emptyContainer = Container()
    let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()

    // When/Then
    do {
      _ = try await PaymentMethodRegistry.shared.createScope(
        for: PrimerPaymentMethodType.adyenAffirm.rawValue,
        checkoutScope: checkoutScope,
        diContainer: emptyContainer
      )
      XCTFail("Expected error when required dependency is missing")
    } catch {
      XCTAssertTrue(error is ContainerError || error is PrimerError)
    }
  }

  // MARK: - Helpers

  private func registerDependencies() async {
    _ = try? await container.register(ProcessWebRedirectPaymentInteractor.self)
      .asSingleton()
      .with { _ in StubAffirmWebRedirectInteractor() }

    _ = try? await container.register(PaymentMethodMapper.self)
      .asSingleton()
      .with { _ in StubAffirmPaymentMethodMapper() }

    _ = try? await container.register(WebRedirectRepository.self)
      .asSingleton()
      .with { _ in MockWebRedirectRepository() }
  }
}

// MARK: - Stubs

@available(iOS 15.0, *)
private final class StubAffirmWebRedirectInteractor: ProcessWebRedirectPaymentInteractor {
  func execute(paymentMethodType: String) async throws -> PaymentResult {
    PaymentResult(paymentId: "affirm_payment_123", status: .success)
  }
}

@available(iOS 15.0, *)
private final class StubAffirmPaymentMethodMapper: PaymentMethodMapper {
  func mapToPublic(_ internalMethod: InternalPaymentMethod) -> CheckoutPaymentMethod {
    CheckoutPaymentMethod(id: internalMethod.id, type: internalMethod.type, name: internalMethod.name)
  }

  func mapToPublic(_ internalMethods: [InternalPaymentMethod]) -> [CheckoutPaymentMethod] {
    internalMethods.map { mapToPublic($0) }
  }
}
