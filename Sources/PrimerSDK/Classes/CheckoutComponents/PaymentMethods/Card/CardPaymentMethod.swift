//
//  CardPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct CardPaymentMethod: PaymentMethodProtocol {

  typealias ScopeType = DefaultCardFormScope

  static let paymentMethodType: String = PrimerPaymentMethodType.paymentCard.rawValue

  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) throws -> DefaultCardFormScope {

    guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
      throw PrimerError.invalidArchitecture(
        description: "CardPaymentMethod requires DefaultCheckoutScope",
        recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
      )
    }

    let paymentMethodContext: PresentationContext =
      defaultCheckoutScope.availablePaymentMethods.count > 1 ? .fromPaymentSelection : .direct

    do {
      let processCardInteractor: ProcessCardPaymentInteractor = try diContainer.resolveSync(
        ProcessCardPaymentInteractor.self)
      let validateInputInteractor = try? diContainer.resolveSync(ValidateInputInteractor.self)
      let cardNetworkDetectionInteractor = try? diContainer.resolveSync(
        CardNetworkDetectionInteractor.self)
      let analyticsInteractor = try? diContainer.resolveSync(
        CheckoutComponentsAnalyticsInteractorProtocol.self)
      let configurationService: ConfigurationService = try diContainer.resolveSync(
        ConfigurationService.self)

      if validateInputInteractor == nil {
        PrimerLogging.shared.logger.debug(
          message:
            "[CardPaymentMethod] ValidateInputInteractor not registered - using local validation only"
        )
      }

      if cardNetworkDetectionInteractor == nil {
        PrimerLogging.shared.logger.warn(
          message:
            "[CardPaymentMethod] CardNetworkDetectionInteractor not registered - co-badged detection disabled"
        )
      }

      return DefaultCardFormScope(
        checkoutScope: defaultCheckoutScope,
        presentationContext: paymentMethodContext,
        processCardPaymentInteractor: processCardInteractor,
        validateInputInteractor: validateInputInteractor,
        cardNetworkDetectionInteractor: cardNetworkDetectionInteractor,
        analyticsInteractor: analyticsInteractor,
        configurationService: configurationService
      )
    } catch let primerError as PrimerError {
      throw primerError
    } catch {
      PrimerLogging.shared.logger.error(
        message: "[CardPaymentMethod] Failed to resolve card payment dependencies: \(error)")
      throw PrimerError.invalidArchitecture(
        description: "Required card payment dependencies could not be resolved",
        recoverSuggestion:
          "Ensure CheckoutComponents DI registration runs before presenting the Card form."
      )
    }
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    checkoutScope.getPaymentMethodScope(DefaultCardFormScope.self)
      .map { scope in
        scope.screen.map { AnyView($0(scope)) }
          ?? AnyView(CardFormScreen(scope: scope))
      }
  }

  @MainActor
  func content<V: View>(@ViewBuilder content: @escaping (DefaultCardFormScope) -> V) -> AnyView {
    fatalError("Custom content method should be implemented by the CheckoutComponents framework")
  }

  @MainActor
  func defaultContent() -> AnyView {
    fatalError("Default content method should be implemented by the CheckoutComponents framework")
  }
}

@available(iOS 15.0, *)
extension CardPaymentMethod {

  @MainActor
  static func register() {
    PaymentMethodRegistry.shared.register(CardPaymentMethod.self)
  }
}
