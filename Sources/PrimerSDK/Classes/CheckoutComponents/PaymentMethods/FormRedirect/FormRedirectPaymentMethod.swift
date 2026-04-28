//
//  FormRedirectPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
enum FormRedirectPaymentMethodHelper {

  @MainActor
  static func createScopeForPaymentMethodType(
    _ paymentMethodType: String,
    checkoutScope: DefaultCheckoutScope,
    diContainer: any ContainerProtocol
  ) async throws -> any PrimerPaymentMethodScope {
    let paymentMethodContext: PresentationContext =
      checkoutScope.availablePaymentMethods.count > 1 ? .fromPaymentSelection : .direct

    do {
      let processPaymentInteractor: ProcessFormRedirectPaymentInteractor = try await diContainer.resolve(
        ProcessFormRedirectPaymentInteractor.self
      )
      let validationService: ValidationService = try await diContainer.resolve(
        ValidationService.self
      )
      let analyticsInteractor = try? await diContainer.resolve(
        CheckoutComponentsAnalyticsInteractorProtocol.self
      )

      return DefaultFormRedirectScope(
        paymentMethodType: paymentMethodType,
        checkoutScope: checkoutScope,
        presentationContext: paymentMethodContext,
        processPaymentInteractor: processPaymentInteractor,
        validationService: validationService,
        analyticsInteractor: analyticsInteractor
      )
    } catch let primerError as PrimerError {
      throw primerError
    } catch {
      PrimerLogging.shared.logger.error(
        message: "[FormRedirectPaymentMethod] Failed to resolve dependencies for \(paymentMethodType): \(error)"
      )
      throw PrimerError.invalidArchitecture(
        description: "Required form redirect payment dependencies could not be resolved",
        recoverSuggestion: "Ensure CheckoutComponents DI registration runs before presenting form redirect."
      )
    }
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    // ACC-7173: audit §2a — FormRedirectContainerView uses @ObservedObject DefaultFormRedirectScope
    // so the metatype must stay concrete; SwiftUI's ObservableObject requires a concrete class.
    checkoutScope.getPaymentMethodScope(DefaultFormRedirectScope.self)
      .map { scope in
        scope.screen.map { AnyView($0(scope)) }
          ?? AnyView(FormRedirectContainerView(scope: scope))
      }
  }
}

@available(iOS 15.0, *)
private struct FormRedirectContainerView: View {

  @ObservedObject var scope: DefaultFormRedirectScope
  @State private var currentState = PrimerFormRedirectState()

  var body: some View {
    Group {
      switch currentState.status {
      case .awaitingExternalCompletion:
        FormRedirectPendingScreen(scope: scope, state: currentState)
      default:
        FormRedirectScreen(scope: scope, state: currentState)
      }
    }
    .task {
      for await state in scope.state {
        currentState = state
      }
    }
  }
}

@available(iOS 15.0, *)
struct BlikPaymentMethod: PaymentMethodProtocol {

  static let paymentMethodType: String = PrimerPaymentMethodType.adyenBlik.rawValue

  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) async throws -> any PrimerPaymentMethodScope {
    let (scope, _) = try DefaultCheckoutScope.validated(from: checkoutScope)
    return try await FormRedirectPaymentMethodHelper.createScopeForPaymentMethodType(
      paymentMethodType,
      checkoutScope: scope,
      diContainer: diContainer
    )
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    FormRedirectPaymentMethodHelper.createView(checkoutScope: checkoutScope)
  }

}

@available(iOS 15.0, *)
struct MBWayPaymentMethod: PaymentMethodProtocol {

  static let paymentMethodType: String = PrimerPaymentMethodType.adyenMBWay.rawValue

  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) async throws -> any PrimerPaymentMethodScope {
    let (scope, _) = try DefaultCheckoutScope.validated(from: checkoutScope)
    return try await FormRedirectPaymentMethodHelper.createScopeForPaymentMethodType(
      paymentMethodType,
      checkoutScope: scope,
      diContainer: diContainer
    )
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    FormRedirectPaymentMethodHelper.createView(checkoutScope: checkoutScope)
  }

}

@available(iOS 15.0, *)
enum FormRedirectPaymentMethod {

  @MainActor
  static func register() {
    PaymentMethodRegistry.shared.register(
      forKey: BlikPaymentMethod.paymentMethodType,
      scopeCreator: { try await BlikPaymentMethod.createScope(checkoutScope: $0, diContainer: $1) },
      viewCreator: { BlikPaymentMethod.createView(checkoutScope: $0) }
    )
    PaymentMethodRegistry.shared.register(
      forKey: MBWayPaymentMethod.paymentMethodType,
      scopeCreator: { try await MBWayPaymentMethod.createScope(checkoutScope: $0, diContainer: $1) },
      viewCreator: { MBWayPaymentMethod.createView(checkoutScope: $0) }
    )
  }
}
