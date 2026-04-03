//
//  AnalyticsEventMetadata.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Optional metadata that can be attached to analytics events.
/// Not all events require all metadata fields - include only relevant fields per event type.
/// Analytics event metadata using discriminated unions for type safety.
/// Each event type carries only its relevant metadata - no optional pollution.
public enum AnalyticsEventMetadata: Sendable {
  case general(GeneralEvent = GeneralEvent())
  case payment(PaymentEvent)
  case threeDS(ThreeDSEvent)
  case redirect(RedirectEvent)
}

// MARK: - Event Types

/// Metadata for general analytics events (checkout flow, SDK lifecycle)
public struct GeneralEvent: Sendable {
  public let locale: String

  public init(locale: String = Self.formattedCurrentLocale) {
    self.locale = locale
  }

  public static var formattedCurrentLocale: String {
    let locale = Locale.current
    guard let languageCode = locale.languageCode else { return "en-US" }
    return locale.regionCode.map { "\(languageCode)-\($0)" } ?? languageCode
  }
}

/// Metadata for payment-related analytics events
public struct PaymentEvent: Sendable {
  public let locale: String
  public let paymentMethod: String
  public let paymentId: String?

  public init(
    locale: String = GeneralEvent.formattedCurrentLocale,
    paymentMethod: String,
    paymentId: String? = nil
  ) {
    self.locale = locale
    self.paymentMethod = paymentMethod
    self.paymentId = paymentId
  }
}

/// Metadata for 3D Secure authentication events
public struct ThreeDSEvent: Sendable {
  public let locale: String
  public let paymentMethod: String
  public let provider: String
  public let response: String?

  public init(
    locale: String = GeneralEvent.formattedCurrentLocale,
    paymentMethod: String,
    provider: String,
    response: String? = nil
  ) {
    self.locale = locale
    self.paymentMethod = paymentMethod
    self.provider = provider
    self.response = response
  }
}

/// Metadata for third-party redirect events
public struct RedirectEvent: Sendable {
  public let locale: String
  public let paymentMethod: String
  public let destinationUrl: String

  public init(
    locale: String = GeneralEvent.formattedCurrentLocale,
    paymentMethod: String,
    destinationUrl: String
  ) {
    self.locale = locale
    self.paymentMethod = paymentMethod
    self.destinationUrl = destinationUrl
  }
}

// MARK: - Convenience Accessors

extension AnalyticsEventMetadata {
  /// User locale in ISO format (e.g., "en-GB")
  var locale: String {
    switch self {
    case let .general(event): event.locale
    case let .payment(event): event.locale
    case let .threeDS(event): event.locale
    case let .redirect(event): event.locale
    }
  }

  var paymentMethod: String? {
    switch self {
    case let .payment(event): event.paymentMethod
    case let .threeDS(event): event.paymentMethod
    case let .redirect(event): event.paymentMethod
    default: nil
    }
  }

  var paymentId: String? {
    switch self {
    case let .payment(event): event.paymentId
    default: nil
    }
  }

  var threedsProvider: String? {
    switch self {
    case let .threeDS(event): event.provider
    default: nil
    }
  }

  var threedsResponse: String? {
    switch self {
    case let .threeDS(event): event.response
    default: nil
    }
  }

  var redirectDestinationUrl: String? {
    switch self {
    case let .redirect(event): event.destinationUrl
    default: nil
    }
  }
}
