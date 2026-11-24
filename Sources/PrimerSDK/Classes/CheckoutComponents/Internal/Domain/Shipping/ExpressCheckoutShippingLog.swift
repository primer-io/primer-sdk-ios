//
//  ExpressCheckoutShippingLog.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

@_spi(PrimerInternal) import PrimerCore
@_spi(PrimerInternal) import PrimerFoundation

/// One Express Checkout shipping step, in the Web SDK's Datadog shape so one dashboard query serves both.
@available(iOS 15.0, *)
struct ExpressCheckoutShippingLog: Equatable {

  enum Event: String {
    case addressChange = "SHIPPING_ADDRESS_CHANGE"
    case optionChange = "SHIPPING_OPTION_CHANGE"
    case commit = "SHIPPING_COMMIT"
  }

  /// Web also has `authorize`, for a commit at Pay. iOS never commits there: an unverified commit blocks Pay.
  enum Trigger: String {
    case sheetOpen = "sheet_open"
    case addressEdit = "address_edit"
    case defaultOption = "default"
    case shopper
  }

  enum Outcome: String {
    case answered
    case timeout
    /// iOS only: the merchant's handler threw, which Web's callback API cannot do.
    case failed
    case noHandler = "no_handler"
    case committed
    case mismatch
    case refreshFailed = "refresh_failed"
  }

  static let contextKey = "express_checkout_shipping"

  let event: Event
  let trigger: Trigger
  let outcome: Outcome
  var durationMs: Int?
  var optionsCount: Int?
  var shippingMethodId: String?

  var message: String { "Express Checkout: \(event.rawValue)" }

  var datadogEvent: String { "EXPRESS_CHECKOUT_\(event.rawValue)" }

  var isWarning: Bool {
    switch outcome {
    case .timeout, .failed, .mismatch, .refreshFailed: true
    case .noHandler: event == .optionChange
    case .answered, .committed: false
    }
  }

  /// Only a step where merchant code ran flags the attempt's later logs.
  var ranMerchantCode: Bool { [.answered, .timeout, .failed].contains(outcome) }

  var fields: [String: Any] {
    var fields: [String: Any] = [
      "payment_method": PrimerPaymentMethodType.applePay.rawValue,
      "trigger": trigger.rawValue,
      "outcome": outcome.rawValue
    ]
    fields["duration_ms"] = durationMs
    fields["options_count"] = optionsCount
    fields["shipping_method_id"] = shippingMethodId
    return fields
  }

  static func send(_ log: Self) {
    if log.ranMerchantCode {
      RemoteLogContext.shared[contextKey] = true
    }
    let logger = PrimerLogging.shared.logger
    if log.isWarning {
      logger.warn(message: log.message, event: log.datadogEvent, userInfo: log.fields)
    } else {
      logger.info(message: log.message, event: log.datadogEvent, userInfo: log.fields)
    }
  }

  static func clearContext() {
    RemoteLogContext.shared[contextKey] = nil
  }
}
