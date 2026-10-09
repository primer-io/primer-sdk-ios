//
//  CheckoutScopeInternal.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

@available(iOS 15.0, *)
@MainActor
protocol CheckoutScopeInternal: PrimerCheckoutScope {
  var paymentMethodSelectionInternal: any PaymentMethodSelectionScopeInternal { get }
  var checkoutNavigator: CheckoutNavigator { get }

  var navigationStateStream: AsyncStream<CheckoutNavigationState> { get }
  /// True while the merchant's `onBeforePaymentCreate` handler has not answered.
  var isAwaitingPaymentDecisionStream: AsyncStream<Bool> { get }
  var currentNavigationState: CheckoutNavigationState { get }
  var currentState: PrimerCheckoutState { get }

  var availablePaymentMethods: [InternalPaymentMethod] { get }
  var hasAlternativeToCurrentMethod: Bool { get }
  var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] { get }
  var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? { get }

  var isInitScreenEnabled: Bool { get }
  var isSuccessScreenEnabled: Bool { get }
  var isErrorScreenEnabled: Bool { get }

  func updateNavigationState(_ newState: CheckoutNavigationState)
  func cancelActivePaymentMethod(returnToSelection: Bool)
  func setSelectedVaultedPaymentMethod(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?)
  /// False when the failure came before any payment attempt, so a retry has nothing to repeat.
  var canRetryPayment: Bool { get }
  func retryPayment()
  func reload() async
}
