//
//  BankSelectorPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

// MARK: - iDEAL Payment Method

@available(iOS 15.0, *)
struct IDealPaymentMethod: PaymentMethodProtocol {

  typealias ScopeType = DefaultBankSelectorScope

  static let paymentMethodType: String = PrimerPaymentMethodType.adyenIDeal.rawValue

  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) throws -> DefaultBankSelectorScope {
    try BankSelectorPaymentMethod.createBankSelectorScope(
      checkoutScope: checkoutScope,
      diContainer: diContainer,
      paymentMethodType: paymentMethodType
    )
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    BankSelectorPaymentMethod.createBankSelectorView(
      checkoutScope: checkoutScope,
      paymentMethodType: paymentMethodType
    )
  }

  @MainActor
  func content<V: View>(@ViewBuilder content: @escaping (DefaultBankSelectorScope) -> V) -> AnyView {
    fatalError("Custom content method should be implemented by the CheckoutComponents framework")
  }

  @MainActor
  func defaultContent() -> AnyView {
    fatalError("Default content method should be implemented by the CheckoutComponents framework")
  }
}

// MARK: - Dotpay Payment Method

@available(iOS 15.0, *)
struct DotpayPaymentMethod: PaymentMethodProtocol {

  typealias ScopeType = DefaultBankSelectorScope

  static let paymentMethodType: String = PrimerPaymentMethodType.adyenDotPay.rawValue

  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) throws -> DefaultBankSelectorScope {
    try BankSelectorPaymentMethod.createBankSelectorScope(
      checkoutScope: checkoutScope,
      diContainer: diContainer,
      paymentMethodType: paymentMethodType
    )
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    BankSelectorPaymentMethod.createBankSelectorView(
      checkoutScope: checkoutScope,
      paymentMethodType: paymentMethodType
    )
  }

  @MainActor
  func content<V: View>(@ViewBuilder content: @escaping (DefaultBankSelectorScope) -> V) -> AnyView {
    fatalError("Custom content method should be implemented by the CheckoutComponents framework")
  }

  @MainActor
  func defaultContent() -> AnyView {
    fatalError("Default content method should be implemented by the CheckoutComponents framework")
  }
}

// MARK: - Shared Bank Selector Logic

@available(iOS 15.0, *)
enum BankSelectorPaymentMethod {

  /// Registers both iDEAL and Dotpay payment methods in the registry.
  @MainActor
  static func registerAll() {
    PaymentMethodRegistry.shared.register(IDealPaymentMethod.self)
    PaymentMethodRegistry.shared.register(DotpayPaymentMethod.self)
  }

  /// Shared scope creation logic for all bank selector payment methods.
  @MainActor
  static func createBankSelectorScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol,
    paymentMethodType: String
  ) throws -> DefaultBankSelectorScope {

    guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
      throw PrimerError.invalidArchitecture(
        description: "BankSelectorPaymentMethod requires DefaultCheckoutScope",
        recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
      )
    }

    let availableMethodsCount = defaultCheckoutScope.availablePaymentMethods.count
    let paymentMethodContext: PresentationContext = availableMethodsCount > 1
      ? .fromPaymentSelection
      : .direct

    do {
      let interactor: ProcessBankSelectorPaymentInteractor = try diContainer.resolveSync(
        ProcessBankSelectorPaymentInteractor.self)
      let analyticsInteractor = try? diContainer.resolveSync(
        CheckoutComponentsAnalyticsInteractorProtocol.self)

      return DefaultBankSelectorScope(
        checkoutScope: defaultCheckoutScope,
        presentationContext: paymentMethodContext,
        interactor: interactor,
        paymentMethodType: paymentMethodType,
        analyticsInteractor: analyticsInteractor
      )
    } catch let primerError as PrimerError {
      throw primerError
    } catch {
      throw PrimerError.invalidArchitecture(
        description: "Required bank selector dependencies could not be resolved",
        recoverSuggestion:
          "Ensure CheckoutComponents DI registration runs before presenting bank selector."
      )
    }
  }

  /// Shared view creation logic for all bank selector payment methods.
  @MainActor
  static func createBankSelectorView(
    checkoutScope: any PrimerCheckoutScope,
    paymentMethodType: String
  ) -> AnyView? {
    guard let bankSelectorScope: DefaultBankSelectorScope =
      checkoutScope.getPaymentMethodScope(for: paymentMethodType)
    else {
      return nil
    }

    if let customScreen = bankSelectorScope.screen {
      return AnyView(customScreen(bankSelectorScope))
    } else {
      return AnyView(BankSelectorScreen(scope: bankSelectorScope))
    }
  }
}
