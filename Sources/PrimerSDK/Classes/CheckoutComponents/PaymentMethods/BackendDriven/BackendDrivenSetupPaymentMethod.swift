//
//  BackendDrivenSetupPaymentMethod.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI
@_spi(PrimerInternal) import PrimerBDCEngine
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Backend-driven methods that start with a setup (`entry` other than `pay`). Registered only under
/// the `.vault` intent, where they save the method instead of paying.
@available(iOS 15.0, *)
enum BackendDrivenSetupPaymentMethod {

  @MainActor
  static func register(types: [String]) {
    for type in types {
      PaymentMethodRegistry.shared.register(
        paymentMethodType: type,
        scopeCreator: createScope(for:checkoutScope:container:),
        viewCreator: { _, _ in AnyView(DefaultLoadingScreen()) }
      )
    }
  }

  /// The configured methods this path can save: backend-driven, entered through a setup.
  static func setupMethods(in paymentMethods: [PrimerPaymentMethod]?) -> [PrimerPaymentMethod] {
    (paymentMethods ?? []).filter { $0.isBackendDriven && $0.entry.requiresSetup }
  }

  /// The setup methods whose client requirements this SDK meets. A failed check hides them all,
  /// as Drop-In does.
  @MainActor
  static func runnableSetupTypes(in paymentMethods: [PrimerPaymentMethod]?) async -> Set<String> {
    let candidates = setupMethods(in: paymentMethods)
    guard !candidates.isEmpty, let verdicts = try? await ClientRequirements.check(candidates) else { return [] }
    return Set(candidates.filter { $0.id.flatMap { verdicts[$0]?.satisfied } == true }.map(\.type))
  }

  @MainActor
  private static func createScope(
    for paymentMethodType: String,
    checkoutScope: any PrimerCheckoutScope,
    container: any ContainerProtocol
  ) async throws -> any PrimerPaymentMethodScope {
    let (defaultCheckoutScope, paymentMethodContext) = try DefaultCheckoutScope.validated(from: checkoutScope)
    return DefaultBackendDrivenSetupScope(
      paymentMethodType: paymentMethodType,
      checkoutScope: defaultCheckoutScope,
      presentationContext: paymentMethodContext,
      repository: try await container.resolve(BackendDrivenSetupRepository.self)
    )
  }
}
