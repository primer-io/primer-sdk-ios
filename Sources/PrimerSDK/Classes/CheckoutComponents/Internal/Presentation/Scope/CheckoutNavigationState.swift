//
//  CheckoutNavigationState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

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

  /// States the inline sheet (`InlineFlowHost`) presents: the payment flow, plus the SDK-owned
  /// vault-management screens.
  ///
  /// Vault management belongs here even though `PrimerVaultedPaymentMethods` is embedded by the
  /// merchant — that component shows only the selected method, so "Show all" has nowhere to go unless
  /// the host presents the full list, and deleting from that list needs its confirmation screen too.
  ///
  /// `loading`, `paymentMethodSelection` and `dismissed` stay out: those are rendered by the
  /// merchant's own embedded content.
  var presentsInlineFlowSheet: Bool {
    switch self {
    case .paymentMethod, .processing, .success, .failure,
         .vaultedPaymentMethods, .deleteVaultedPaymentMethodConfirmation:
      true
    case .loading, .paymentMethodSelection, .dismissed:
      false
    }
  }

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
      lhsError.diagnosticsId == rhsError.diagnosticsId
    default:
      false
    }
  }
}
