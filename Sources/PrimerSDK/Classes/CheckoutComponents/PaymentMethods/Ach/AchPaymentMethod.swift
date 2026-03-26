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
  ) async throws -> DefaultAchScope {

    guard let defaultCheckoutScope = checkoutScope as? DefaultCheckoutScope else {
      throw PrimerError.invalidArchitecture(
        description: "AchPaymentMethod requires DefaultCheckoutScope",
        recoverSuggestion: "Ensure you're using the default CheckoutComponents implementation"
      )
    }

    let paymentMethodContext: PresentationContext =
      defaultCheckoutScope.availablePaymentMethods.count > 1 ? .fromPaymentSelection : .direct

    do {
      let processAchInteractor: ProcessAchPaymentInteractor = try await diContainer.resolve(
        ProcessAchPaymentInteractor.self
      )
      let analyticsInteractor = try? await diContainer.resolve(
        CheckoutComponentsAnalyticsInteractorProtocol.self
      )

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
        message: "Failed to resolve ACH payment dependencies: \(error)"
      )
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
      PrimerLogging.shared.logger.error(message: "Failed to retrieve ACH scope from checkout scope")
      return nil
    }

    return achScope.screen.map { AnyView($0(achScope)) }
      ?? AnyView(AchView(scope: achScope))
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

#if DEBUG
  @available(iOS 15.0, *)
  struct TestAchPaymentMethod: PaymentMethodProtocol {

    typealias ScopeType = DefaultAchScope

    static let paymentMethodType: String = "PRIMER_TEST_STRIPE_ACH"

    @MainActor
    static func createScope(
      checkoutScope: PrimerCheckoutScope,
      diContainer: any ContainerProtocol
    ) async throws -> DefaultAchScope {
      try await AchPaymentMethod.createScope(checkoutScope: checkoutScope, diContainer: diContainer)
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
