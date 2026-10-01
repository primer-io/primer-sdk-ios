//
//  CheckoutAnalyticsTracker.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Turns checkout state changes into the terminal and lifecycle events.
@available(iOS 15.0, *)
@MainActor
final class CheckoutAnalyticsTracker: LogReporter {

  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?
  private let threeDSObservations: [Task<Void, Never>]

  init(analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?) {
    self.analyticsInteractor = analyticsInteractor
    // The 3DS service lives in the shared core, so it announces the challenge and the result instead of calling CC analytics.
    threeDSObservations = [
      Task {
        for await notification in NotificationCenter.default.notifications(named: .primer3DSChallengePresented) {
          let info = notification.userInfo
          await analyticsInteractor?.trackThreeDSChallengeShown(
            provider: info?[Notification.Name.primer3DSProviderKey] as? String ?? "Unknown",
            protocolVersion: info?[Notification.Name.primer3DSProtocolVersionKey] as? String
          )
        }
      },
      Task {
        for await notification in NotificationCenter.default.notifications(named: .primer3DSAuthenticationCompleted) {
          let info = notification.userInfo
          guard let outcome = info?[Notification.Name.primer3DSOutcomeKey] as? String else { continue }
          await analyticsInteractor?.recordThreeDSOutcome(AnalyticsFunnelState.ThreeDSOutcome(
            authenticationOutcome: outcome,
            skippedReasonCode: info?[Notification.Name.primer3DSSkippedReasonKey] as? String
          ))
        }
      }
    ]
  }

  deinit {
    stopObservingThreeDS()
  }

  func trackStateChange(_ state: PrimerCheckoutState, availablePaymentMethods: [String] = []) async {
    switch state {
    case .ready:
      await analyticsInteractor?.trackCheckoutFlowStarted(availablePaymentMethods: availablePaymentMethods)
      let initDuration = await LoggingSessionContext.shared.calculateInitDuration()
      let message = initDuration.map { "Checkout initialized (\($0)ms)" } ?? "Checkout initialized"
      logger.info(
        message: message,
        event: "checkout-initialized",
        userInfo: initDuration.map { ["init_duration_ms": $0] }
      )

    case let .success(result):
      await analyticsInteractor?.trackSuccess(result.paymentMethodType, paymentId: result.paymentId)

    case let .failure(error, checkoutData):
      let context = Self.paymentContext(of: error)
      await analyticsInteractor?.trackFailure(
        error,
        paymentMethod: context.paymentMethod,
        paymentId: checkoutData?.payment?.id ?? context.paymentId
      )

    case .dismissed:
      stopObservingThreeDS()
      await analyticsInteractor?.trackFlowExited()

    default:
      break
    }
  }

  func trackRetry() async {
    await analyticsInteractor?.trackReattempted()
  }

  /// Leaving a method's screen for the list abandons that method.
  func trackNavigation(from previous: CheckoutNavigationState, to state: CheckoutNavigationState) async {
    guard case .paymentMethodSelection = state, case let .paymentMethod(type) = previous else { return }
    await trackMethodLeft(type, reason: .shopperCancel)
  }

  /// `paymentMethod` nil means the method of the open attempt.
  func trackMethodLeft(_ paymentMethod: String?, reason: AnalyticsContract.UnselectReason) async {
    await analyticsInteractor?.trackMethodUnselected(paymentMethod, reason: reason)
  }

  /// For surfaces that close without passing through `.dismissed`.
  func trackFlowExited() async {
    stopObservingThreeDS()
    await analyticsInteractor?.trackFlowExited()
  }

  /// A closed checkout can outlive its screen, and must not send another session's 3DS.
  private nonisolated func stopObservingThreeDS() {
    threeDSObservations.forEach { $0.cancel() }
  }

  private static func paymentContext(of error: PrimerError) -> (paymentMethod: String?, paymentId: String?) {
    guard case let .paymentFailed(paymentMethodType, paymentId, _, _, _) = error else { return (nil, nil) }
    return (paymentMethodType, paymentId)
  }
}
