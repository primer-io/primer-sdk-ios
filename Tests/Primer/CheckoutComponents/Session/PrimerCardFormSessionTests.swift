//
//  PrimerCardFormSessionTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
import SwiftUI
import XCTest
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class PrimerCardFormSessionTests: XCTestCase {

  // MARK: - Test Double

  /// Minimal card-form scope whose state stream is driven by the test via `continuation`.
  private final class StubCardFormScope: PrimerCardFormScope {
    typealias State = PrimerCardFormState

    var continuation: AsyncStream<PrimerCardFormState>.Continuation?
    private(set) var startCalled = false

    lazy var stateStream: AsyncStream<PrimerCardFormState> = AsyncStream { self.continuation = $0 }
    var state: AsyncStream<PrimerCardFormState> { stateStream }

    var cardFormUIOptions: PrimerCardFormUIOptions?

    func start() { startCalled = true }
    func submit() {}
    func cancel() {}

    func updateCardNumber(_ value: String) {}
    func updateCvv(_ value: String) {}
    func updateExpiryDate(_ value: String) {}
    func updateCardholderName(_ value: String) {}
    func updatePostalCode(_ value: String) {}
    func updateCity(_ value: String) {}
    func updateState(_ value: String) {}
    func updateAddressLine1(_ value: String) {}
    func updateAddressLine2(_ value: String) {}
    func updatePhoneNumber(_ value: String) {}
    func updateFirstName(_ value: String) {}
    func updateLastName(_ value: String) {}
    func updateRetailOutlet(_ value: String) {}
    func updateOtpCode(_ value: String) {}
    func updateEmail(_ value: String) {}
    func updateExpiryMonth(_ value: String) {}
    func updateExpiryYear(_ value: String) {}
    func updateSelectedCardNetwork(_ value: String) {}
    func updateCountryCode(_ value: String) {}
  }

  /// Card-form scope that also conforms to `CardFormFieldScopeInternal`, recording every forwarded
  /// call so the session's pass-through behavior can be asserted.
  private final class TrackingFieldScope: CardFormFieldScopeInternal {
    var continuation: AsyncStream<PrimerCardFormState>.Continuation?
    private(set) var startCalled = false
    private(set) var submitCalled = false
    private(set) var cancelCalled = false

    private(set) var lastCardNumber: String?
    private(set) var lastCvv: String?
    private(set) var lastExpiryDate: String?
    private(set) var lastCardholderName: String?
    private(set) var lastPostalCode: String?
    private(set) var lastCountryCode: String?
    private(set) var lastCity: String?
    private(set) var lastState: String?
    private(set) var lastAddressLine1: String?
    private(set) var lastAddressLine2: String?
    private(set) var lastPhoneNumber: String?
    private(set) var lastFirstName: String?
    private(set) var lastLastName: String?
    private(set) var lastSelectedCardNetwork: String?

    var seededState = PrimerCardFormState()

    lazy var stateStream: AsyncStream<PrimerCardFormState> = AsyncStream { self.continuation = $0 }
    var state: AsyncStream<PrimerCardFormState> { stateStream }

    var cardFormUIOptions: PrimerCardFormUIOptions?

    var currentState: PrimerCardFormState { seededState }
    var selectCountry: PrimerSelectCountryScope { fatalError("Not needed for these tests") }

    func start() { startCalled = true }
    func submit() { submitCalled = true }
    func cancel() { cancelCalled = true }

    func updateCardNumber(_ value: String) { lastCardNumber = value }
    func updateCvv(_ value: String) { lastCvv = value }
    func updateExpiryDate(_ value: String) { lastExpiryDate = value }
    func updateCardholderName(_ value: String) { lastCardholderName = value }
    func updatePostalCode(_ value: String) { lastPostalCode = value }
    func updateCountryCode(_ value: String) { lastCountryCode = value }
    func updateCity(_ value: String) { lastCity = value }
    func updateState(_ value: String) { lastState = value }
    func updateAddressLine1(_ value: String) { lastAddressLine1 = value }
    func updateAddressLine2(_ value: String) { lastAddressLine2 = value }
    func updatePhoneNumber(_ value: String) { lastPhoneNumber = value }
    func updateFirstName(_ value: String) { lastFirstName = value }
    func updateLastName(_ value: String) { lastLastName = value }
    func updateSelectedCardNetwork(_ value: String) { lastSelectedCardNetwork = value }
    func autoSelectDetectedNetwork(_ value: String) {}
    func updateRetailOutlet(_ value: String) {}
    func updateOtpCode(_ value: String) {}
    func updateEmail(_ value: String) {}
    func updateExpiryMonth(_ value: String) {}
    func updateExpiryYear(_ value: String) {}

    func updateValidationState(_ keyPath: WritableKeyPath<FieldValidationStates, Bool>, isValid: Bool) {}
    func updateValidationStateIfNeeded(for field: PrimerInputElementType, isValid: Bool) {}
    func performSubmit() async {}
  }

  // MARK: - Tests

  func test_init_startsScope_andExposesIt() {
    // Given
    let scope = StubCardFormScope()

    // When
    let session = PrimerCardFormSession(scope: scope)

    // Then
    XCTAssertTrue(scope.startCalled, "Session should start the underlying scope")
    XCTAssertTrue(session.scope is StubCardFormScope, "Session should expose the provided scope")
  }

  func test_init_seedsDefaultState_whenScopeIsNotInternal() {
    // Given a scope that is not CardFormFieldScopeInternal
    let session = PrimerCardFormSession(scope: StubCardFormScope())

    // Then the seed falls back to a default state
    XCTAssertEqual(session.state, PrimerCardFormState())
  }

  func test_stateStream_updatesPublishedState() async throws {
    // Given
    let scope = StubCardFormScope()
    let session = PrimerCardFormSession(scope: scope)

    // Wait until the session's observation task has subscribed (continuation set).
    try await withTimeout(2.0) {
      while scope.continuation == nil { await Task.yield() }
    }

    // When the scope emits a new state
    var updated = PrimerCardFormState()
    updated.isLoading = true
    scope.continuation?.yield(updated)

    // Then the published state reflects it
    try await withTimeout(2.0) {
      while !session.state.isLoading { await Task.yield() }
    }
    XCTAssertTrue(session.state.isLoading, "Published state should reflect the scope's latest emission")
  }

  // MARK: - Seeded state

  func test_init_seedsStateFromCurrentState_whenScopeIsInternal() {
    // Given a field scope exposing a non-default current state
    let scope = TrackingFieldScope()
    scope.seededState.isLoading = true

    // When
    let session = PrimerCardFormSession(scope: scope)

    // Then the session seeds its published state from the scope's current state
    XCTAssertTrue(session.state.isLoading)
  }

  // MARK: - Field forwarding

  func test_updateCardNumber_forwardsValueToFieldScope() {
    // Given
    let scope = TrackingFieldScope()
    let session = PrimerCardFormSession(scope: scope)

    // When
    session.updateCardNumber("4111111111111111")

    // Then
    XCTAssertEqual(scope.lastCardNumber, "4111111111111111")
  }

  func test_updateCvv_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updateCvv("123")
    XCTAssertEqual(scope.lastCvv, "123")
  }

  func test_updateExpiryDate_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updateExpiryDate("12/29")
    XCTAssertEqual(scope.lastExpiryDate, "12/29")
  }

  func test_updateCardholderName_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updateCardholderName("Jane Doe")
    XCTAssertEqual(scope.lastCardholderName, "Jane Doe")
  }

  func test_updatePostalCode_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updatePostalCode("EC1A 1BB")
    XCTAssertEqual(scope.lastPostalCode, "EC1A 1BB")
  }

  func test_updateCountryCode_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updateCountryCode("GB")
    XCTAssertEqual(scope.lastCountryCode, "GB")
  }

  func test_updateCity_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updateCity("London")
    XCTAssertEqual(scope.lastCity, "London")
  }

  func test_updateState_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updateState("Greater London")
    XCTAssertEqual(scope.lastState, "Greater London")
  }

  func test_updateAddressLine1_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updateAddressLine1("1 Test Street")
    XCTAssertEqual(scope.lastAddressLine1, "1 Test Street")
  }

  func test_updateAddressLine2_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updateAddressLine2("Flat 2")
    XCTAssertEqual(scope.lastAddressLine2, "Flat 2")
  }

  func test_updatePhoneNumber_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updatePhoneNumber("+447700900000")
    XCTAssertEqual(scope.lastPhoneNumber, "+447700900000")
  }

  func test_updateFirstName_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updateFirstName("Jane")
    XCTAssertEqual(scope.lastFirstName, "Jane")
  }

  func test_updateLastName_forwardsValueToFieldScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).updateLastName("Doe")
    XCTAssertEqual(scope.lastLastName, "Doe")
  }

  func test_selectCardNetwork_forwardsNetworkRawValueToFieldScope() {
    // Given
    let scope = TrackingFieldScope()
    let session = PrimerCardFormSession(scope: scope)

    // When
    session.selectCardNetwork(PrimerCardNetwork(network: .visa))

    // Then the underlying network's rawValue is forwarded.
    XCTAssertEqual(scope.lastSelectedCardNetwork, CardNetwork.visa.rawValue)
  }

  // MARK: - Lifecycle forwarding

  func test_submit_forwardsToScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).submit()
    XCTAssertTrue(scope.submitCalled)
  }

  func test_cancel_forwardsToScope() {
    let scope = TrackingFieldScope()
    PrimerCardFormSession(scope: scope).cancel()
    XCTAssertTrue(scope.cancelCalled)
  }

  func test_fieldUpdates_areNoOp_whenScopeIsNotInternal() {
    // Given a scope that is not CardFormFieldScopeInternal — calls must not crash.
    let session = PrimerCardFormSession(scope: StubCardFormScope())

    // When / Then — no observable effect, but must be safe to call.
    session.updateCardNumber("4111111111111111")
    session.selectCardNetwork(PrimerCardNetwork(network: .visa))
    XCTAssertEqual(session.state, PrimerCardFormState())
  }
}
