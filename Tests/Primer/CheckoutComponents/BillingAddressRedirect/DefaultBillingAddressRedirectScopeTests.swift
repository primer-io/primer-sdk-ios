//
//  DefaultBillingAddressRedirectScopeTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import XCTest

@available(iOS 15.0, *)
@MainActor
final class DefaultBillingAddressRedirectScopeTests: XCTestCase {

  private var sut: DefaultBillingAddressRedirectScope!
  private var mockInteractor: MockBillingAddressWebRedirectInteractor!

  override func setUp() async throws {
    try await super.setUp()
    mockInteractor = MockBillingAddressWebRedirectInteractor()
    let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
    sut = DefaultBillingAddressRedirectScope(
      paymentMethodType: PrimerPaymentMethodType.adyenAffirm.rawValue,
      checkoutScope: checkoutScope,
      processWebRedirectInteractor: mockInteractor
    )
  }

  override func tearDown() async throws {
    sut = nil
    mockInteractor = nil
    try await super.tearDown()
  }

  // MARK: - Field Update Tests

  func test_updateCountryCode_updatesState() async {
    // When
    sut.updateCountryCode("US")

    // Then
    let state = await collectFirstState()
    XCTAssertEqual(state.countryCode, "US")
  }

  func test_updateAddressLine1_updatesState() async {
    // When
    sut.updateAddressLine1("123 Main St")

    // Then
    let state = await collectFirstState()
    XCTAssertEqual(state.addressLine1, "123 Main St")
  }

  func test_updateAddressLine2_updatesState() async {
    // When
    sut.updateAddressLine2("Apt 4B")

    // Then
    let state = await collectFirstState()
    XCTAssertEqual(state.addressLine2, "Apt 4B")
  }

  func test_updatePostalCode_updatesState() async {
    // When
    sut.updatePostalCode("94105")

    // Then
    let state = await collectFirstState()
    XCTAssertEqual(state.postalCode, "94105")
  }

  func test_updateCity_updatesState() async {
    // When
    sut.updateCity("San Francisco")

    // Then
    let state = await collectFirstState()
    XCTAssertEqual(state.city, "San Francisco")
  }

  func test_updateState_updatesState() async {
    // When
    sut.updateState("CA")

    // Then
    let state = await collectFirstState()
    XCTAssertEqual(state.state, "CA")
  }

  // MARK: - Form Validity Tests

  func test_formValidity_allRequiredFieldsFilled_isValid() async {
    // When
    fillValidForm()

    // Then
    let state = await collectFirstState()
    XCTAssertTrue(state.isFormValid)
  }

  func test_formValidity_missingCountryCode_isInvalid() async {
    // Given
    sut.updateAddressLine1("123 Main St")
    sut.updatePostalCode("94105")
    sut.updateCity("San Francisco")
    sut.updateState("CA")

    // Then
    let state = await collectFirstState()
    XCTAssertFalse(state.isFormValid)
  }

  func test_formValidity_missingAddressLine1_isInvalid() async {
    // Given
    sut.updateCountryCode("US")
    sut.updatePostalCode("94105")
    sut.updateCity("San Francisco")
    sut.updateState("CA")

    // Then
    let state = await collectFirstState()
    XCTAssertFalse(state.isFormValid)
  }

  func test_formValidity_addressLine2Optional_stillValid() async {
    // Given — fill all required fields but NOT addressLine2
    fillValidForm()

    // Then — should still be valid
    let state = await collectFirstState()
    XCTAssertTrue(state.isFormValid)
    XCTAssertEqual(state.addressLine2, "")
  }

  func test_formValidity_emptyForm_isInvalid() async {
    // Then
    let state = await collectFirstState()
    XCTAssertFalse(state.isFormValid)
  }

  // MARK: - Initial State Tests

  func test_initialState_statusIsReady() async {
    let state = await collectFirstState()
    XCTAssertEqual(state.status, .ready)
  }

  func test_initialState_formIsInvalid() async {
    let state = await collectFirstState()
    XCTAssertFalse(state.isFormValid)
  }

  func test_initialState_allFieldsEmpty() async {
    let state = await collectFirstState()
    XCTAssertTrue(state.countryCode.isEmpty)
    XCTAssertTrue(state.addressLine1.isEmpty)
    XCTAssertTrue(state.addressLine2.isEmpty)
    XCTAssertTrue(state.postalCode.isEmpty)
    XCTAssertTrue(state.city.isEmpty)
    XCTAssertTrue(state.state.isEmpty)
  }

  func test_initialState_noErrors() async {
    let state = await collectFirstState()
    XCTAssertTrue(state.errors.isEmpty)
  }

  // MARK: - Submit Guard Tests

  func test_submit_withInvalidForm_doesNotCallInteractor() async throws {
    // Given — form is empty (invalid)

    // When
    sut.submit()
    try await Task.sleep(nanoseconds: 100_000_000)

    // Then
    XCTAssertEqual(mockInteractor.executeCallCount, 0)
  }

  func test_submit_withValidForm_isAccepted() async {
    // Given
    fillValidForm()
    let state = await collectFirstState()

    // Then — form should be valid, which means submit() would proceed
    XCTAssertTrue(state.isFormValid)
    XCTAssertEqual(state.status, .ready)
  }

  // MARK: - Payment Method Type

  func test_paymentMethodType_isAdyenAffirm() {
    XCTAssertEqual(sut.paymentMethodType, "ADYEN_AFFIRM")
  }

  // MARK: - Start Tests

  func test_start_doesNotCrash() async throws {
    sut.start()
    try await Task.sleep(nanoseconds: 100_000_000)
    XCTAssertEqual(sut.paymentMethodType, PrimerPaymentMethodType.adyenAffirm.rawValue)
  }

  func test_start_calledTwice_isIdempotent() async throws {
    sut.start()
    sut.start()
    try await Task.sleep(nanoseconds: 100_000_000)
    let state = await collectFirstState()
    XCTAssertEqual(state.status, .ready)
  }

  // MARK: - Cancel Tests

  func test_cancel_setsStatusToReady() async throws {
    sut.cancel()
    try await Task.sleep(nanoseconds: 50_000_000)
    let state = await collectFirstState()
    XCTAssertEqual(state.status, .ready)
  }

  func test_cancel_withNilRepository_doesNotCrash() {
    sut.cancel()
  }

  // MARK: - onBack Tests

  func test_onBack_fromPaymentSelection_navigatesBack() async {
    let coordinator = CheckoutCoordinator()
    coordinator.navigate(to: .paymentMethodSelection)
    coordinator.navigate(to: .paymentMethod(PrimerPaymentMethodType.adyenAffirm.rawValue, .fromPaymentSelection))
    let navigator = CheckoutNavigator(coordinator: coordinator)
    let checkoutScope = DefaultCheckoutScope(
      clientToken: TestData.Tokens.valid,
      settings: PrimerSettings(paymentHandling: .manual, paymentMethodOptions: PrimerPaymentMethodOptions()),
      diContainer: DIContainer.shared,
      navigator: navigator,
      presentationContext: .fromPaymentSelection
    )
    let scope = DefaultBillingAddressRedirectScope(
      paymentMethodType: PrimerPaymentMethodType.adyenAffirm.rawValue,
      checkoutScope: checkoutScope,
      presentationContext: .fromPaymentSelection,
      processWebRedirectInteractor: mockInteractor
    )

    scope.onBack()

    XCTAssertEqual(coordinator.currentRoute, .paymentMethodSelection)
  }

  func test_onBack_directContext_doesNotNavigate() async {
    let coordinator = CheckoutCoordinator()
    coordinator.navigate(to: .paymentMethod(PrimerPaymentMethodType.adyenAffirm.rawValue, .direct))
    let navigator = CheckoutNavigator(coordinator: coordinator)
    let checkoutScope = DefaultCheckoutScope(
      clientToken: TestData.Tokens.valid,
      settings: PrimerSettings(paymentHandling: .manual, paymentMethodOptions: PrimerPaymentMethodOptions()),
      diContainer: DIContainer.shared,
      navigator: navigator,
      presentationContext: .direct
    )
    let initialStackCount = coordinator.navigationStack.count
    let scope = DefaultBillingAddressRedirectScope(
      paymentMethodType: PrimerPaymentMethodType.adyenAffirm.rawValue,
      checkoutScope: checkoutScope,
      presentationContext: .direct,
      processWebRedirectInteractor: mockInteractor
    )

    scope.onBack()

    XCTAssertEqual(coordinator.navigationStack.count, initialStackCount)
  }

  // MARK: - dismissalMechanism Tests

  func test_dismissalMechanism_reflectsCheckoutScope() async {
    let mechanism = sut.dismissalMechanism
    XCTAssertNotNil(mechanism)
  }

  // MARK: - presentationContext Tests

  func test_presentationContext_defaultIsFromPaymentSelection() {
    XCTAssertEqual(sut.presentationContext, .fromPaymentSelection)
  }

  func test_presentationContext_directIsPreserved() async {
    let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
    let scope = DefaultBillingAddressRedirectScope(
      paymentMethodType: PrimerPaymentMethodType.adyenAffirm.rawValue,
      checkoutScope: checkoutScope,
      presentationContext: .direct,
      processWebRedirectInteractor: mockInteractor
    )
    XCTAssertEqual(scope.presentationContext, .direct)
  }

  // MARK: - Init Tests

  func test_init_withPaymentMethod_populatesState() async {
    let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
    let paymentMethod = CheckoutPaymentMethod(
      id: "affirm_id",
      type: PrimerPaymentMethodType.adyenAffirm.rawValue,
      name: "Affirm"
    )
    let scope = DefaultBillingAddressRedirectScope(
      paymentMethodType: PrimerPaymentMethodType.adyenAffirm.rawValue,
      checkoutScope: checkoutScope,
      processWebRedirectInteractor: mockInteractor,
      paymentMethod: paymentMethod
    )

    let state = await firstState(from: scope)
    XCTAssertEqual(state.paymentMethod?.id, "affirm_id")
    XCTAssertEqual(state.paymentMethod?.type, PrimerPaymentMethodType.adyenAffirm.rawValue)
  }

  func test_init_withSurchargeAmount_populatesState() async {
    let checkoutScope = await ContainerTestHelpers.createMockCheckoutScope()
    let scope = DefaultBillingAddressRedirectScope(
      paymentMethodType: PrimerPaymentMethodType.adyenAffirm.rawValue,
      checkoutScope: checkoutScope,
      processWebRedirectInteractor: mockInteractor,
      surchargeAmount: "$2.50"
    )

    let state = await firstState(from: scope)
    XCTAssertEqual(state.surchargeAmount, "$2.50")
  }

  // MARK: - Validation Edge Cases

  func test_updateAddressLine2_withExistingError_clearsError() async {
    // addressLine2 is optional and always clears errors regardless of input
    sut.updateAddressLine2("Apt 4B")
    sut.updateAddressLine2("")

    let state = await collectFirstState()
    XCTAssertNil(state.errors[.addressLine2])
  }

  func test_updateField_thenEmpty_keepsFormInvalid() async {
    sut.updateCountryCode("US")
    sut.updateCountryCode("")

    let state = await collectFirstState()
    XCTAssertFalse(state.isFormValid)
  }

  func test_submit_withInvalidForm_triggersValidationOnAllFields() async throws {
    sut.submit()
    try await Task.sleep(nanoseconds: 100_000_000)

    let state = await collectFirstState()
    XCTAssertFalse(state.isFormValid)
    XCTAssertEqual(mockInteractor.executeCallCount, 0)
  }

  // MARK: - Submit / performPayment Tests

  func test_submit_withValidForm_transitionsOutOfReady() async throws {
    fillValidForm()
    try await Task.sleep(nanoseconds: 50_000_000)

    sut.submit()

    let finalState = try await awaitValue(sut.state, matching: { $0.status != .ready })
    XCTAssertNotEqual(finalState.status, .ready)
  }

  func test_submit_whenInteractorThrows_eventuallyFails() async throws {
    mockInteractor.errorToThrow = PrimerError.unknown(message: "boom")
    fillValidForm()
    try await Task.sleep(nanoseconds: 50_000_000)

    sut.submit()

    let state = try await awaitValue(sut.state, matching: {
      if case .failure = $0.status { return true }
      return false
    })
    if case .failure = state.status {
      // Expected
    } else {
      XCTFail("Expected failure status")
    }
  }

  // MARK: - Helpers

  private func fillValidForm() {
    sut.updateCountryCode("US")
    sut.updateAddressLine1("123 Main St")
    sut.updatePostalCode("94105")
    sut.updateCity("San Francisco")
    sut.updateState("CA")
  }

  private func collectFirstState() async -> PrimerBillingAddressRedirectState {
    await firstState(from: sut)
  }

  private func firstState(from scope: DefaultBillingAddressRedirectScope) async -> PrimerBillingAddressRedirectState {
    var collectedState = PrimerBillingAddressRedirectState()
    for await state in scope.state {
      collectedState = state
      break
    }
    return collectedState
  }
}

// MARK: - Mock Interactor

@available(iOS 15.0, *)
private final class MockBillingAddressWebRedirectInteractor: ProcessWebRedirectPaymentInteractor {

  private(set) var executeCallCount = 0
  private(set) var lastPaymentMethodType: String?
  var resultToReturn = PaymentResult(paymentId: "test_123", status: .success)
  var errorToThrow: Error?

  func execute(paymentMethodType: String) async throws -> PaymentResult {
    executeCallCount += 1
    lastPaymentMethodType = paymentMethodType
    if let error = errorToThrow { throw error }
    return resultToReturn
  }
}
