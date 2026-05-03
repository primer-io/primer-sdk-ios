//
//  CheckoutAnalyticsTracker.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@available(iOS 15.0, *)
@MainActor
final class CheckoutAnalyticsTracker: LogReporter {

  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

  init(analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?) {
    self.analyticsInteractor = analyticsInteractor
  }

  func trackStateChange(_ state: PrimerCheckoutState) async {
    switch state {
    case .ready:
      await analyticsInteractor?.trackEvent(.checkoutFlowStarted, metadata: .general())
      let initDuration = await LoggingSessionContext.shared.calculateInitDuration()
      let message = initDuration.map { "Checkout initialized (\($0)ms)" } ?? "Checkout initialized"
      logger.info(
        message: message,
        event: "checkout-initialized",
        userInfo: initDuration.map { ["init_duration_ms": $0] }
      )

    case let .success(result):
      if let paymentMethod = result.paymentMethodType {
        await analyticsInteractor?.trackEvent(
          .paymentSuccess,
          metadata: .payment(
            PaymentEvent(
              paymentMethod: paymentMethod,
              paymentId: result.paymentId
            )))
      } else {
        await analyticsInteractor?.trackEvent(.paymentSuccess, metadata: .general())
      }

    case let .failure(error):
      await analyticsInteractor?.trackEvent(
        .paymentFailure, metadata: extractFailureMetadata(from: error))

    case .dismissed:
      await analyticsInteractor?.trackEvent(.paymentFlowExited, metadata: .general())

    default:
      break
    }
  }

  func trackRetry(navigationState: CheckoutNavigationState) async {
    let metadata: AnalyticsEventMetadata = if case let .failure(error) = navigationState {
      extractFailureMetadata(from: error)
    } else {
      .general()
    }
    await analyticsInteractor?.trackEvent(.paymentReattempted, metadata: metadata)
  }

  private func extractFailureMetadata(from error: PrimerError) -> AnalyticsEventMetadata {
    if case let .paymentFailed(paymentMethodType, paymentId, _, _, _) = error,
      let paymentMethod = paymentMethodType {
      return .payment(
        PaymentEvent(
          paymentMethod: paymentMethod,
          paymentId: paymentId
        ))
    }
    return .general()
  }
}
