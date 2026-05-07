//
//  WebRedirectPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
struct WebRedirectPaymentMethod: PaymentMethodProtocol {

  static var paymentMethodType: String { "WEB_REDIRECT" }

  @MainActor
  static func register(types: [String]) {
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
    let (defaultCheckoutScope, paymentMethodContext) = try DefaultCheckoutScope.validated(from: checkoutScope)

    let mapper = try? await container.resolve(PaymentMethodMapper.self)
    let paymentMethod: CheckoutPaymentMethod? = defaultCheckoutScope.availablePaymentMethods
      .first { $0.type == paymentMethodType }
      .flatMap { mapper?.mapToPublic($0) }

    let processWebRedirectInteractor = try await container.resolve(ProcessWebRedirectPaymentInteractor.self)
    let accessibilityService = try? await container.resolve(AccessibilityAnnouncementService.self)
    let analyticsInteractor = try? await container.resolve(CheckoutComponentsAnalyticsInteractorProtocol.self)
    let repository = try await container.resolve(WebRedirectRepository.self)

    return DefaultWebRedirectScope(
      paymentMethodType: paymentMethodType,
      checkoutScope: defaultCheckoutScope,
      presentationContext: paymentMethodContext,
      processWebRedirectInteractor: processWebRedirectInteractor,
      accessibilityService: accessibilityService,
      analyticsInteractor: analyticsInteractor,
      repository: repository,
      paymentMethod: paymentMethod,
      surchargeAmount: paymentMethod?.formattedSurcharge
    )
  }

  @MainActor
  private static func createView(
    for paymentMethodType: String,
    checkoutScope: any PrimerCheckoutScope
  ) -> AnyView? {
    // ACC-7173: string-keyed `getPaymentMethodScope<T>(for:)` carries the same
    // `T: PrimerPaymentMethodScope` constraint that rejects existentials. Keep concrete metatype
    // here; the downstream WebRedirectScreen still accepts `any PrimerWebRedirectScope`.
    guard let webRedirectScope: DefaultWebRedirectScope = checkoutScope.getPaymentMethodScope(for: paymentMethodType) else {
      return nil
    }

    return webRedirectScope.screen.map { AnyView($0(webRedirectScope)) }
      ?? AnyView(WebRedirectScreen(scope: webRedirectScope))
  }

  @MainActor
  static func createScope(
    checkoutScope: PrimerCheckoutScope,
    diContainer: any ContainerProtocol
  ) async throws -> any PrimerPaymentMethodScope {
    throw PrimerError.invalidArchitecture(
      description: "WebRedirectPaymentMethod.createScope requires a payment method type parameter",
      recoverSuggestion: "Use register(types:) for dynamic registration instead"
    )
  }

  @MainActor
  static func createView(checkoutScope: any PrimerCheckoutScope) -> AnyView? {
    nil
  }
}

@available(iOS 15.0, *)
extension PaymentMethodRegistry {

  @MainActor
  func register(
    paymentMethodType: String,
    scopeCreator: @escaping @MainActor (String, any PrimerCheckoutScope, any ContainerProtocol) async throws -> any PrimerPaymentMethodScope,
    viewCreator: @escaping @MainActor (String, any PrimerCheckoutScope) -> AnyView?
  ) {
    let wrappedScopeCreator: @MainActor (PrimerCheckoutScope, any ContainerProtocol) async throws -> any PrimerPaymentMethodScope = { checkoutScope, container in
      try await scopeCreator(paymentMethodType, checkoutScope, container)
    }

    let wrappedViewCreator: @MainActor (any PrimerCheckoutScope) -> AnyView? = { checkoutScope in
      viewCreator(paymentMethodType, checkoutScope)
    }

    registerInternal(
      typeKey: paymentMethodType,
      scopeCreator: wrappedScopeCreator,
      viewCreator: wrappedViewCreator
    )
  }
}
