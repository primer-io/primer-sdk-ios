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
          try createScope(
            paymentMethodType: typeRawValue,
            checkoutScope: checkoutScope,
            diContainer: diContainer
          )
        },
        viewCreator: { checkoutScope in
          createView(checkoutScope: checkoutScope)
        }
      )
    }
  }

  // MARK: - Scope Creation

  @MainActor
  private static func createScope(
    paymentMethodType: String,
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) throws -> DefaultQRCodeScope {

    guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
      throw PrimerError.invalidArchitecture(
        description: "QRCodePaymentMethod requires DefaultCheckoutScope",
        recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
      )
    }

    let paymentMethodContext: PresentationContext =
      defaultCheckoutScope.availablePaymentMethods.count > 1 ? .fromPaymentSelection : .direct

    do {
      let repository: QRCodeRepository = try diContainer.resolveSync(QRCodeRepository.self)

      let interactor = ProcessQRCodePaymentInteractorImpl(
        repository: repository,
        paymentMethodType: paymentMethodType
      )

      return DefaultQRCodeScope(
        checkoutScope: defaultCheckoutScope,
        presentationContext: paymentMethodContext,
        interactor: interactor
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

  // MARK: - View Creation

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    guard let qrCodeScope = checkoutScope.getPaymentMethodScope(DefaultQRCodeScope.self) else {
      return nil
    }

    return qrCodeScope.screen.map { AnyView($0(qrCodeScope)) }
      ?? AnyView(QRCodeView(scope: qrCodeScope))
  }
}
