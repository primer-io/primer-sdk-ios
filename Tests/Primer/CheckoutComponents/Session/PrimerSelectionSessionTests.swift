//
//  PrimerSelectionSessionTests.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) @testable import PrimerNetworking
import XCTest
@_spi(PrimerInternal) @testable import PrimerFoundation
@_spi(PrimerInternal) @testable import PrimerCore

@available(iOS 15.0, *)
@MainActor
final class PrimerSelectionSessionTests: XCTestCase {

  private final class StubSelectionScope: PrimerPaymentMethodSelectionScope {
    var continuation: AsyncStream<PrimerPaymentMethodSelectionState>.Continuation?
    private(set) var selectedPaymentMethod: CheckoutPaymentMethod?

    lazy var stateStream: AsyncStream<PrimerPaymentMethodSelectionState> =
      AsyncStream { self.continuation = $0 }
    var state: AsyncStream<PrimerPaymentMethodSelectionState> { stateStream }

    var dismissalMechanism: [DismissalMechanism] = []

    func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod) {
      selectedPaymentMethod = paymentMethod
    }
    func cancel() {}
    func payWithVaultedPaymentMethod() async {}
    func payWithVaultedPaymentMethodAndCvv(_ cvv: String) async {}
    func updateCvvInput(_ cvv: String) {}
    func showAllVaultedPaymentMethods() {}
    func showOtherWaysToPay() {}
  }

  /// Selection scope conforming to `PaymentMethodSelectionScopeInternal`, recording forwarded calls.
  private final class TrackingSelectionScope: PaymentMethodSelectionScopeInternal {
    var continuation: AsyncStream<PrimerPaymentMethodSelectionState>.Continuation?

    private(set) var selectedPaymentMethod: CheckoutPaymentMethod?
    private(set) var cancelCalled = false
    private(set) var showAllCalled = false
    private(set) var selectedVaulted: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
    private(set) var navigatedToDeleteConfirmation: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?

    var stubbedVaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []
    var stubbedCurrentState = PrimerPaymentMethodSelectionState()

    lazy var stateStream: AsyncStream<PrimerPaymentMethodSelectionState> =
      AsyncStream { self.continuation = $0 }
    var state: AsyncStream<PrimerPaymentMethodSelectionState> { stateStream }

    var dismissalMechanism: [DismissalMechanism] = []

    var currentState: PrimerPaymentMethodSelectionState { stubbedCurrentState }

    var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] {
      stubbedVaultedPaymentMethods
    }

    func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod) {
      selectedPaymentMethod = paymentMethod
    }
    func cancel() { cancelCalled = true }
    func payWithVaultedPaymentMethod() async {}
    func payWithVaultedPaymentMethodAndCvv(_ cvv: String) async {}
    func updateCvvInput(_ cvv: String) {}
    func showAllVaultedPaymentMethods() { showAllCalled = true }
    func showOtherWaysToPay() {}

    func syncSelectedVaultedPaymentMethod() {}
    func collapsePaymentMethods() {}
    func selectVaultedPaymentMethod(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) {
      selectedVaulted = method
    }
    func deleteVaultedPaymentMethod(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) async throws {}
    func navigateToDeleteConfirmation(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) {
      navigatedToDeleteConfirmation = method
    }
  }

  private func makeVaultedPaymentMethod(
    id: String = "vault_1"
  ) -> PrimerHeadlessUniversalCheckout.VaultedPaymentMethod {
    let data = try! JSONSerialization.data(withJSONObject: ["last4Digits": "4242"]) // swiftlint:disable:this force_try
    let instrumentData = try! JSONDecoder().decode( // swiftlint:disable:this force_try
      Response.Body.Tokenization.PaymentInstrumentData.self,
      from: data
    )
    return PrimerHeadlessUniversalCheckout.VaultedPaymentMethod(
      id: id,
      paymentMethodType: PrimerPaymentMethodType.paymentCard.rawValue,
      paymentInstrumentType: .paymentCard,
      paymentInstrumentData: instrumentData,
      analyticsId: "analytics_\(id)"
    )
  }

  func test_init_seedsDefaultState() {
    let session = PrimerSelectionSession(scope: StubSelectionScope())
    XCTAssertTrue(session.state.paymentMethods.isEmpty)
  }

  func test_init_seedsStateFromInternalScopeCurrentState() {
    // Given
    let scope = TrackingSelectionScope()
    var seeded = PrimerPaymentMethodSelectionState()
    seeded.paymentMethods = [CheckoutPaymentMethod(id: "pm_1", type: "PAYMENT_CARD", name: "Card")]
    scope.stubbedCurrentState = seeded

    // When
    let session = PrimerSelectionSession(scope: scope)

    // Then
    XCTAssertEqual(session.state.paymentMethods.map(\.id), ["pm_1"])
  }

  func test_stateStream_updatesPublishedState() async throws {
    let scope = StubSelectionScope()
    let session = PrimerSelectionSession(scope: scope)

    // Wait for the session's observation task to start iterating scope.state,
    // which is when the stream's continuation becomes available.
    try await withTimeout(2.0) { [scope] in
      while scope.continuation == nil { await Task.yield() }
    }

    var updated = PrimerPaymentMethodSelectionState()
    updated.isLoading = true
    scope.continuation?.yield(updated)

    try await withTimeout(2.0) { [session] in
      while !session.state.isLoading { await Task.yield() }
    }
    XCTAssertTrue(session.state.isLoading)
  }

  func test_vaultedPaymentMethods_emptyWhenScopeNotInternal() {
    // A non-`PaymentMethodSelectionScopeInternal` scope yields no vaulted methods.
    let session = PrimerSelectionSession(scope: StubSelectionScope())
    XCTAssertTrue(session.vaultedPaymentMethods.isEmpty)
  }

  // MARK: - Selection forwarding

  func test_select_forwardsToOnPaymentMethodSelected() {
    // Given
    let scope = TrackingSelectionScope()
    let session = PrimerSelectionSession(scope: scope)
    let method = CheckoutPaymentMethod(id: "pm_1", type: "PAYMENT_CARD", name: "Card")

    // When
    session.select(method)

    // Then
    XCTAssertEqual(scope.selectedPaymentMethod, method)
  }

  func test_cancel_forwardsToScope() {
    // Given
    let scope = TrackingSelectionScope()

    // When
    PrimerSelectionSession(scope: scope).cancel()

    // Then
    XCTAssertTrue(scope.cancelCalled)
  }

  // MARK: - Vaulted forwarding

  func test_selectVaulted_forwardsToSelectVaultedPaymentMethod() {
    // Given
    let scope = TrackingSelectionScope()
    let session = PrimerSelectionSession(scope: scope)
    let method = makeVaultedPaymentMethod(id: "v1")

    // When
    session.selectVaulted(method)

    // Then
    XCTAssertEqual(scope.selectedVaulted?.id, "v1")
  }

  func test_delete_forwardsToNavigateToDeleteConfirmation() {
    // Given
    let scope = TrackingSelectionScope()
    let session = PrimerSelectionSession(scope: scope)
    let method = makeVaultedPaymentMethod(id: "v2")

    // When
    session.delete(method)

    // Then
    XCTAssertEqual(scope.navigatedToDeleteConfirmation?.id, "v2")
  }

  func test_showAll_forwardsToShowAllVaultedPaymentMethods() {
    // Given
    let scope = TrackingSelectionScope()

    // When
    PrimerSelectionSession(scope: scope).showAll()

    // Then
    XCTAssertTrue(scope.showAllCalled)
  }

  func test_vaultedPaymentMethods_readsFromInternalScope() {
    // Given
    let scope = TrackingSelectionScope()
    scope.stubbedVaultedPaymentMethods = [makeVaultedPaymentMethod(id: "v1"), makeVaultedPaymentMethod(id: "v2")]
    let session = PrimerSelectionSession(scope: scope)

    // Then
    XCTAssertEqual(session.vaultedPaymentMethods.map(\.id), ["v1", "v2"])
  }
}
