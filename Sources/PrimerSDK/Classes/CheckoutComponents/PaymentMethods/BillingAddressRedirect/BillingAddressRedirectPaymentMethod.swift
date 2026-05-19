//
//  BillingAddressRedirectPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
enum BillingAddressRedirectPaymentMethod {

  @MainActor
  static func register() {
    PaymentMethodRegistry.shared.register(
      paymentMethodType: PrimerPaymentMethodType.adyenAffirm.rawValue,
      scopeCreator: createScope(for:checkoutScope:container:),
      viewCreator: createView(for:checkoutScope:)
    )
  }

  @MainActor
  private static func createScope(
    for paymentMethodType: String,
    checkoutScope: any PrimerCheckoutScope,
    container: any ContainerProtocol
  ) async throws -> DefaultBillingAddressRedirectScope {
    let (defaultCheckoutScope, paymentMethodContext) = try DefaultCheckoutScope.validated(from: checkoutScope)

    let mapper = try? await container.resolve(PaymentMethodMapper.self)
    let paymentMethod: CheckoutPaymentMethod? = defaultCheckoutScope.availablePaymentMethods
      .first { $0.type == paymentMethodType }
      .flatMap { mapper?.mapToPublic($0) }

    let processWebRedirectInteractor = try await container.resolve(ProcessWebRedirectPaymentInteractor.self)
    let validationService = (try? await container.resolve(ValidationService.self)) ?? DefaultValidationService()
    let accessibilityService = try? await container.resolve(AccessibilityAnnouncementService.self)
    let analyticsInteractor = try? await container.resolve(CheckoutComponentsAnalyticsInteractorProtocol.self)
    let repository = try? await container.resolve(WebRedirectRepository.self)

    return DefaultBillingAddressRedirectScope(
      paymentMethodType: paymentMethodType,
      checkoutScope: defaultCheckoutScope,
      presentationContext: paymentMethodContext,
      processWebRedirectInteractor: processWebRedirectInteractor,
      validationService: validationService,
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
    // ACC-7173: string-keyed `getPaymentMethodScope<T>(for:)` carries the same `T: PrimerPaymentMethodScope`
    // constraint that rejects existentials. Keep concrete metatype here; downstream screen still accepts
    // `any PrimerBillingAddressRedirectScope`.
    guard let billingScope: DefaultBillingAddressRedirectScope = checkoutScope.getPaymentMethodScope(for: paymentMethodType) else {
      return nil
    }

    return billingScope.screen.map { AnyView($0(billingScope)) }
      ?? AnyView(BillingAddressRedirectScreen(scope: billingScope))
  }
}
