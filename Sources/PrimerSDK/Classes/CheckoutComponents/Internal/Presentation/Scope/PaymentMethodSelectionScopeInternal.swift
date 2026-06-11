//
//  PaymentMethodSelectionScopeInternal.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
@MainActor
protocol PaymentMethodSelectionScopeInternal: PrimerPaymentMethodSelectionScope {
  var currentState: PrimerPaymentMethodSelectionState { get }
  var vaultedPaymentMethods: [PrimerHeadlessUniversalCheckout.VaultedPaymentMethod] { get }
  func syncSelectedVaultedPaymentMethod()
  func collapsePaymentMethods()
  func selectVaultedPaymentMethod(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod)
  func deleteVaultedPaymentMethod(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod) async throws
  func navigateToDeleteConfirmation(_ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod)
}
