//
//  PayPalPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct PayPalPaymentMethod: PaymentMethodProtocol {

  typealias ScopeType = DefaultPayPalScope

  static let paymentMethodType: String = PrimerPaymentMethodType.payPal.rawValue

  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) async throws -> DefaultPayPalScope {

    let (defaultCheckoutScope, paymentMethodContext) = try DefaultCheckoutScope.validated(from: checkoutScope)

    do {
      let processPayPalInteractor: ProcessPayPalPaymentInteractor = try await diContainer.resolve(
        ProcessPayPalPaymentInteractor.self)
      let analyticsInteractor = try? await diContainer.resolve(
        CheckoutComponentsAnalyticsInteractorProtocol.self)

      return DefaultPayPalScope(
        checkoutScope: defaultCheckoutScope,
        presentationContext: paymentMethodContext,
        processPayPalInteractor: processPayPalInteractor,
        analyticsInteractor: analyticsInteractor
      )
    } catch let primerError as PrimerError {
      throw primerError
    } catch {
      PrimerLogging.shared.logger.error(
        message: "Failed to resolve PayPal payment dependencies: \(error)")
      throw PrimerError.invalidArchitecture(
        description: "Required PayPal payment dependencies could not be resolved",
        recoverSuggestion:
          "Ensure CheckoutComponents DI registration runs before presenting PayPal."
      )
    }
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    guard let payPalScope = checkoutScope.getPaymentMethodScope(DefaultPayPalScope.self) else {
      return nil
    }

    return payPalScope.screen.map { AnyView($0(payPalScope)) }
      ?? AnyView(PayPalView(scope: payPalScope))
  }

  @MainActor
  func content<V: View>(@ViewBuilder content: @escaping (DefaultPayPalScope) -> V) -> AnyView {
    fatalError("Custom content method should be implemented by the CheckoutComponents framework")
  }

  @MainActor
  func defaultContent() -> AnyView {
    fatalError("Default content method should be implemented by the CheckoutComponents framework")
  }
}

@available(iOS 15.0, *)
extension PayPalPaymentMethod {

  @MainActor
  static func register() {
    PaymentMethodRegistry.shared.register(PayPalPaymentMethod.self)
  }
}
