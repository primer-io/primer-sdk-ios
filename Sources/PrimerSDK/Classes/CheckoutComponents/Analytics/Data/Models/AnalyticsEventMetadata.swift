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
public enum AnalyticsEventMetadata {
  case general(GeneralEvent = GeneralEvent())
  case payment(PaymentEvent)
  case threeDS(ThreeDSEvent)
  case redirect(RedirectEvent)
}

// MARK: - Event Types

/// Metadata for general analytics events (checkout flow, SDK lifecycle)
public struct GeneralEvent {
  public let locale: String

  public init(locale: String = Self.formattedCurrentLocale) {
    self.locale = locale
  }

  /// Get a properly formatted locale string (e.g., "en-US") without modifiers
  /// Public so it can be used in default parameter values
  public static var formattedCurrentLocale: String {
    let locale = Locale.current
    if let languageCode = locale.languageCode {
      if let regionCode = locale.regionCode {
        return "\(languageCode)-\(regionCode)"
      } else {
        return languageCode
      }
    }
    return "en-US"  // Fallback
  }
}

/// Metadata for payment-related analytics events
public struct PaymentEvent {
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
public struct ThreeDSEvent {
  public let locale: String
  public let paymentMethod: String
  public let provider: String
  public let response: String

  public init(
    locale: String = GeneralEvent.formattedCurrentLocale,
    paymentMethod: String,
    provider: String,
    response: String
  ) {
    self.locale = locale
    self.paymentMethod = paymentMethod
    self.provider = provider
    self.response = response
  }
}

/// Metadata for third-party redirect events
public struct RedirectEvent {
  public let locale: String
  public let destinationUrl: String

  public init(
    locale: String = GeneralEvent.formattedCurrentLocale,
    destinationUrl: String
  ) {
    self.locale = locale
    self.destinationUrl = destinationUrl
  }
}

// MARK: - Convenience Accessors

extension AnalyticsEventMetadata {
  /// User locale in ISO format (e.g., "en-GB")
  var locale: String {
    switch self {
    case let .general(event): return event.locale
    case let .payment(event): return event.locale
    case let .threeDS(event): return event.locale
    case let .redirect(event): return event.locale
    }
  }

  /// Selected payment method (e.g., "PAYMENT_CARD", "APPLE_PAY")
  var paymentMethod: String? {
    switch self {
    case let .payment(event): return event.paymentMethod
    case let .threeDS(event): return event.paymentMethod
    default: return nil
    }
  }

  /// Identifier from payments API (e.g., "pay_01HZXGT7N5V1ASDFG987654321")
  var paymentId: String? {
    switch self {
    case let .payment(event): return event.paymentId
    default: return nil
    }
  }

  /// 3DS provider name (e.g., "Netcetera")
  var threedsProvider: String? {
    switch self {
    case let .threeDS(event): return event.provider
    default: return nil
    }
  }

  /// ECI value or 3DS response data (e.g., "05")
  var threedsResponse: String? {
    switch self {
    case let .threeDS(event): return event.response
    default: return nil
    }
  }

  /// Third-party redirection target URL
  var redirectDestinationUrl: String? {
    switch self {
    case let .redirect(event): return event.destinationUrl
    default: return nil
    }
  }
}
