//
//  ApplePayPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct ApplePayPaymentMethod: PaymentMethodProtocol {

  typealias ScopeType = DefaultApplePayScope

  static let paymentMethodType: String = "APPLE_PAY"

  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) async throws -> DefaultApplePayScope {
    guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
      throw PrimerError.invalidArchitecture(
        description: "ApplePayPaymentMethod requires DefaultCheckoutScope",
        recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
      )
    }

    let paymentMethodContext: PresentationContext =
      defaultCheckoutScope.availablePaymentMethods.count > 1 ? .fromPaymentSelection : .direct

    return DefaultApplePayScope(
      checkoutScope: defaultCheckoutScope,
      presentationContext: paymentMethodContext
    )
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    checkoutScope.getPaymentMethodScope(DefaultApplePayScope.self)
      .map { scope in
        scope.screen.map { AnyView($0(scope)) }
          ?? AnyView(ApplePayScreen(scope: scope))
      }
  }

  @MainActor
  func content<V: View>(@ViewBuilder content: @escaping (DefaultApplePayScope) -> V) -> AnyView {
    fatalError("Custom content method should be implemented by the CheckoutComponents framework")
  }

  @MainActor
  func defaultContent() -> AnyView {
    fatalError("Default content method should be implemented by the CheckoutComponents framework")
  }
}

@available(iOS 15.0, *)
extension ApplePayPaymentMethod {

  @MainActor
  static func register() {
    PaymentMethodRegistry.shared.register(ApplePayPaymentMethod.self)
  }
}
