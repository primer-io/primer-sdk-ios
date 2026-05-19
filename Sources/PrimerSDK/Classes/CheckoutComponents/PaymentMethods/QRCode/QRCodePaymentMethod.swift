//
//  QRCodePaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
enum QRCodePaymentMethod {

  @MainActor
  static func registerAll(_ types: [PrimerPaymentMethodType]) {
    for type in types {
      let typeRawValue = type.rawValue
      PaymentMethodRegistry.shared.register(
        forKey: typeRawValue,
        scopeCreator: { checkoutScope, diContainer in
          try await createScope(
            paymentMethodType: typeRawValue,
            checkoutScope: checkoutScope,
            diContainer: diContainer
          )
        },
        viewCreator: createView(checkoutScope:)
      )
    }
  }

  @MainActor
  private static func createScope(
    paymentMethodType: String,
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) async throws -> DefaultQRCodeScope {

    let (defaultCheckoutScope, paymentMethodContext) = try DefaultCheckoutScope.validated(from: checkoutScope)

    do {
      let analyticsInteractor = try? await diContainer.resolve(
        CheckoutComponentsAnalyticsInteractorProtocol.self
      )

      let factory = try await diContainer.resolve(QRCodePaymentInteractorFactory.self)
      let interactor = try await factory.create(with: paymentMethodType)

      return DefaultQRCodeScope(
        checkoutScope: defaultCheckoutScope,
        presentationContext: paymentMethodContext,
        interactor: interactor,
        analyticsInteractor: analyticsInteractor,
        paymentMethodType: paymentMethodType
      )
    } catch let primerError as PrimerError {
      throw primerError
    } catch {
      throw PrimerError.invalidArchitecture(
        description: "Required QR code payment dependencies could not be resolved",
        recoverSuggestion:
          "Ensure CheckoutComponents DI registration runs before presenting QR code payment."
      )
    }
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    checkoutScope.getPaymentMethodScope(PrimerQRCodeScope.self)
      .map { scope in
        scope.screen.map { AnyView($0(scope)) }
          ?? AnyView(QRCodeView(scope: scope))
      }
  }
}
