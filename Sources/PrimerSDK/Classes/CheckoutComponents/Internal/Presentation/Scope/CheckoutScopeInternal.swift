//
//  CheckoutScopeInternal.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
protocol CheckoutScopeInternal: PrimerCheckoutScope {
  var paymentMethodSelectionInternal: any PaymentMethodSelectionScopeInternal { get }
  var checkoutNavigator: CheckoutNavigator { get }

  var navigationStateStream: AsyncStream<CheckoutNavigationState> { get }
  var currentNavigationState: CheckoutNavigationState { get }
  var currentState: PrimerCheckoutState { get }

  var availablePaymentMethods: [InternalPaymentMethod] { get }
  var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] { get }
  var selectedVaultedPaymentMethod: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod? { get }

  var paymentMethodSelectionScreen: PaymentMethodSelectionScreenComponent? { get }
  var successScreen: ((PaymentResult) -> AnyView)? { get }
  var isInitScreenEnabled: Bool { get }
  var isSuccessScreenEnabled: Bool { get }
  var isErrorScreenEnabled: Bool { get }

  func updateNavigationState(_ newState: CheckoutNavigationState)
  func setSelectedVaultedPaymentMethod(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod?)
  func retryPayment()
}
