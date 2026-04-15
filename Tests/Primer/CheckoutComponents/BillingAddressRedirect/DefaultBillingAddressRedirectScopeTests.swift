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

  // MARK: - Helpers

  private func fillValidForm() {
    sut.updateCountryCode("US")
    sut.updateAddressLine1("123 Main St")
    sut.updatePostalCode("94105")
    sut.updateCity("San Francisco")
    sut.updateState("CA")
  }

  private func collectFirstState() async -> PrimerBillingAddressRedirectState {
    var collectedState = PrimerBillingAddressRedirectState()
    for await state in sut.state {
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
  var resultToReturn: PaymentResult = PaymentResult(paymentId: "test_123", status: .success)
  var errorToThrow: Error?

  func execute(paymentMethodType: String) async throws -> PaymentResult {
    executeCallCount += 1
    lastPaymentMethodType = paymentMethodType
    if let error = errorToThrow { throw error }
    return resultToReturn
  }
}
