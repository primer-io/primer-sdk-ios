//
//  AnalyticsFunnelState.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Values fixed by the checkout event contract.
enum AnalyticsContract {
  /// Bump when an event's trigger or population changes.
  static let version = 2

  enum UnselectReason: String {
    case shopperCancel = "shopper_cancel"
    case merchantAbort = "merchant_abort"
  }

  enum FailureOutcome: String {
    case failed
    case unknown
  }

  enum ErrorOrigin: String {
    case payment
    case primer
    case integration
  }
}

/// Applies the contract's per-session rules before an event is sent: attempt boundaries, one outcome per
/// attempt, and deduplication. One instance lives for one checkout session.
struct AnalyticsFunnelState {

  /// Context stamped on the event.
  struct Envelope: Equatable {
    let attemptId: String?
    let paymentMethod: String?
    let paymentId: String?
    let lastStep: String?
    /// Only on the attempt's SUCCESS or FAILURE.
    var threeDSOutcome: ThreeDSOutcome?
  }

  /// How the attempt's 3DS authentication ended, frictionless included.
  struct ThreeDSOutcome: Equatable, Sendable {
    let authenticationOutcome: String
    let skippedReasonCode: String?
  }

  struct Output {
    let eventType: AnalyticsEventType
    let metadata: AnalyticsEventMetadata?
    let envelope: Envelope
  }

  private let makeAttemptId: @Sendable () -> String
  private var attemptId: String?
  private var paymentMethod: String?
  private var paymentId: String?
  private var isAttemptOpen = false
  private var hasSubmittedInAttempt = false
  private var threeDSOutcome: ThreeDSOutcome?
  private var lastOutcome: AnalyticsEventType?
  private(set) var selectedMethods: Set<String>
  private var hasStartedFlow = false
  private var hasSucceeded = false
  private var hasExited = false
  private var lastStep: String?

  /// - Parameter selectedMethods: the methods this client session already selected before a remount.
  init(
    makeAttemptId: @escaping @Sendable () -> String = { UUID().uuidString },
    selectedMethods: Set<String> = []
  ) {
    self.makeAttemptId = makeAttemptId
    self.selectedMethods = selectedMethods
  }

  /// The events to send for one tracked event, in order. Empty when the contract drops it.
  mutating func process(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) -> [Output] {
    let method = metadata?.paymentMethod
    var outputs: [Output] = []

    switch eventType {
    case .checkoutFlowStarted:
      guard !hasStartedFlow else { return [] }
      hasStartedFlow = true

    case .paymentMethodSelection:
      let selection = select(method)
      outputs = selection.implied
      guard selection.isFirst else { return outputs }

    case .paymentReattempted:
      return reattempt(method)

    case .paymentSuccess, .paymentFailure, .paymentMethodUnselected:
      guard closeAttempt(with: eventType, method: method) else { return [] }

    case .paymentFlowExited:
      return exit(metadata)

    case .paymentDetailsEntered, .paymentSubmitted, .paymentProcessingStarted, .paymentRedirectToThirdParty,
         .paymentReturnedFromThirdParty, .paymentThreeds, .redirectReturnUrlNotConfigured:
      guard let implied = openAttemptIfNeeded(for: eventType, method: method) else { return [] }
      outputs = implied

    default:
      break
    }

    if let id = metadata?.paymentId { paymentId = id }
    outputs.append(emit(eventType, metadata: metadata))
    return outputs
  }

  /// Lives until the next attempt starts, so a late result never reaches another attempt.
  mutating func recordThreeDSOutcome(_ outcome: ThreeDSOutcome) {
    threeDSOutcome = outcome
  }

  // MARK: - Private

  /// The events a selection implies, and whether the selection itself is sent.
  private mutating func select(_ method: String?) -> (implied: [Output], isFirst: Bool) {
    guard let method else { return ([], true) }
    var implied: [Output] = []
    if isAttemptOpen, let current = paymentMethod, current != method {
      isAttemptOpen = false
      lastOutcome = .paymentMethodUnselected
      implied.append(emit(.paymentMethodUnselected, metadata: unselected(current)))
    }
    if !isAttemptOpen { implied += beginAttempt(method) }
    return (implied, selectedMethods.insert(method).inserted)
  }

  /// Empty when the retried attempt already started, or when no failure came before it.
  private mutating func reattempt(_ method: String?) -> [Output] {
    isAttemptOpen ? [] : beginAttempt(method)
  }

  /// Nil drops the event: DETAILS_ENTERED after this attempt's SUBMITTED is late.
  private mutating func openAttemptIfNeeded(for eventType: AnalyticsEventType, method: String?) -> [Output]? {
    let implied = isAttemptOpen ? [] : beginAttempt(method ?? paymentMethod)
    if eventType == .paymentDetailsEntered, hasSubmittedInAttempt { return nil }
    if eventType == .paymentSubmitted { hasSubmittedInAttempt = true }
    return implied
  }

  /// False when the outcome must be dropped.
  private mutating func closeAttempt(with outcome: AnalyticsEventType, method: String?) -> Bool {
    if outcome == .paymentMethodUnselected {
      // A late signal about a method the shopper already left.
      guard isAttemptOpen, method == nil || method == paymentMethod else { return false }
    } else {
      // An attempt that already has an outcome, such as a merchant abort reported as UNSELECTED.
      if attemptId != nil, !isAttemptOpen { return false }
      if attemptId == nil {
        // No attempt and no method: the checkout failed to load, which the contract does not count as a payment.
        guard method != nil else { return false }
        startAttempt(method)
      }
      hasSucceeded = hasSucceeded || outcome == .paymentSuccess
    }
    isAttemptOpen = false
    lastOutcome = outcome
    return true
  }

  private mutating func exit(_ metadata: AnalyticsEventMetadata?) -> [Output] {
    guard !hasExited, !hasSucceeded else { return [] }
    hasExited = true
    return [Output(eventType: .paymentFlowExited, metadata: metadata, envelope: envelope(lastStep: lastStep))]
  }

  /// A new attempt right after a failure is a reattempt.
  private mutating func beginAttempt(_ method: String?) -> [Output] {
    let previous = paymentMethod
    let followsFailure = lastOutcome == .paymentFailure
    startAttempt(method)
    guard followsFailure else { return [] }
    lastOutcome = nil
    return [emit(.paymentReattempted, metadata: reattempted(previous: previous))]
  }

  private mutating func startAttempt(_ method: String?) {
    attemptId = makeAttemptId()
    paymentMethod = method ?? paymentMethod
    paymentId = nil
    isAttemptOpen = true
    hasSubmittedInAttempt = false
    threeDSOutcome = nil
  }

  private mutating func emit(_ eventType: AnalyticsEventType, metadata: AnalyticsEventMetadata?) -> Output {
    lastStep = eventType.rawValue
    var stamped = envelope(lastStep: nil)
    if eventType == .paymentSuccess || eventType == .paymentFailure { stamped.threeDSOutcome = threeDSOutcome }
    return Output(eventType: eventType, metadata: metadata, envelope: stamped)
  }

  private func envelope(lastStep: String?) -> Envelope {
    Envelope(attemptId: attemptId, paymentMethod: paymentMethod, paymentId: paymentId, lastStep: lastStep)
  }

  private func unselected(_ method: String) -> AnalyticsEventMetadata {
    .payment(PaymentEvent(paymentMethod: method, reason: AnalyticsContract.UnselectReason.shopperCancel.rawValue))
  }

  private func reattempted(previous: String?) -> AnalyticsEventMetadata {
    guard let paymentMethod else { return .general() }
    return .payment(PaymentEvent(paymentMethod: paymentMethod, previousPaymentMethod: previous))
  }
}
