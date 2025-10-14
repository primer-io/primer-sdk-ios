//
//  AnalyticsEventMetadata.swift
//  PrimerSDK
//
//  Created by CheckoutComponents Analytics
//

import Foundation

/// Optional metadata that can be attached to analytics events.
/// Not all events require all metadata fields - include only relevant fields per event type.
public struct AnalyticsEventMetadata {
    /// Logical grouping / future taxonomy category
    public let eventType: String?

    /// Locale of the device in ISO format (e.g., "en-GB")
    public let userLocale: String?

    /// Selected payment method (e.g., "PAYMENT_CARD", "APPLE_PAY")
    public let paymentMethod: String?

    /// Identifier from payments API (e.g., "pay_01HZXGT7N5V1ASDFG987654321")
    public let paymentId: String?

    /// Third-party redirection target URL
    public let redirectDestinationUrl: String?

    /// 3DS provider name (e.g., "Netcetera")
    public let threedsProvider: String?

    /// ECI value or 3DS response data (e.g., "05")
    public let threedsResponse: String?

    /// Browser name inferred from user agent (usually nil for native; service auto-fills)
    public let browser: String?

    /// Human-readable device name (e.g., "iPhone 15 Pro"); service auto-fills when nil
    public let device: String?

    /// Device category ("phone", "tablet", "watch"); service auto-fills when nil
    public let deviceType: String?

    public init(
        eventType: String? = nil,
        userLocale: String? = nil,
        paymentMethod: String? = nil,
        paymentId: String? = nil,
        redirectDestinationUrl: String? = nil,
        threedsProvider: String? = nil,
        threedsResponse: String? = nil,
        browser: String? = nil,
        device: String? = nil,
        deviceType: String? = nil
    ) {
        self.eventType = eventType
        self.userLocale = userLocale
        self.paymentMethod = paymentMethod
        self.paymentId = paymentId
        self.redirectDestinationUrl = redirectDestinationUrl
        self.threedsProvider = threedsProvider
        self.threedsResponse = threedsResponse
        self.browser = browser
        self.device = device
        self.deviceType = deviceType
    }
}
