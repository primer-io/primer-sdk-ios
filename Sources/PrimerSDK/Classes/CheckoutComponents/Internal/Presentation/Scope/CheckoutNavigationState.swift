//
//  CheckoutNavigationState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@available(iOS 15.0, *)
enum CheckoutNavigationState: Equatable {
  case loading
  case paymentMethodSelection
  case vaultedPaymentMethods
  case deleteVaultedPaymentMethodConfirmation(
    PrimerHeadlessUniversalCheckout.VaultedPaymentMethod)
  case paymentMethod(String)
  case processing
  case success(PaymentResult)
  case failure(PrimerError)
  case dismissed

  static func == (lhs: CheckoutNavigationState, rhs: CheckoutNavigationState) -> Bool {
    switch (lhs, rhs) {
    case (.loading, .loading),
      (.paymentMethodSelection, .paymentMethodSelection),
      (.vaultedPaymentMethods, .vaultedPaymentMethods),
      (.processing, .processing),
      (.dismissed, .dismissed):
      true
    case let (
      .deleteVaultedPaymentMethodConfirmation(lhsMethod),
      .deleteVaultedPaymentMethodConfirmation(rhsMethod)
    ):
      lhsMethod.id == rhsMethod.id
    case let (.paymentMethod(lhsType), .paymentMethod(rhsType)):
      lhsType == rhsType
    case let (.success(lhsResult), .success(rhsResult)):
      lhsResult.paymentId == rhsResult.paymentId
    case let (.failure(lhsError), .failure(rhsError)):
      lhsError.localizedDescription == rhsError.localizedDescription
    default:
      false
    }
  }
}
