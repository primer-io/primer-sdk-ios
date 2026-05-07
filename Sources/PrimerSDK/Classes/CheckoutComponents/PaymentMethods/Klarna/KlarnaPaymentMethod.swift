//
//  KlarnaPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct KlarnaPaymentMethod: PaymentMethodProtocol {

  static let paymentMethodType: String = PrimerPaymentMethodType.klarna.rawValue

  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) async throws -> any PrimerPaymentMethodScope {

    let (defaultCheckoutScope, paymentMethodContext) = try DefaultCheckoutScope.validated(from: checkoutScope)

    do {
      let processKlarnaInteractor: ProcessKlarnaPaymentInteractor = try await diContainer.resolve(
        ProcessKlarnaPaymentInteractor.self)
      let analyticsInteractor = try? await diContainer.resolve(
        CheckoutComponentsAnalyticsInteractorProtocol.self)

      return DefaultKlarnaScope(
        checkoutScope: defaultCheckoutScope,
        presentationContext: paymentMethodContext,
        processKlarnaInteractor: processKlarnaInteractor,
        analyticsInteractor: analyticsInteractor
      )
    } catch let primerError as PrimerError {
      throw primerError
    } catch {
      PrimerLogging.shared.logger.error(
        message: "Failed to resolve Klarna payment dependencies: \(error)")
      throw PrimerError.invalidArchitecture(
        description: "Required Klarna payment dependencies could not be resolved",
        recoverSuggestion:
          "Ensure CheckoutComponents DI registration runs before presenting Klarna."
      )
    }
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    guard let klarnaScope = checkoutScope.getPaymentMethodScope(PrimerKlarnaScope.self) else {
      PrimerLogging.shared.logger.error(message: "Failed to retrieve Klarna scope from checkout scope")
      return nil
    }

    return klarnaScope.screen.map { AnyView($0(klarnaScope)) }
      ?? AnyView(KlarnaView(scope: klarnaScope))
  }
}

@available(iOS 15.0, *)
extension KlarnaPaymentMethod {

  @MainActor
  static func register() {
    PaymentMethodRegistry.shared.register(
      forKey: paymentMethodType,
      scopeCreator: { try await createScope(checkoutScope: $0, diContainer: $1) },
      viewCreator: { createView(checkoutScope: $0) }
    )

    #if DEBUG
      TestKlarnaPaymentMethod.register()
    #endif
  }
}

#if DEBUG
  @available(iOS 15.0, *)
  struct TestKlarnaPaymentMethod: PaymentMethodProtocol {

    static let paymentMethodType: String = "PRIMER_TEST_KLARNA"

    @MainActor
    static func createScope(
      checkoutScope: PrimerCheckoutScope,
      diContainer: any ContainerProtocol
    ) async throws -> any PrimerPaymentMethodScope {
      try await KlarnaPaymentMethod.createScope(checkoutScope: checkoutScope, diContainer: diContainer)
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
      KlarnaPaymentMethod.createView(checkoutScope: checkoutScope)
    }

    @MainActor
    static func register() {
      PaymentMethodRegistry.shared.register(
        forKey: paymentMethodType,
        scopeCreator: { try await createScope(checkoutScope: $0, diContainer: $1) },
        viewCreator: { createView(checkoutScope: $0) }
      )
    }
  }
#endif
