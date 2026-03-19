//
//  CheckoutNavigator.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class CheckoutNavigator: ObservableObject, LogReporter {

  private let coordinator: CheckoutCoordinator

  var navigationEvents: AsyncStream<CheckoutRoute> {
    AsyncStream { continuation in
      let task = Task { @MainActor [self] in
        for await _ in coordinator.$navigationStack.values {
          continuation.yield(coordinator.currentRoute)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  var checkoutCoordinator: CheckoutCoordinator {
    coordinator
  }

  init(coordinator: CheckoutCoordinator? = nil) {
    self.coordinator = coordinator ?? CheckoutCoordinator()
  }

  func navigateToLoading() {
    coordinator.navigate(to: .loading)
  }

  func navigateToPaymentSelection() {
    coordinator.navigate(to: .paymentMethodSelection)
  }

  func navigateToVaultedPaymentMethods() {
    coordinator.navigate(to: .vaultedPaymentMethods)
  }

  func navigateToDeleteVaultedPaymentMethodConfirmation(
    _ method: PrimerHeadlessUniversalCheckout.VaultedPaymentMethod
  ) {
    coordinator.navigate(to: .deleteVaultedPaymentMethodConfirmation(method))
  }

  func navigateToPaymentMethod(
    _ paymentMethodType: String, context: PresentationContext = .fromPaymentSelection
  ) {
    coordinator.navigate(to: .paymentMethod(paymentMethodType, context))
  }

  func navigateToProcessing() {
    coordinator.navigate(to: .processing)
  }

  func navigateToError(_ error: PrimerError) {
    coordinator.handlePaymentFailure(error)
  }

  func handleOtherPaymentMethods() {
    coordinator.navigate(to: .paymentMethodSelection)
  }

  func navigateBack() {
    coordinator.goBack()
  }

  func dismiss() {
    coordinator.dismiss()
  }
}
