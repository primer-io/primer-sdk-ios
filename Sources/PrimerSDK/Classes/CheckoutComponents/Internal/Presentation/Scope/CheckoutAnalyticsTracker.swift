//
//  CheckoutAnalyticsTracker.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerFoundation
@_spi(PrimerInternal) import PrimerCore

/// Turns checkout state changes into the terminal and lifecycle events.
@available(iOS 15.0, *)
@MainActor
final class CheckoutAnalyticsTracker: LogReporter {

  private let analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?

  init(analyticsInteractor: CheckoutComponentsAnalyticsInteractorProtocol?) {
    self.analyticsInteractor = analyticsInteractor
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
      await analyticsInteractor?.trackFlowExited()

    default:
      break
    }
  }

  /// One Datadog log per payment attempt, in the Web SDK's shape so one dashboard query serves both.
  func logPaymentSucceeded() {
    logger.info(
      message: Constants.successMessage,
      event: Constants.successEvent,
      userInfo: [Constants.checkoutOutcomeKey: Constants.checkoutComplete]
    )
  }

  func logPaymentFailed(_ error: PrimerError, checkoutData: PrimerCheckoutData?) {
    logger.warn(
      message: Constants.failureMessage,
      event: error.errorId,
      userInfo: Self.failureLogFields(error, checkoutData: checkoutData)
    )
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
    await analyticsInteractor?.trackFlowExited()
  }

  static func failureLogFields(_ error: PrimerError, checkoutData: PrimerCheckoutData?) -> [String: Any] {
    var fields: [String: Any] = [
      "error_code": error.datadogErrorCode,
      "error_origin": error.analyticsOrigin.rawValue,
      "error_message": error.localizedDescription,
      "diagnostics_id": error.diagnosticsId
    ]
    // Web sends the outcome only once a payment exists, so failures before one stay out of the success rate.
    if checkoutData?.payment?.id != nil {
      fields[Constants.checkoutOutcomeKey] = Constants.checkoutFailure
    }
    return fields
  }

  private static func paymentContext(of error: PrimerError) -> (paymentMethod: String?, paymentId: String?) {
    guard case let .paymentFailed(paymentMethodType, paymentId, _, _, _) = error else { return (nil, nil) }
    // The shared vault flow says UNKNOWN when its token has no type, so the attempt's method is used instead.
    return (paymentMethodType == "UNKNOWN" ? nil : paymentMethodType, paymentId)
  }
}

@available(iOS 15.0, *)
private extension CheckoutAnalyticsTracker {
  enum Constants {
    static let successMessage = "Payment complete"
    static let failureMessage = "Payment failed"
    static let successEvent = "payment-complete"
    static let checkoutOutcomeKey = "checkout_outcome"
    static let checkoutComplete = "CHECKOUT_COMPLETE"
    static let checkoutFailure = "CHECKOUT_FAILURE"
  }
}

extension PrimerError {
  /// The Web SDK's code where one exists, otherwise the error id in the same case.
  var datadogErrorCode: String {
    switch self {
    case .paymentFailed: "PAYMENT_FAILED"
    case .cancelled: "PAYMENT_CANCELLED"
    case .merchantError: "PAYMENT_CREATION_ABORTED"
    case .failedToResumePayment: "RESUME_FAILED"
    case .invalidClientToken: "INVALID_CLIENT_TOKEN"
    case .unknown: "UNEXPECTED"
    default: errorId.replacingOccurrences(of: "-", with: "_").uppercased()
    }
  }
}
