//
//  BackendDrivenPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
import SwiftUI

@available(iOS 16.0, *)
enum BackendDrivenPaymentMethod {

  @MainActor
  static func register(types: [String]) {
    let types = types.filter { $0 != CardPaymentMethod.paymentMethodType }
    guard !types.isEmpty else { return }
    SDUITokenResolvers.register()
    for type in types {
      PaymentMethodRegistry.shared.register(
        paymentMethodType: type,
        scopeCreator: createScope(for:checkoutScope:container:),
        viewCreator: createView(for:checkoutScope:)
      )
    }
  }

  @MainActor
  private static func createScope(
    for paymentMethodType: String,
    checkoutScope: any PrimerCheckoutScope,
    container: any ContainerProtocol
  ) async throws -> any PrimerPaymentMethodScope {
    let (defaultCheckoutScope, presentationContext) = try DefaultCheckoutScope.validated(from: checkoutScope)
    return DefaultBackendDrivenScope(
      paymentMethodType: paymentMethodType,
      checkoutScope: defaultCheckoutScope,
      presentationContext: presentationContext
    )
  }

  @MainActor
  private static func createView(
    for paymentMethodType: String,
    checkoutScope: any PrimerCheckoutScope
  ) -> AnyView? {
    guard let scope: DefaultBackendDrivenScope = checkoutScope.getPaymentMethodScope(for: paymentMethodType) else {
      return nil
    }
    return AnyView(BackendDrivenScreen(scope: scope))
  }
}
