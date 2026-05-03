//
//  CheckoutRoute.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

@available(iOS 15.0, *)
public enum PresentationContext {
  case direct
  case fromPaymentSelection

  var shouldShowBackButton: Bool {
    self == .fromPaymentSelection
  }
}

@available(iOS 15.0, *)
enum NavigationBehavior {
  case push
  case reset
  case replace
}

@available(iOS 15.0, *)
enum CheckoutRoute: Hashable, Identifiable {
  case splash
  case loading
  case paymentMethodSelection
  case vaultedPaymentMethods
  case deleteVaultedPaymentMethodConfirmation(PrimerHeadlessUniversalCheckout.VaultedPaymentMethod)
  case processing
  case success(PaymentResult)
  case failure(PrimerError)
  case paymentMethod(String, PresentationContext)

  var id: String {
    switch self {
    case .splash: "splash"
    case .loading: "loading"
    case .paymentMethodSelection: "payment-method-selection"
    case .vaultedPaymentMethods: "vaulted-payment-methods"
    case let .deleteVaultedPaymentMethodConfirmation(method):
      "delete-vaulted-payment-method-confirmation-\(method.id)"
    case .processing: "processing"
    case let .paymentMethod(type, context):
      "payment-method-\(type)-\(context == .direct ? "direct" : "selection")"
    case .success: "success"
    case .failure: "failure"
    }
  }

  func hash(into hasher: inout Hasher) {
    hasher.combine(id)
  }

  static func == (lhs: CheckoutRoute, rhs: CheckoutRoute) -> Bool {
    lhs.id == rhs.id
  }

  var navigationBehavior: NavigationBehavior {
    switch self {
    case .splash: .reset
    case .loading: .replace
    case .paymentMethodSelection: .reset
    case .vaultedPaymentMethods: .push
    case .deleteVaultedPaymentMethodConfirmation: .push
    case .paymentMethod: .push
    case .processing: .replace
    case .success, .failure: .replace
    }
  }
}
