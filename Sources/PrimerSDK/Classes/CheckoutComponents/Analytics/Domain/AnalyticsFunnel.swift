//
//  AnalyticsFunnel.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
@_spi(PrimerInternal) import PrimerFoundation

/// The one place that defines each checkout event's payload. Call sites use these, never `trackEvent` directly.
extension CheckoutComponentsAnalyticsInteractorProtocol {

  func trackSDKInitStart() async {
    await trackEvent(.sdkInitStart, metadata: nil)
  }

  func trackSDKInitEnd() async {
    await trackEvent(.sdkInitEnd, metadata: nil)
  }

  func trackCheckoutFlowStarted(availablePaymentMethods: [String]) async {
    await trackEvent(.checkoutFlowStarted, metadata: .general(GeneralEvent(availablePaymentMethods: availablePaymentMethods)))
  }

  /// The shopper entered a method. Starts an attempt even when the event itself is deduplicated.
  func trackMethodSelected(_ paymentMethod: String) async {
    await trackEvent(.paymentMethodSelection, metadata: .payment(PaymentEvent(paymentMethod: paymentMethod)))
  }

  /// `paymentMethod` nil means the method of the open attempt.
  func trackMethodUnselected(_ paymentMethod: String?, reason: AnalyticsContract.UnselectReason) async {
    await trackEvent(
      .paymentMethodUnselected,
      metadata: .payment(PaymentEvent(paymentMethod: paymentMethod ?? "", reason: reason.rawValue))
    )
  }

  func trackDetailsEntered(_ paymentMethod: String) async {
    await trackEvent(.paymentDetailsEntered, metadata: .payment(PaymentEvent(paymentMethod: paymentMethod)))
  }

  func trackSubmitted(_ paymentMethod: String) async {
    await trackEvent(.paymentSubmitted, metadata: .payment(PaymentEvent(paymentMethod: paymentMethod)))
  }

  func trackProcessingStarted(_ paymentMethod: String) async {
    await trackEvent(.paymentProcessingStarted, metadata: .payment(PaymentEvent(paymentMethod: paymentMethod)))
  }

  func trackRedirectToThirdParty(_ paymentMethod: String, destination: URL, paymentId: String?) async {
    // Origin only, the path and query can carry tokens.
    let origin = destination.host.map { "\(destination.scheme ?? "https")://\($0)" } ?? ""
    await trackEvent(
      .paymentRedirectToThirdParty,
      metadata: .redirect(RedirectEvent(paymentMethod: paymentMethod, destinationUrl: origin, paymentId: paymentId))
    )
  }

  func trackReturnedFromThirdParty(_ paymentMethod: String, paymentId: String?) async {
    await trackEvent(
      .paymentReturnedFromThirdParty,
      metadata: .payment(PaymentEvent(paymentMethod: paymentMethod, paymentId: paymentId))
    )
  }

  func trackRedirectReturnUrlNotConfigured(_ paymentMethod: String) async {
    await trackEvent(.redirectReturnUrlNotConfigured, metadata: .payment(PaymentEvent(paymentMethod: paymentMethod)))
  }

  /// The payment method comes from the attempt when the caller does not know it.
  func trackThreeDSChallengeShown(provider: String, protocolVersion: String?) async {
    await trackEvent(
      .paymentThreeds,
      metadata: .threeDS(ThreeDSEvent(paymentMethod: "", provider: provider, protocolVersion: protocolVersion))
    )
  }

  func trackSuccess(_ paymentMethod: String?, paymentId: String?) async {
    let metadata: AnalyticsEventMetadata = paymentMethod.map {
      .payment(PaymentEvent(paymentMethod: $0, paymentId: paymentId))
    } ?? .general()
    await trackEvent(.paymentSuccess, metadata: metadata)
  }

  func trackFailure(_ error: PrimerError, paymentMethod: String?, paymentId: String?) async {
    let event = PaymentEvent(
      paymentMethod: paymentMethod ?? "",
      paymentId: paymentId,
      errorCode: error.errorId,
      errorOrigin: error.analyticsOrigin.rawValue,
      outcome: AnalyticsContract.FailureOutcome.failed.rawValue
    )
    await trackEvent(.paymentFailure, metadata: .payment(event))
  }

  /// A new attempt at the same method. The previous method is added by the funnel.
  func trackReattempted() async {
    await trackEvent(.paymentReattempted, metadata: nil)
  }

  func trackFlowExited() async {
    await trackEvent(.paymentFlowExited, metadata: nil)
  }
}

extension PrimerError {
  var analyticsOrigin: AnalyticsContract.ErrorOrigin {
    switch self {
    case .paymentFailed, .failedToCreatePayment, .failedToResumePayment, .klarnaUserNotApproved, .applePayTimedOut:
      .payment
    case .uninitializedSDKSession, .invalidClientToken, .missingPrimerConfiguration, .misconfiguredPaymentMethods,
         .missingPrimerInputElement, .invalidUrl, .invalidArchitecture, .invalidClientSessionValue,
         .invalidMerchantIdentifier, .invalidValue, .unableToMakePaymentsOnProvidedNetworks, .unsupportedIntent,
         .unsupportedPaymentMethod, .unsupportedPaymentMethodForManager, .missingSDK, .merchantError,
         .invalidVaultedPaymentMethodId, .applePayConfigurationError:
      .integration
    default:
      .primer
    }
  }
}
