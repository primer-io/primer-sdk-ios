//
//  MockSelectionScopeInternal.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@testable import PrimerSDK
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Selection scope conforming to `PaymentMethodSelectionScopeInternal`, recording forwarded calls and
/// letting tests seed the current state and vaulted methods used to render the selection views.
@available(iOS 15.0, *)
@MainActor
final class MockSelectionScopeInternal: PaymentMethodSelectionScopeInternal {

  var stubbedCurrentState = PrimerPaymentMethodSelectionState()
  var stubbedVaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] = []

  private(set) var selectedPaymentMethod: CheckoutPaymentMethod?
  private(set) var cancelCalled = false
  private(set) var showAllCalled = false
  private(set) var showOtherWaysCalled = false
  private(set) var updatedCvv: String?
  private(set) var paidWithVaulted = false
  private(set) var paidWithVaultedAndCvv: String?
  private(set) var selectedVaulted: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
  private(set) var deletedVaulted: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?
  private(set) var navigatedToDeleteConfirmation: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?

  var continuation: AsyncStream<PrimerPaymentMethodSelectionState>.Continuation?
  lazy var stateStream: AsyncStream<PrimerPaymentMethodSelectionState> =
    AsyncStream { self.continuation = $0 }
  var state: AsyncStream<PrimerPaymentMethodSelectionState> { stateStream }

  var dismissalMechanism: [DismissalMechanism] = []

  var currentState: PrimerPaymentMethodSelectionState { stubbedCurrentState }
  var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] { stubbedVaultedPaymentMethods }

  func onPaymentMethodSelected(paymentMethod: CheckoutPaymentMethod) { selectedPaymentMethod = paymentMethod }
  func cancel() { cancelCalled = true }
  func payWithVaultedPaymentMethod() async { paidWithVaulted = true }
  func payWithVaultedPaymentMethodAndCvv(_ cvv: String) async { paidWithVaultedAndCvv = cvv }
  func updateCvvInput(_ cvv: String) { updatedCvv = cvv }
  func showAllVaultedPaymentMethods() { showAllCalled = true }
  func showOtherWaysToPay() { showOtherWaysCalled = true }
  func syncSelectedVaultedPaymentMethod() {}
  func collapsePaymentMethods() {}
  func selectVaultedPaymentMethod(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) {
    selectedVaulted = method
  }
  func deleteVaultedPaymentMethod(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) async throws {
    deletedVaulted = method
  }
  func navigateToDeleteConfirmation(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) {
    navigatedToDeleteConfirmation = method
  }
}
