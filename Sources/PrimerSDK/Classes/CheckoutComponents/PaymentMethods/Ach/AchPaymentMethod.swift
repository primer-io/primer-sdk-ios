//
//  AchPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct AchPaymentMethod: PaymentMethodProtocol {

  typealias ScopeType = DefaultAchScope

  static let paymentMethodType: String = PrimerPaymentMethodType.stripeAch.rawValue

  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) throws -> DefaultAchScope {

    guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
      throw PrimerError.invalidArchitecture(
        description: "AchPaymentMethod requires DefaultCheckoutScope",
        recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
      )
    }

    let availableMethodsCount = defaultCheckoutScope.availablePaymentMethods.count

    let paymentMethodContext: PresentationContext
    if availableMethodsCount > 1 {
      paymentMethodContext = .fromPaymentSelection
    } else {
      paymentMethodContext = .direct
    }

    do {
      let processAchInteractor: ProcessAchPaymentInteractor = try diContainer.resolveSync(
        ProcessAchPaymentInteractor.self)
      let analyticsInteractor = try? diContainer.resolveSync(
        CheckoutComponentsAnalyticsInteractorProtocol.self)

      return DefaultAchScope(
        checkoutScope: defaultCheckoutScope,
        presentationContext: paymentMethodContext,
        processAchInteractor: processAchInteractor,
        analyticsInteractor: analyticsInteractor
      )
    } catch let primerError as PrimerError {
      throw primerError
    } catch {
      PrimerLogging.shared.logger.error(
        message: "Failed to resolve ACH payment dependencies: \(error)")
      throw PrimerError.invalidArchitecture(
        description: "Required ACH payment dependencies could not be resolved",
        recoverSuggestion:
          "Ensure CheckoutComponents DI registration runs before presenting ACH."
      )
    }
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    guard let achScope = checkoutScope.getPaymentMethodScope(DefaultAchScope.self) else {
      let logger = PrimerLogging.shared.logger
      logger.error(message: "Failed to retrieve ACH scope from checkout scope")
      return nil
    }

    if let customScreen = achScope.screen {
      return AnyView(customScreen(achScope))
    } else {
      return AnyView(AchView(scope: achScope))
    }
  }

  @MainActor
  func content<V: View>(@ViewBuilder content: @escaping (DefaultAchScope) -> V) -> AnyView {
    fatalError("Custom content method should be implemented by the CheckoutComponents framework")
  }

  @MainActor
  func defaultContent() -> AnyView {
    fatalError("Default content method should be implemented by the CheckoutComponents framework")
  }
}

// MARK: - Registration Helper

@available(iOS 15.0, *)
extension AchPaymentMethod {

  @MainActor
  static func register() {
    PaymentMethodRegistry.shared.register(AchPaymentMethod.self)

    #if DEBUG
      TestAchPaymentMethod.register()
    #endif
  }
}

// MARK: - Test ACH Payment Method (DEBUG only)

#if DEBUG
  @available(iOS 15.0, *)
  struct TestAchPaymentMethod: PaymentMethodProtocol {

    typealias ScopeType = DefaultAchScope

    static let paymentMethodType: String = "PRIMER_TEST_STRIPE_ACH"

    @MainActor
    static func createScope(
      checkoutScope: PrimerCheckoutScope,
      diContainer: any ContainerProtocol
    ) throws -> DefaultAchScope {
      try AchPaymentMethod.createScope(checkoutScope: checkoutScope, diContainer: diContainer)
    }

    @MainActor
    static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
      AchPaymentMethod.createView(checkoutScope: checkoutScope)
    }

    @MainActor
    func content<V: View>(@ViewBuilder content: @escaping (DefaultAchScope) -> V) -> AnyView {
      fatalError("Custom content method should be implemented by the CheckoutComponents framework")
    }

    @MainActor
    func defaultContent() -> AnyView {
      fatalError("Default content method should be implemented by the CheckoutComponents framework")
    }

    @MainActor
    static func register() {
      PaymentMethodRegistry.shared.register(TestAchPaymentMethod.self)
    }
  }
#endif
