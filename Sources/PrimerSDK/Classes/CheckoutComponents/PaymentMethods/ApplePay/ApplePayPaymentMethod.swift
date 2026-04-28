//
//  ApplePayPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct ApplePayPaymentMethod: PaymentMethodProtocol {

  static let paymentMethodType: String = "APPLE_PAY"

  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) async throws -> any PrimerPaymentMethodScope {
    let (defaultCheckoutScope, paymentMethodContext) = try DefaultCheckoutScope.validated(from: checkoutScope)

    return DefaultApplePayScope(
      checkoutScope: defaultCheckoutScope,
      presentationContext: paymentMethodContext
    )
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    // ACC-7173: audit §2a — ApplePayScreen uses @ObservedObject DefaultApplePayScope so the
    // metatype must stay concrete; SwiftUI's ObservableObject requires a concrete class.
    checkoutScope.getPaymentMethodScope(DefaultApplePayScope.self)
      .map { scope in
        scope.screen.map { AnyView($0(scope)) }
          ?? AnyView(ApplePayScreen(scope: scope))
      }
  }
}

@available(iOS 15.0, *)
extension ApplePayPaymentMethod {

  @MainActor
  static func register() {
    PaymentMethodRegistry.shared.register(
      forKey: paymentMethodType,
      scopeCreator: { try await createScope(checkoutScope: $0, diContainer: $1) },
      viewCreator: { createView(checkoutScope: $0) }
    )
  }
}
