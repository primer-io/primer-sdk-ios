//
//  AnalyticsPayloadBuilder.swift
//
//  Copyright © 2025 Primer API Ltd. All rights reserved. 
//  Licensed under the MIT License. See LICENSE file in the project root for full license information.

import Foundation
import UIKit

/// Responsible for constructing analytics payloads from event data and session configuration.
/// Handles payload assembly, device info integration, and SDK type detection.
struct AnalyticsPayloadBuilder {

    // MARK: - Public Methods

    /// Construct a complete analytics payload
    /// - Parameters:
    ///   - eventType: The type of event being tracked
    ///   - metadata: Optional event-specific metadata
    ///   - config: Session configuration containing IDs and environment
    ///   - timestamp: Optional UNIX timestamp override. If nil, uses current time. Used for buffered events to preserve original event time.
    /// - Returns: A complete analytics payload ready for transmission
    func buildPayload(
        eventType: AnalyticsEventType,
        metadata: AnalyticsEventMetadata?,
        config: AnalyticsSessionConfig,
        timestamp: Int? = nil
    ) -> AnalyticsPayload {
        let eventId = String.uuid
        let eventTimestamp = timestamp ?? Int(Date().timeIntervalSince1970)
        let sdkType = detectSDKType()

        // Always include userAgent (system info)
        let userAgent = UIDevice.userAgent

        // Only include optional fields if metadata is provided
        // This ensures SDK lifecycle events (metadata=nil) don't include these fields
        // which matches backend validation requirements
        let userLocale: String? = metadata != nil ? (metadata!.locale) : nil
        let device: String? = metadata != nil ? UIDevice.model.rawValue : nil
        let deviceType: String? = metadata != nil ? UIDevice.deviceType : nil

        return AnalyticsPayload(
            id: eventId,
            timestamp: eventTimestamp,
            sdkType: sdkType,
            eventName: eventType.rawValue,
            checkoutSessionId: config.checkoutSessionId,
            clientSessionId: config.clientSessionId,
            primerAccountId: config.primerAccountId,
            sdkVersion: config.sdkVersion,
            userAgent: userAgent,
            eventType: nil,
            userLocale: userLocale,
            paymentMethod: metadata?.paymentMethod,
            paymentId: metadata?.paymentId,
            redirectDestinationUrl: metadata?.redirectDestinationUrl,
            threedsProvider: metadata?.threedsProvider,
            threedsResponse: metadata?.threedsResponse,
            browser: nil,
            device: device,
            deviceType: deviceType
        )
    }

    // MARK: - Private Helpers

    /// Detect SDK type based on React Native bridge availability
    private func detectSDKType() -> String {
        return NSClassFromString("RCTBridge") != nil ? "RN_IOS" : "IOS_NATIVE"
    }
}
