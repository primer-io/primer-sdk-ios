//
//  DefaultPayPalScope.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import SwiftUI

@available(iOS 15.0, *)
@MainActor
final class DefaultPayPalScope: PrimerPayPalScope, ObservableObject, LogReporter {

  private(set) var presentationContext: PresentationContext

  var dismissalMechanism: [DismissalMechanism] {
    checkoutScope?.dismissalMechanism ?? []
  }

  var state: AsyncStream<PrimerPayPalState> {
    AsyncStream { continuation in
      let task = Task { @MainActor in
        for await _ in $internalState.values {
          continuation.yield(internalState)
        }
        continuation.finish()
      }

      continuation.onTermination = { _ in
        task.cancel()
      }
    }
  }

  var screen: PayPalScreenComponent?
  var payButton: PayPalButtonComponent?
  var submitButtonText: String?

  private weak var checkoutScope: DefaultCheckoutScope?
  private let processPayPalInteractor: ProcessPayPalPaymentInteractor
  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

  @Published private var internalState = PrimerPayPalState()

  init(
    checkoutScope: DefaultCheckoutScope,
    presentationContext: PresentationContext = .fromPaymentSelection,
    processPayPalInteractor: ProcessPayPalPaymentInteractor,
    analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol? = nil
  ) {
    self.checkoutScope = checkoutScope
    self.presentationContext = presentationContext
    self.processPayPalInteractor = processPayPalInteractor
    self.analyticsInteractor = analyticsInteractor
  }

  func start() {
    logger.debug(message: "PayPal scope started")
    internalState.step = .idle
  }

  func submit() {
    Task {
      await performPayment()
    }
  }

  func cancel() {
    logger.debug(message: "PayPal payment cancelled")
    checkoutScope?.onDismiss()
  }

  func onBack() {
    if presentationContext.shouldShowBackButton {
      checkoutScope?.checkoutNavigator.navigateBack()
    }
  }

  private func performPayment() async {
    internalState.step = .loading
    checkoutScope?.startProcessing()

    await analyticsInteractor?.trackEvent(
      .paymentSubmitted,
      metadata: .payment(PaymentEvent(paymentMethod: PrimerPaymentMethodType.payPal.rawValue))
    )

    do {
      try await checkoutScope?.invokeBeforePaymentCreate(
        paymentMethodType: PrimerPaymentMethodType.payPal.rawValue
      )

      internalState.step = .redirecting

      await analyticsInteractor?.trackEvent(
        .paymentProcessingStarted,
        metadata: .payment(PaymentEvent(paymentMethod: PrimerPaymentMethodType.payPal.rawValue))
      )

      let result = try await processPayPalInteractor.execute()

      internalState.step = .success
      checkoutScope?.handlePaymentSuccess(result)
    } catch {
      logger.error(message: "PayPal payment failed: \(error.localizedDescription)")
      internalState.step = .failure(error.localizedDescription)

      let primerError =
        error as? PrimerError ?? PrimerError.unknown(message: error.localizedDescription)
      checkoutScope?.handlePaymentError(primerError)
    }
  }
}
