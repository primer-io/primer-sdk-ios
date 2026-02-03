//
//  AnalyticsPayload.swift
//
//  Copyright © 2026 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation

/// Internal payload model matching the analytics API JSON schema.
/// Codable automatically omits nil optional values during JSON encoding.
struct AnalyticsPayload: Codable {
  // MARK: - Required Fields

  /// Unique event ID (UUID v4)
  let id: String

  /// UNIX / Epoch timestamp as integer
  let timestamp: Int

  /// Which SDK initiated the event ("IOS_NATIVE" or "RN_IOS")
  let sdkType: String

  /// The name of the event (SCREAMING_SNAKE_CASE format)
  let eventName: String

  /// Session ID generated when checkout begins
  let checkoutSessionId: String

  /// Client session identifier (from JWT)
  let clientSessionId: String

  /// Primer identifier for the merchant
  let primerAccountId: String

  /// Current SDK version in semver format (e.g., "2.46.7")
  let sdkVersion: String

  /// Web-style user agent string (iOS version + device model)
  let userAgent: String

  // MARK: - Optional Fields

  /// Logical grouping / future taxonomy category
  let eventType: String?

  /// Locale of the device in ISO format (e.g., "en-GB")
  let userLocale: String?

  /// Selected payment method
  let paymentMethod: String?

  /// Identifier from payments API
  let paymentId: String?

  /// Third-party redirection target
  let redirectDestinationUrl: String?

  /// 3DS provider name
  let threedsProvider: String?

  /// ECI or response data
  let threedsResponse: String?

  /// Browser name inferred from UA
  let browser: String?

  /// Human-readable device name
  let device: String?

  /// Device category
  let deviceType: String?
}
